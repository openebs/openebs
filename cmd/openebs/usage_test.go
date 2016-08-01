package main

import (
	"sort"
	"testing"

	"github.com/openebs/openebs/cli"
)

// Tests if the subcommands of OpenEBS are sorted
func TestOpenEBSSubcommandsAreSorted(t *testing.T) {
	if !sort.IsSorted(byName(cli.OpenEBSCommandUsage)) {
		t.Fatal("OpenEBS subcommands are not in sorted order")
	}
}
