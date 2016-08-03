package client

// Command returns a cli command handler if one exists
func (cli *OpenEBSCli) Command(name string) func(...string) error {
	// Names of commands are keys (of type string) in this map
	// The command handlers are values (of type func(...string) error) in this map
	return map[string]func(...string) error{
	}[name]
}
