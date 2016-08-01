package system

import (
	"runtime"
	"time"

	"golang.org/x/net/context"

	"github.com/openebs/openebs/api/client"
	"github.com/openebs/openebs/cli"
	"github.com/openebs/openebs/version"
	"github.com/openebs/openebs/utils/templates"
	"github.com/openebs/openebs/types"
	"github.com/openebs/openebs/pkg/spf13/cobra"
)

var versionTemplate = `Client:
 Version:      {{.Client.Version}}
 API version:  {{.Client.APIVersion}}
 Go version:   {{.Client.GoVersion}}
 Git commit:   {{.Client.GitCommit}}
 Built:        {{.Client.BuildTime}}
 OS/Arch:      {{.Client.Os}}/{{.Client.Arch}}{{if .Client.Experimental}}
 Experimental: {{.Client.Experimental}}{{end}}{{if .ServerOK}}

Server:
 Version:      {{.Server.Version}}
 API version:  {{.Server.APIVersion}}
 Go version:   {{.Server.GoVersion}}
 Git commit:   {{.Server.GitCommit}}
 Built:        {{.Server.BuildTime}}
 OS/Arch:      {{.Server.Os}}/{{.Server.Arch}}{{if .Server.Experimental}}
 Experimental: {{.Server.Experimental}}{{end}}{{end}}`

type versionOptions struct {
	format string
}

// NewVersionCommand creates a new cobra.Command for `openebs version`
func NewVersionCommand(openEBSCli *client.OpenEBSCli) *cobra.Command {
	var opts versionOptions

	cmd := &cobra.Command{
		Use:   "version [OPTIONS]",
		Short: "Show the OpenEBS version information",
		Args:  cli.ExactArgs(0),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runVersion(openEBSCli, &opts)
		},
	}

	flags := cmd.Flags()

	flags.StringVarP(&opts.format, "format", "f", "", "Format the output using the given go template")

	return cmd
}

func runVersion(openEBSCli *client.OpenEBSCli, opts *versionOptions) error {
	ctx := context.Background()

	templateFormat := versionTemplate
	if opts.format != "" {
		templateFormat = opts.format
	}

	tmpl, err := templates.Parse(templateFormat)
	if err != nil {
		return cli.StatusError{StatusCode: 64,
			Status: "Template parsing error: " + err.Error()}
	}

	vd := types.VersionResponse{
		Client: &types.Version{
			Version:      version.Version,
			APIVersion:   openEBSCli.Client().ClientVersion(),
			GoVersion:    runtime.Version(),
			GitCommit:    version.GitCommit,
			BuildTime:    version.BuildTime,
			Os:           runtime.GOOS,
			Arch:         runtime.GOARCH,
		},
	}

	serverVersion, err := openEBSCli.Client().ServerVersion(ctx)
	if err == nil {
		vd.Server = &serverVersion
	}

	// first we need to make BuildTime more human friendly
	t, errTime := time.Parse(time.RFC3339Nano, vd.Client.BuildTime)
	if errTime == nil {
		vd.Client.BuildTime = t.Format(time.ANSIC)
	}

	if vd.ServerOK() {
		t, errTime = time.Parse(time.RFC3339Nano, vd.Server.BuildTime)
		if errTime == nil {
			vd.Server.BuildTime = t.Format(time.ANSIC)
		}
	}

	if err2 := tmpl.Execute(openEBSCli.Out(), vd); err2 != nil && err == nil {
		err = err2
	}
	openEBSCli.Out().Write([]byte{'\n'})
	return err
}
