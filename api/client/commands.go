package client

// Command returns a cli command handler if one exists
func (cli *OpenEBSCli) Command(name string) func(...string) error {
	// Names of commands are keys in this map
	// The command handlers i.e. functions are the values in this map
	return map[string]func(...string) error{
	}[name]
}
