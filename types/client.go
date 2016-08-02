package types

// VersionResponse holds version information for the client and the server
type VersionResponse struct {
	Client *Version
	Server *Version
}

// ServerOK returns true when the client could connect to the openebs server
// and parse the information received. It returns false otherwise.
func (v VersionResponse) ServerOK() bool {
	return v.Server != nil
}

// VSMListOptions holds paramters to list the VSMs
type VSMListOptions struct {
        All		bool
}
