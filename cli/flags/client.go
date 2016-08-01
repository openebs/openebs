package flags

import flag "github.com/openebs/openebs/pkg/mflag"

// ClientFlags represents flags for the OpenEBS client.
type ClientFlags struct {
	FlagSet   *flag.FlagSet
	Common    *CommonFlags
	PostParse func()

	ConfigDir string
}
