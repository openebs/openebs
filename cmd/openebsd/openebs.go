package main

import (
	"fmt"
	"os"

	"github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/version"
	flag "github.com/openebs/openebs/pkg/mflag"
	"github.com/openebs/openebs/pkg/term"
)

var (
	daemonCli = NewDaemonCli()
	flHelp    = flag.Bool([]string{"h", "-help"}, false, "Print usage")
	flVersion = flag.Bool([]string{"v", "-version"}, false, "Print version information and quit")
)

func main() {

	// Set terminal emulation based on platform as required.
	_, stdout, stderr := term.StdStreams()

	logrus.SetOutput(stderr)

	flag.Merge(flag.CommandLine, daemonCli.commonFlags.FlagSet)

	flag.Usage = func() {
		fmt.Fprint(stdout, "Usage: openebsd [OPTIONS]\n\n")
		fmt.Fprint(stdout, "A self-sufficient runtime for containers.\n\nOptions:\n")

		flag.CommandLine.SetOutput(stdout)
		flag.PrintDefaults()
	}
	flag.CommandLine.ShortUsage = func() {
		fmt.Fprint(stderr, "\nUsage:\topenebsd [OPTIONS]\n")
	}

	if err := flag.CommandLine.ParseFlags(os.Args[1:], false); err != nil {
		os.Exit(1)
	}

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

        // On Windows, this may be launching as a service or with an option to
        // register the service.
        stop, err := initService()
        if err != nil {
                logrus.Fatal(err)
        }


	if !stop {
		err = daemonCli.start()
		notifyShutdown(err)
		if err != nil {
			logrus.Fatal(err)
		}
	}
}

func showVersion() {
	fmt.Printf("OpenEBS version %s, build %s\n", version.Version, version.GitCommit)
}
