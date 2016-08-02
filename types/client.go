// This will hold the definition of the structures, functions, etc.
// required for client-server communication.
package types

// This holds version information for the client and the server
type VersionResponse struct {
	Client *Version
	Server *Version
}

// ServerOK returns true when the client could connect to the openebs server
// and parse the information received. It returns false otherwise.
func (v VersionResponse) ServerOK() bool {
	return v.Server != nil
}

// This holds paramters required to list the VSMs.
type VSMListOptions struct {
	All bool
}

// This holds parameters required to create a VSM.
type VSMCreateOptions struct {
	Name      string
	IP        string
	Interface string
	Subnet    string
	Router    string
	Volume    string
}
