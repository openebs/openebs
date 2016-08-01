package main

import (
	"sort"

	"github.com/openebs/openebs/cli"
)

type byName []cli.Command

func (a byName) Len() int           { return len(a) }
func (a byName) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a byName) Less(i, j int) bool { return a[i].Name < a[j].Name }

func sortCommands(commands []cli.Command) []cli.Command {
	openEBSCommands := make([]cli.Command, len(commands))
	copy(openEBSCommands, commands)
	sort.Sort(byName(openEBSCommands))
	return openEBSCommands
}
