package formatter

import (
	"bytes"
	"fmt"
	"io"
	"strings"
	"text/tabwriter"
	"text/template"

	"github.com/openebs/openebs/utils/templates"
	"github.com/openebs/openebs/types"
)

const (
	tableFormatKey = "table"
	rawFormatKey   = "raw"

	defaultVsmTableFormat       = "table {{.Name}}\t{{.IPAddress}}\t{{.Status}}"
	defaultQuietFormat                = "{{.Name}}"
)

// Context contains information required by the formatter to print the output as desired.
type Context struct {
	// Output is the output stream to which the formatted string is written.
	Output io.Writer
	// Format is used to choose raw, table or custom format for the output.
	Format string
	// Quiet when set to true will simply print minimal information.
	Quiet bool

	// internal element
	table       bool
	finalFormat string
	header      string
	buffer      *bytes.Buffer
}

func (c *Context) preformat() {
	c.finalFormat = c.Format

	if strings.HasPrefix(c.Format, tableKey) {
		c.table = true
		c.finalFormat = c.finalFormat[len(tableKey):]
	}

	c.finalFormat = strings.Trim(c.finalFormat, " ")
	r := strings.NewReplacer(`\t`, "\t", `\n`, "\n")
	c.finalFormat = r.Replace(c.finalFormat)
}

func (c *Context) parseFormat() (*template.Template, error) {
	tmpl, err := templates.Parse(c.finalFormat)
	if err != nil {
		c.buffer.WriteString(fmt.Sprintf("Template parsing error: %v\n", err))
		c.buffer.WriteTo(c.Output)
	}
	return tmpl, err
}

func (c *Context) postformat(tmpl *template.Template, subContext subContext) {
	if c.table {
		if len(c.header) == 0 {
			// if we still don't have a header, we didn't have any vsms so we need to fake it to get the right headers from the template
			tmpl.Execute(bytes.NewBufferString(""), subContext)
			c.header = subContext.fullHeader()
		}

		t := tabwriter.NewWriter(c.Output, 20, 1, 3, ' ', 0)
		t.Write([]byte(c.header))
		t.Write([]byte("\n"))
		c.buffer.WriteTo(t)
		t.Flush()
	} else {
		c.buffer.WriteTo(c.Output)
	}
}

func (c *Context) contextFormat(tmpl *template.Template, subContext subContext) error {
	if err := tmpl.Execute(c.buffer, subContext); err != nil {
		c.buffer = bytes.NewBufferString(fmt.Sprintf("Template parsing error: %v\n", err))
		c.buffer.WriteTo(c.Output)
		return err
	}
	if c.table && len(c.header) == 0 {
		c.header = subContext.fullHeader()
	}
	c.buffer.WriteString("\n")
	return nil
}

// VsmContext contains vsm specific information required by the formater, encapsulate a Context struct.
type VsmContext struct {
	Context
	// VSMs
	Vsms []types.Vsm
}

func (ctx VsmContext) Write() {
	switch ctx.Format {
	case tableFormatKey:
		if ctx.Quiet {
			ctx.Format = defaultQuietFormat
		} else {
			ctx.Format = defaultVsmTableFormat
		}
	case rawFormatKey:
		if ctx.Quiet {
			ctx.Format = `vsm_name: {{.Name}}`
		} else {
			ctx.Format = `vsm_name: {{.Name}}\nipaddr: {{.IPAddress}}\nstatus: {{.Status}}\n`
		}
	}

	ctx.buffer = bytes.NewBufferString("")
	ctx.preformat()

	tmpl, err := ctx.parseFormat()
	if err != nil {
		return
	}

	for _, vsm := range ctx.Vsms {
		vsmCtx := &vsmContext{
			v:     vsm,
		}
		err = ctx.contextFormat(tmpl, vsmCtx)
		if err != nil {
			return
		}
	}

	ctx.postformat(tmpl, &vsmContext{})
}

