package main

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/api"
	apiserver "github.com/openebs/openebs/api/server"
	"github.com/openebs/openebs/api/server/middleware"
	"github.com/openebs/openebs/api/server/router"
	systemrouter "github.com/openebs/openebs/api/server/router/system"
	vsmrouter "github.com/openebs/openebs/api/server/router/vsm"
	cliflags "github.com/openebs/openebs/cli/flags"
	"github.com/openebs/openebs/daemon"
	"github.com/openebs/openebs/opts"
	"github.com/openebs/openebs/pkg/jsonlog"
	"github.com/openebs/openebs/pkg/listeners"
	flag "github.com/openebs/openebs/pkg/mflag"
	"github.com/openebs/openebs/pkg/pidfile"
	"github.com/openebs/openebs/pkg/signal"
	"github.com/openebs/openebs/utils"
	"github.com/openebs/openebs/version"
)

const (
	daemonConfigFileFlag = "-config-file"
)

// DaemonCli represents the daemon CLI.
type DaemonCli struct {
	*daemon.Config
	commonFlags *cliflags.CommonFlags
	configFile  *string

	api *apiserver.Server
	d   *daemon.Daemon
}

func presentInHelp(usage string) string { return usage }
func absentFromHelp(string) string      { return "" }

// NewDaemonCli returns a pre-configured daemon CLI
func NewDaemonCli() *DaemonCli {
	// TODO(tiborvass): remove InstallFlags?
	daemonConfig := new(daemon.Config)

	daemonConfig.LogConfig.Config = make(map[string]string)

	daemonConfig.InstallFlags(flag.CommandLine, presentInHelp)
	configFile := flag.CommandLine.String([]string{daemonConfigFileFlag}, defaultDaemonConfigFile, "Daemon configuration file")
	flag.CommandLine.Require(flag.Exact, 0)

	return &DaemonCli{
		Config:      daemonConfig,
		commonFlags: cliflags.InitCommonFlags(),
		configFile:  configFile,
	}
}

func (cli *DaemonCli) start() (err error) {
	stopc := make(chan bool)
	defer close(stopc)

	flags := flag.CommandLine
	cli.commonFlags.PostParse()

	cliConfig, err := loadDaemonCliConfig(cli.Config, flags, cli.commonFlags, *cli.configFile)
	if err != nil {
		return err
	}
	cli.Config = cliConfig

	if cli.Config.Debug {
		utils.EnableDebug()
	}

	logrus.SetFormatter(&logrus.TextFormatter{
		TimestampFormat: jsonlog.RFC3339NanoFixed,
		DisableColors:   cli.Config.RawLogs,
	})

	if err := setDefaultUmask(); err != nil {
		return fmt.Errorf("Failed to set umask: %v", err)
	}

	//TODO : Kiran
	//if len(cli.LogConfig.Config) > 0 {
	//	if err := logger.ValidateLogOpts(cli.LogConfig.Type, cli.LogConfig.Config); err != nil {
	//		return fmt.Errorf("Failed to set log opts: %v", err)
	//	}
	//}

	if cli.Pidfile != "" {
		pf, err := pidfile.New(cli.Pidfile)
		if err != nil {
			return fmt.Errorf("Error starting daemon: %v", err)
		}
		defer func() {
			if err := pf.Remove(); err != nil {
				logrus.Error(err)
			}
		}()
	}

	serverConfig := &apiserver.Config{
		Logging:     true,
		SocketGroup: cli.Config.SocketGroup,
		Version:     version.Version,
	}

	if len(cli.Config.Hosts) == 0 {
		cli.Config.Hosts = make([]string, 1)
	}

	api := apiserver.New(serverConfig)
	cli.api = api

	for i := 0; i < len(cli.Config.Hosts); i++ {
		var err error
		if cli.Config.Hosts[i], err = opts.ParseHost(cli.Config.TLS, cli.Config.Hosts[i]); err != nil {
			return fmt.Errorf("error parsing -H %s : %v", cli.Config.Hosts[i], err)
		}

		protoAddr := cli.Config.Hosts[i]
		protoAddrParts := strings.SplitN(protoAddr, "://", 2)
		if len(protoAddrParts) != 2 {
			return fmt.Errorf("bad format %s, expected PROTO://ADDR", protoAddr)
		}

		proto := protoAddrParts[0]
		addr := protoAddrParts[1]

		// It's a bad idea to bind to TCP without tlsverify.
		if proto == "tcp" {
			logrus.Warn("[!] DON'T BIND ON ANY IP ADDRESS WITHOUT setting -tlsverify IF YOU DON'T KNOW WHAT YOU'RE DOING [!]")
		}
		ls, err := listeners.Init(proto, addr, serverConfig.SocketGroup, serverConfig.TLSConfig)
		if err != nil {
			return err
		}
		ls = wrapListeners(proto, ls)
		// If we're binding to a TCP port, make sure that a container doesn't try to use it.
		if proto == "tcp" {
			if err := allocateDaemonPort(addr); err != nil {
				return err
			}
		}
		logrus.Debugf("Listener created for HTTP on %s (%s)", protoAddrParts[0], protoAddrParts[1])
		api.Accept(protoAddrParts[1], ls...)
	}

	signal.Trap(func() {
		cli.stop()
		<-stopc // wait for daemonCli.start() to return
	})

	d, err := daemon.NewDaemon(cli.Config)
	if err != nil {
		return fmt.Errorf("Error starting daemon: %v", err)
	}

	//name, _ := os.Hostname()

	logrus.Info("Daemon has completed initialization")

	logrus.WithFields(logrus.Fields{
		"version": version.Version,
		"commit":  version.GitCommit,
	}).Info("OpenEBS daemon")

	cli.initMiddlewares(api, serverConfig)
	initRouter(api, d)

	cli.d = d
	cli.setupConfigReloadTrap()

	// The serve API routine never exits unless an error occurs
	// We need to start it as a goroutine and wait on it so
	// daemon doesn't exit
	serveAPIWait := make(chan error)
	go api.Wait(serveAPIWait)

	// after the daemon is done setting up we can notify systemd api
	notifySystem()

	// Daemon is fully initialized and handling API traffic
	// Wait for serve API to complete
	errAPI := <-serveAPIWait
	shutdownDaemon(d, 15)
	if errAPI != nil {
		return fmt.Errorf("Shutting down due to ServeAPI error: %v", errAPI)
	}

	return nil
}

func (cli *DaemonCli) reloadConfig() {
	reload := func(config *daemon.Config) {
		if err := cli.d.Reload(config); err != nil {
			logrus.Errorf("Error reconfiguring the daemon: %v", err)
			return
		}
		if config.IsValueSet("debug") {
			debugEnabled := utils.IsDebugEnabled()
			switch {
			case debugEnabled && !config.Debug: // disable debug
				utils.DisableDebug()
				cli.api.DisableProfiler()
			case config.Debug && !debugEnabled: // enable debug
				utils.EnableDebug()
				cli.api.EnableProfiler()
			}

		}
	}

	if err := daemon.ReloadConfiguration(*cli.configFile, flag.CommandLine, reload); err != nil {
		logrus.Error(err)
	}
}

func (cli *DaemonCli) stop() {
	cli.api.Close()
}

// shutdownDaemon just wraps daemon.Shutdown() to handle a timeout in case
// d.Shutdown() is waiting too long to kill container or worst it's
// blocked there
func shutdownDaemon(d *daemon.Daemon, timeout time.Duration) {
	ch := make(chan struct{})
	go func() {
		d.Shutdown()
		close(ch)
	}()
	select {
	case <-ch:
		logrus.Debug("Clean shutdown succeeded")
	case <-time.After(timeout * time.Second):
		logrus.Error("Force shutdown daemon")
	}
}

func loadDaemonCliConfig(config *daemon.Config, flags *flag.FlagSet, commonConfig *cliflags.CommonFlags, configFile string) (*daemon.Config, error) {
	config.Debug = commonConfig.Debug
	config.Hosts = commonConfig.Hosts
	config.LogLevel = commonConfig.LogLevel

	if configFile != "" {
		c, err := daemon.MergeDaemonConfigurations(config, flags, configFile)
		if err != nil {
			if flags.IsSet(daemonConfigFileFlag) || !os.IsNotExist(err) {
				return nil, fmt.Errorf("unable to configure the OpenEBS daemon with file %s: %v\n", configFile, err)
			}
		}
		// the merged configuration can be nil if the config file didn't exist.
		// leave the current configuration as it is if when that happens.
		if c != nil {
			config = c
		}
	}

	if err := daemon.ValidateConfiguration(config); err != nil {
		return nil, err
	}

	// ensure that the log level is the one set after merging configurations
	cliflags.SetDaemonLogLevel(config.LogLevel)

	return config, nil
}

func initRouter(s *apiserver.Server, d *daemon.Daemon) {

	routers := []router.Router{
		systemrouter.NewRouter(d),
		vsmrouter.NewRouter(d),
	}
	s.InitRouter(utils.IsDebugEnabled(), routers...)
}

func (cli *DaemonCli) initMiddlewares(s *apiserver.Server, cfg *apiserver.Config) {
	v := cfg.Version

	vm := middleware.NewVersionMiddleware(v, api.DefaultVersion, api.MinVersion)
	s.UseMiddleware(vm)

	u := middleware.NewUserAgentMiddleware(v)
	s.UseMiddleware(u)

}
