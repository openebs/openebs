package main

import (
	"fmt"
	"os"

	"github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/api/client"
	"github.com/openebs/openebs/cli"
	"github.com/openebs/openebs/cli/cobraadaptor"
	cliflags "github.com/openebs/openebs/cli/flags"
	"github.com/openebs/openebs/cliconfig"
	"github.com/openebs/openebs/version"
	flag "github.com/openebs/openebs/pkg/mflag"
	"github.com/openebs/openebs/pkg/term"
	"github.com/openebs/openebs/utils"
)

var (
	commonFlags = cliflags.InitCommonFlags()
	clientFlags = initClientFlags(commonFlags)
	flHelp      = flag.Bool([]string{"h", "-help"}, false, "Print usage")
	flVersion   = flag.Bool([]string{"v", "-version"}, false, "Print version information and quit")
)

func main() {
	// Set terminal emulation based on platform as required.
	stdin, stdout, stderr := term.StdStreams()

	logrus.SetOutput(stderr)

	flag.Merge(flag.CommandLine, clientFlags.FlagSet, commonFlags.FlagSet)

	cobraAdaptor := cobraadaptor.NewCobraAdaptor(clientFlags)

	flag.Usage = func() {
		fmt.Fprint(stdout, "Usage: openebs [OPTIONS] COMMAND [arg...]\n       openebs [ --help | -v | --version ]\n\n")
		fmt.Fprint(stdout, "A self-sufficient runtime for block storage.\n\nOptions:\n")

		flag.CommandLine.SetOutput(stdout)
		flag.PrintDefaults()

		help := "\nCommands:\n"

		openEBSCommands := append(cli.OpenEBSCommandUsage, cobraAdaptor.Usage()...)
		for _, cmd := range sortCommands(openEBSCommands) {
			help += fmt.Sprintf("    %-16.10s%s\n", cmd.Name, cmd.Description)
		}

		help += "\nRun 'openebs COMMAND --help' for more information on a command."
		fmt.Fprintf(stdout, "%s\n", help)
	}

	flag.Parse()

	if *flVersion {
		showVersion()
		return
	}

	if *flHelp {
		// if global flag --help is present, regardless of what other options and commands there are,
		// just print the usage.
		flag.Usage()
		return
	}

	clientCli := client.NewOpenEBSCli(stdin, stdout, stderr, clientFlags)

	c := cli.New(clientCli, NewDaemonProxy(), cobraAdaptor)
	if err := c.Run(flag.Args()...); err != nil {
		if sterr, ok := err.(cli.StatusError); ok {
			if sterr.Status != "" {
				fmt.Fprintln(stderr, sterr.Status)
			}
			// StatusError should only be used for errors, and all errors should
			// have a non-zero exit status, so never exit with 0
			if sterr.StatusCode == 0 {
				os.Exit(1)
			}
			os.Exit(sterr.StatusCode)
		}
		fmt.Fprintln(stderr, err)
		os.Exit(1)
	}
}

func showVersion() {
	fmt.Printf("OpenEBS version %s, build %s\n", version.Version, version.GitCommit)
}

func initClientFlags(commonFlags *cliflags.CommonFlags) *cliflags.ClientFlags {
	clientFlags := &cliflags.ClientFlags{FlagSet: new(flag.FlagSet), Common: commonFlags}
	client := clientFlags.FlagSet
	client.StringVar(&clientFlags.ConfigDir, []string{"-config"}, cliconfig.ConfigDir(), "Location of client config files")

	clientFlags.PostParse = func() {
		clientFlags.Common.PostParse()

		if clientFlags.ConfigDir != "" {
			cliconfig.SetConfigDir(clientFlags.ConfigDir)
		}

		if clientFlags.Common.Debug {
			utils.EnableDebug()
		}
	}
	return clientFlags
}
