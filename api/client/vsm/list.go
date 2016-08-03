// Copyright 2016 CloudByte, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package vsm

import (
	"golang.org/x/net/context"

	"github.com/openebs/openebs/api/client"
	"github.com/openebs/openebs/api/client/formatter"
	"github.com/openebs/openebs/cli"
	"github.com/openebs/openebs/pkg/spf13/cobra"
	"github.com/openebs/openebs/types"
)

type listOptions struct {
	all 	bool
	quiet 	bool
	format 	string
}

type preProcessor struct {
	opts *types.VSMListOptions
}

// NewPsCommand creates a new cobra.Command for `docker ps`
func NewVSMListCommand(openEBSCli *client.OpenEBSCli) *cobra.Command {
	var opts listOptions

	cmd := &cobra.Command{
		Use:   "vsm-ls [OPTIONS]",
		Short: "List VSMs",
		Args:  cli.ExactArgs(0),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runList(openEBSCli, &opts)
		},
	}

	flags := cmd.Flags()

	flags.BoolVarP(&opts.all, "all", "a", false, "Show all VSMs (default shows just running)")
	flags.BoolVarP(&opts.quiet, "quiet", "q", false, "Only display Names")
	flags.StringVarP(&opts.format, "format", "", "", "Pretty-print VSMs")

	return cmd
}

func runList(openEBSCli *client.OpenEBSCli, opts *listOptions) error {
	ctx := context.Background()

	options := types.VSMListOptions{
		All: opts.all,
	}


	vsms, err := openEBSCli.Client().VSMList(ctx, options)
	if err != nil {
		return err
	}

	f := opts.format
	if len(f) == 0 {
		if len(openEBSCli.ListFormat()) > 0 {
			f = openEBSCli.ListFormat()
		} else {
			f = "table"
		}
	}

	lsCtx := formatter.VsmContext {
		Context: formatter.Context{
			Output: openEBSCli.Out(),
			Format: f,
			Quiet: opts.quiet,
		},
		Vsms: vsms,
	}

	lsCtx.Write()

	//if len(vsms) > 0 {
	//	fmt.Fprintf(openEBSCli.Out(), "Total VSMs %d\n", len(vsms))
	//} else {
	//	fmt.Fprintf(openEBSCli.Out(), "No VSMs\n")
	//}
	return nil
}
