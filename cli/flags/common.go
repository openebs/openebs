package flags

import (
	"fmt"
	"os"

	"github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/opts"
	flag "github.com/openebs/openebs/pkg/mflag"
)


// CommonFlags are flags common to both the client and the daemon.
type CommonFlags struct {
	FlagSet   *flag.FlagSet
	PostParse func()

	Debug      bool
	Hosts      []string
	LogLevel   string
}

// InitCommonFlags initializes flags common to both client and daemon
func InitCommonFlags() *CommonFlags {
	var commonFlags = &CommonFlags{FlagSet: new(flag.FlagSet)}

	commonFlags.PostParse = func() { postParseCommon(commonFlags) }

	cmd := commonFlags.FlagSet

	cmd.BoolVar(&commonFlags.Debug, []string{"D", "-debug"}, false, "Enable debug mode")
	cmd.StringVar(&commonFlags.LogLevel, []string{"l", "-log-level"}, "info", "Set the logging level")

	cmd.Var(opts.NewNamedListOptsRef("hosts", &commonFlags.Hosts, opts.ValidateHost), []string{"H", "-host"}, "Daemon socket(s) to connect to")
	return commonFlags
}

func postParseCommon(commonFlags *CommonFlags) {

	SetDaemonLogLevel(commonFlags.LogLevel)

}

// SetDaemonLogLevel sets the logrus logging level
// TODO: this is a bad name, it applies to the client as well.
func SetDaemonLogLevel(logLevel string) {
	if logLevel != "" {
		lvl, err := logrus.ParseLevel(logLevel)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Unable to parse logging level: %s\n", logLevel)
			os.Exit(1)
		}
		logrus.SetLevel(lvl)
	} else {
		logrus.SetLevel(logrus.InfoLevel)
	}
}
