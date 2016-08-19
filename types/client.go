// This will hold the definition of the structures, functions, etc.
// required for client-server communication.

// NOTE: This should not consist of types related to OpenEBS storage !!!

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
