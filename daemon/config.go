package daemon

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"strings"
	"sync"

	"github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/opts"
	flag "github.com/openebs/openebs/pkg/mflag"
	"github.com/imdario/mergo"
)


// flatOptions contains configuration keys
// that MUST NOT be parsed as deep structures.
// Use this to differentiate these options
// with others like the ones in CommonTLSOptions.
var flatOptions = map[string]bool{
	"log-opts":           true,
}

// LogConfig represents the default log configuration.
// It includes json tags to deserialize configuration from a file
// using the same names that the flags in the command line use.
type LogConfig struct {
	Type   string            `json:"log-driver,omitempty"`
	Config map[string]string `json:"log-opts,omitempty"`
}


// CommonConfig defines the configuration of a OpenEBS daemon which is
// common across platforms.
// It includes json tags to deserialize configuration from a file
// using the same names that the flags in the command line use.
type CommonConfig struct {
	RawLogs		bool     `json:"raw-logs,omitempty"`
        SocketGroup	string              `json:"group,omitempty"`
	Debug		bool     `json:"debug,omitempty"`
	Hosts		[]string `json:"hosts,omitempty"`
	LogLevel	string   `json:"log-level,omitempty"`
	TLS		bool     `json:"tls,omitempty"`
	Pidfile		string   `json:"pidfile,omitempty"`
	LogConfig

	reloadLock	sync.Mutex
	valuesSet	map[string]interface{}
}

// InstallCommonFlags adds command-line options to the top-level flag parser for
// the current process.
// Subsequent calls to `flag.Parse` will populate config with values parsed
// from the command-line.
func (config *Config) InstallCommonFlags(cmd *flag.FlagSet, usageFn func(string) string) {

	cmd.StringVar(&config.Pidfile, []string{"p", "-pidfile"}, defaultPidFile, usageFn("Path to use for daemon PID file"))
	cmd.StringVar(&config.LogConfig.Type, []string{"-log-driver"}, "json-file", usageFn("Default driver for container logs"))
	cmd.Var(opts.NewNamedMapOpts("log-opts", config.LogConfig.Config, nil), []string{"-log-opt"}, usageFn("Default log driver options for containers"))
}

// IsValueSet returns true if a configuration value
// was explicitly set in the configuration file.
func (config *Config) IsValueSet(name string) bool {
	if config.valuesSet == nil {
		return false
	}
	_, ok := config.valuesSet[name]
	return ok
}


// ReloadConfiguration reads the configuration in the host and reloads the daemon and server.
func ReloadConfiguration(configFile string, flags *flag.FlagSet, reload func(*Config)) error {
	logrus.Infof("Got signal to reload configuration, reloading from: %s", configFile)
	newConfig, err := getConflictFreeConfiguration(configFile, flags)
	if err != nil {
		return err
	}

	if err := ValidateConfiguration(newConfig); err != nil {
		return fmt.Errorf("file configuration validation failed (%v)", err)
	}

	reload(newConfig)
	return nil
}

// boolValue is an interface that boolean value flags implement
// to tell the command line how to make -name equivalent to -name=true.
type boolValue interface {
	IsBoolFlag() bool
}

// MergeDaemonConfigurations reads a configuration file,
// loads the file configuration in an isolated structure,
// and merges the configuration provided from flags on top
// if there are no conflicts.
func MergeDaemonConfigurations(flagsConfig *Config, flags *flag.FlagSet, configFile string) (*Config, error) {
	fileConfig, err := getConflictFreeConfiguration(configFile, flags)
	if err != nil {
		return nil, err
	}

	if err := ValidateConfiguration(fileConfig); err != nil {
		return nil, fmt.Errorf("file configuration validation failed (%v)", err)
	}

	// merge flags configuration on top of the file configuration
	if err := mergo.Merge(fileConfig, flagsConfig); err != nil {
		return nil, err
	}

	// We need to validate again once both fileConfig and flagsConfig
	// have been merged
	if err := ValidateConfiguration(fileConfig); err != nil {
		return nil, fmt.Errorf("file configuration validation failed (%v)", err)
	}

	return fileConfig, nil
}

// getConflictFreeConfiguration loads the configuration from a JSON file.
// It compares that configuration with the one provided by the flags,
// and returns an error if there are conflicts.
func getConflictFreeConfiguration(configFile string, flags *flag.FlagSet) (*Config, error) {
	b, err := ioutil.ReadFile(configFile)
	if err != nil {
		return nil, err
	}

	var config Config
	var reader io.Reader
	if flags != nil {
		var jsonConfig map[string]interface{}
		reader = bytes.NewReader(b)
		if err := json.NewDecoder(reader).Decode(&jsonConfig); err != nil {
			return nil, err
		}

		configSet := configValuesSet(jsonConfig)

		if err := findConfigurationConflicts(configSet, flags); err != nil {
			return nil, err
		}

		// Override flag values to make sure the values set in the config file with nullable values, like `false`,
		// are not overridden by default truthy values from the flags that were not explicitly set.
		// See https://github.com/docker/docker/issues/20289 for an example.
		//
		// TODO: Rewrite configuration logic to avoid same issue with other nullable values, like numbers.
		namedOptions := make(map[string]interface{})
		for key, value := range configSet {
			f := flags.Lookup("-" + key)
			if f == nil { // ignore named flags that don't match
				namedOptions[key] = value
				continue
			}

			if _, ok := f.Value.(boolValue); ok {
				f.Value.Set(fmt.Sprintf("%v", value))
			}
		}
		if len(namedOptions) > 0 {
			// set also default for mergeVal flags that are boolValue at the same time.
			flags.VisitAll(func(f *flag.Flag) {
				if opt, named := f.Value.(opts.NamedOption); named {
					v, set := namedOptions[opt.Name()]
					_, boolean := f.Value.(boolValue)
					if set && boolean {
						f.Value.Set(fmt.Sprintf("%v", v))
					}
				}
			})
		}

		config.valuesSet = configSet
	}

	reader = bytes.NewReader(b)
	err = json.NewDecoder(reader).Decode(&config)
	return &config, err
}

// configValuesSet returns the configuration values explicitly set in the file.
func configValuesSet(config map[string]interface{}) map[string]interface{} {
	flatten := make(map[string]interface{})
	for k, v := range config {
		if m, isMap := v.(map[string]interface{}); isMap && !flatOptions[k] {
			for km, vm := range m {
				flatten[km] = vm
			}
			continue
		}

		flatten[k] = v
	}
	return flatten
}

// findConfigurationConflicts iterates over the provided flags searching for
// duplicated configurations and unknown keys. It returns an error with all the conflicts if
// it finds any.
func findConfigurationConflicts(config map[string]interface{}, flags *flag.FlagSet) error {
	// 1. Search keys from the file that we don't recognize as flags.
	unknownKeys := make(map[string]interface{})
	for key, value := range config {
		flagName := "-" + key
		if flag := flags.Lookup(flagName); flag == nil {
			unknownKeys[key] = value
		}
	}

	// 2. Discard values that implement NamedOption.
	// Their configuration name differs from their flag name, like `labels` and `label`.
	if len(unknownKeys) > 0 {
		unknownNamedConflicts := func(f *flag.Flag) {
			if namedOption, ok := f.Value.(opts.NamedOption); ok {
				if _, valid := unknownKeys[namedOption.Name()]; valid {
					delete(unknownKeys, namedOption.Name())
				}
			}
		}
		flags.VisitAll(unknownNamedConflicts)
	}

	if len(unknownKeys) > 0 {
		var unknown []string
		for key := range unknownKeys {
			unknown = append(unknown, key)
		}
		return fmt.Errorf("the following directives don't match any configuration option: %s", strings.Join(unknown, ", "))
	}

	var conflicts []string
	printConflict := func(name string, flagValue, fileValue interface{}) string {
		return fmt.Sprintf("%s: (from flag: %v, from file: %v)", name, flagValue, fileValue)
	}

	// 3. Search keys that are present as a flag and as a file option.
	duplicatedConflicts := func(f *flag.Flag) {
		// search option name in the json configuration payload if the value is a named option
		if namedOption, ok := f.Value.(opts.NamedOption); ok {
			if optsValue, ok := config[namedOption.Name()]; ok {
				conflicts = append(conflicts, printConflict(namedOption.Name(), f.Value.String(), optsValue))
			}
		} else {
			// search flag name in the json configuration payload without trailing dashes
			for _, name := range f.Names {
				name = strings.TrimLeft(name, "-")

				if value, ok := config[name]; ok {
					conflicts = append(conflicts, printConflict(name, f.Value.String(), value))
					break
				}
			}
		}
	}

	flags.Visit(duplicatedConflicts)

	if len(conflicts) > 0 {
		return fmt.Errorf("the following directives are specified both as a flag and in the configuration file: %s", strings.Join(conflicts, ", "))
	}
	return nil
}

// ValidateConfiguration validates some specific configs.
// such as config.DNS, config.Labels, config.DNSSearch,
// as well as config.MaxConcurrentDownloads, config.MaxConcurrentUploads.
func ValidateConfiguration(config *Config) error {

	return nil
}
