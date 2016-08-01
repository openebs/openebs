package system

import (
	"fmt"

	"golang.org/x/net/context"

	"github.com/docker/go-units"

	"github.com/openebs/openebs/api/client"
	"github.com/openebs/openebs/cli"
	"github.com/openebs/openebs/pkg/ioutils"
	"github.com/openebs/openebs/utils"
	"github.com/openebs/openebs/pkg/spf13/cobra"
)

// NewInfoCommand creates a new cobra.Command for `openebs info`
func NewInfoCommand(openEBSCli *client.OpenEBSCli) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "info",
		Short: "Display system-wide information",
		Args:  cli.ExactArgs(0),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runInfo(openEBSCli)
		},
	}
	return cmd

}

func runInfo(openEBSCli *client.OpenEBSCli) error {
	ctx := context.Background()
	info, err := openEBSCli.Client().Info(ctx)
	if err != nil {
		return err
	}

	ioutils.FprintfIfNotEmpty(openEBSCli.Out(), "Server Version: %s\n", info.ServerVersion)
	ioutils.FprintfIfNotEmpty(openEBSCli.Out(), "Kernel Version: %s\n", info.KernelVersion)
	ioutils.FprintfIfNotEmpty(openEBSCli.Out(), "Operating System: %s\n", info.OperatingSystem)
	ioutils.FprintfIfNotEmpty(openEBSCli.Out(), "OSType: %s\n", info.OSType)
	ioutils.FprintfIfNotEmpty(openEBSCli.Out(), "Architecture: %s\n", info.Architecture)
	fmt.Fprintf(openEBSCli.Out(), "CPUs: %d\n", info.NCPU)
	fmt.Fprintf(openEBSCli.Out(), "Total Memory: %s\n", units.BytesSize(float64(info.MemTotal)))
	ioutils.FprintfIfNotEmpty(openEBSCli.Out(), "ID: %s\n", info.ID)
	fmt.Fprintf(openEBSCli.Out(), "Debug Mode (client): %v\n", utils.IsDebugEnabled())
	fmt.Fprintf(openEBSCli.Out(), "Debug Mode (server): %v\n", info.Debug)


	return nil
}
