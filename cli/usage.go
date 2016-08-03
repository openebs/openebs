package cli

// Command is the struct containing the command name and description
type Command struct {
	Name        string
	Description string
}

// OpenEBSCommandUsage lists the top level openebs commands and their short usage
var OpenEBSCommandUsage = []Command{
}

// OpenEBSCommands stores all the openebs command
var OpenEBSCommands = make(map[string]Command)

func init() {
	for _, cmd := range OpenEBSCommandUsage {
		OpenEBSCommands[cmd.Name] = cmd
	}
}
