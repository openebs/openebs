package cobraadaptor

import (
	"github.com/openebs/openebs/api/client"
	"github.com/openebs/openebs/api/client/system"
	"github.com/openebs/openebs/api/client/vsm"
	"github.com/openebs/openebs/cli"
	cliflags "github.com/openebs/openebs/cli/flags"
	"github.com/openebs/openebs/pkg/spf13/cobra"
	"github.com/openebs/openebs/pkg/term"
)

// CobraAdaptor is an adaptor for supporting spf13/cobra commands in the
// openebs/cli framework
type CobraAdaptor struct {
	rootCmd    *cobra.Command
	openEBSCli *client.OpenEBSCli
}

// NewCobraAdaptor returns a new handler
func NewCobraAdaptor(clientFlags *cliflags.ClientFlags) CobraAdaptor {
	stdin, stdout, stderr := term.StdStreams()
	openEBSCli := client.NewOpenEBSCli(stdin, stdout, stderr, clientFlags)

	var rootCmd = &cobra.Command{
		Use:           "openebs [OPTIONS]",
		Short:         "A self-sufficient runtime for elastic block storage",
		SilenceUsage:  true,
		SilenceErrors: true,
	}
	rootCmd.SetUsageTemplate(usageTemplate)
	rootCmd.SetHelpTemplate(helpTemplate)
	rootCmd.SetFlagErrorFunc(cli.FlagErrorFunc)
	rootCmd.SetOutput(stdout)
	rootCmd.AddCommand(
		system.NewVersionCommand(openEBSCli),
		system.NewInfoCommand(openEBSCli),
		vsm.NewVSMListCommand(openEBSCli),
	)

	rootCmd.PersistentFlags().BoolP("help", "h", false, "Print usage")
	rootCmd.PersistentFlags().MarkShorthandDeprecated("help", "please use --help")

	return CobraAdaptor{
		rootCmd:    rootCmd,
		openEBSCli: openEBSCli,
	}
}

// Usage returns the list of commands and their short usage string for
// all top level cobra commands.
func (c CobraAdaptor) Usage() []cli.Command {
	cmds := []cli.Command{}
	for _, cmd := range c.rootCmd.Commands() {
		if cmd.Name() != "" {
			cmds = append(cmds, cli.Command{Name: cmd.Name(), Description: cmd.Short})
		}
	}
	return cmds
}

func (c CobraAdaptor) run(cmd string, args []string) error {
	if err := c.openEBSCli.Initialize(); err != nil {
		return err
	}
	// Prepend the command name to support normal cobra command delegation
	c.rootCmd.SetArgs(append([]string{cmd}, args...))
	return c.rootCmd.Execute()
}

// Command returns a cli command handler if one exists
func (c CobraAdaptor) Command(name string) func(...string) error {
	for _, cmd := range c.rootCmd.Commands() {
		if cmd.Name() == name {
			return func(args ...string) error {
				return c.run(name, args)
			}
		}
	}
	return nil
}

// GetRootCommand returns the root command. Required to generate the man pages
// and reference docs from a script outside this package.
func (c CobraAdaptor) GetRootCommand() *cobra.Command {
	return c.rootCmd
}

var usageTemplate = `Usage:	{{if not .HasSubCommands}}{{.UseLine}}{{end}}{{if .HasSubCommands}}{{ .CommandPath}} COMMAND{{end}}

{{ .Short | trim }}{{if gt .Aliases 0}}

Aliases:
  {{.NameAndAliases}}{{end}}{{if .HasExample}}

Examples:
{{ .Example }}{{end}}{{if .HasFlags}}

Options:
{{.Flags.FlagUsages | trimRightSpace}}{{end}}{{ if .HasAvailableSubCommands}}

Commands:{{range .Commands}}{{if .IsAvailableCommand}}
  {{rpad .Name .NamePadding }} {{.Short}}{{end}}{{end}}{{end}}{{ if .HasSubCommands }}

Run '{{.CommandPath}} COMMAND --help' for more information on a command.{{end}}
`

var helpTemplate = `
{{if or .Runnable .HasSubCommands}}{{.UsageString}}{{end}}`
