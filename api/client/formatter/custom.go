package formatter

import (
	"strings"

	"github.com/openebs/openebs/types"
)

const (
	tableKey = "table"

	vsmNameHeader		= "VSM NAME"
	ipAddrHeader		= "IP Address"
	statusHeader		= "STATUS"
)

type vsmContext struct {
	baseSubContext
	v     types.Vsm
}

func (c *vsmContext) Name() string {
	c.addHeader(vsmNameHeader)
	return c.v.Name
}


func (c *vsmContext) IPAddress() string {
	c.addHeader(ipAddrHeader)
	if c.v.IPAddress == "" {
		return "<no addr>"
	}
	return c.v.IPAddress
}


func (c *vsmContext) Status() string {
	c.addHeader(statusHeader)
	return c.v.Status
}



type subContext interface {
	fullHeader() string
	addHeader(header string)
}

type baseSubContext struct {
	header []string
}

func (c *baseSubContext) fullHeader() string {
	if c.header == nil {
		return ""
	}
	return strings.Join(c.header, "\t")
}

func (c *baseSubContext) addHeader(header string) {
	if c.header == nil {
		c.header = []string{}
	}
	c.header = append(c.header, strings.ToUpper(header))
}

func stripNamePrefix(ss []string) []string {
	sss := make([]string, len(ss))
	for i, s := range ss {
		sss[i] = s[1:]
	}

	return sss
}
