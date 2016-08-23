package types

// Port stores open ports info of container
// e.g. {"PrivatePort": 8080, "PublicPort": 80, "Type": "tcp"}
type Port struct {
	IP          string `json:",omitempty"`
	PrivatePort int
	PublicPort  int `json:",omitempty"`
	Type        string
}

// Version contains response of Remote API:
// GET "/version"
type Version struct {
	Version       string
	APIVersion    string `json:"ApiVersion"`
	GitCommit     string
	GoVersion     string
	Os            string
	Arch          string
	KernelVersion string `json:",omitempty"`
	Experimental  bool   `json:",omitempty"`
	BuildTime     string `json:",omitempty"`
}

// Info contains response of Remote API:
// GET "/info"
type Info struct {
	ID                string
	Debug             bool
	SystemTime        string
	KernelVersion     string
	OperatingSystem   string
	OSType            string
	Architecture      string
	NCPU              int
	MemTotal          int64
	ExperimentalBuild bool
	ServerVersion     string
}

// Used for response from Remote API:
// GET "/vsm/lsjson"
// POST "/vsm/create"
// TODO deprecate
type Vsm struct {
	Name      string
	IPAddress string
	IOPS      string
	Volumes   string
	Status    string
}

/////////////////////////
// Storage Types
/////////////////////////

// Generic Type
type OEBSType interface {
}

type NameID struct {
	Name string
	Id   string
	Desc string
}

type Storage struct {
	Size uint64
	Iops uint64
}

type Network struct {
	Ip     string
	Iface  string
	Subnet string
	Router string
}

type Message struct {
	Id    string
	Level string
	Desc  string
}

type Response struct {
	Val    OEBSType
	Infos  []Message
	Errors []Message
	Warns  []Message
}

type VsmV2 struct {
	NameID
	Network
	Vols []Volume
}

type Volume struct {
	NameID
	Storage
}

///////////////////
// Options w.r.t storage operations
///////////////////

// Various options whose combinations will determine
// the storage operation. These will play a crucial
// role in executing the vanilla operation
// or a variation of the operation.

type OptionType string

// Various options that may be exercised during
// a request against a particular operation.
const (
	// Pure options
	IopsOpt    OptionType = "iops"
	SizeOpt    OptionType = "size"
	UsageOpt   OptionType = "usage"
	NoneOpt    OptionType = "none"
	DefaultOpt OptionType = "default"
	IssuesOpt  OptionType = "issues"
	// Verbose mode
	AllOpt     OptionType = "all"
	ProfileOpt OptionType = "profile"

	// Derived options based on combinations of above types
	ProfileIssuesOpt OptionType = "pissues"

	// Not sure if this is the right place !!
	VersionOpt OptionType = "version"
)

// An option can be value based or range based.
type Option struct {
	Type  OptionType
	Truth bool
	Val   string
	Min   uint64
	Max   uint64
}

func FirstOptType(options []Option) OptionType {

	optionType := DefaultOpt

	if nil == options || 0 == len(options) {
		return optionType
	}

	// return the very first option type
	return options[0].Type
}

func LastOptType(options []Option) OptionType {

	optionType := DefaultOpt

	if nil == options || 0 == len(options) {
		return optionType
	}

	// return the last option type
	return options[len(options)-1].Type
}

func getOptTypes(options []Option) []OptionType {

	optTypes := []OptionType{}

	if nil == options || 0 == len(options) {
		optTypes = append(optTypes, NoneOpt)
		return optTypes
	}

	for _, option := range options {
		optTypes = append(optTypes, option.Type)
	}

	return optTypes
}

// Checks if the provided collection has the required type.
func hasOptType(providedOptTypes []OptionType, requiredOptType OptionType) bool {

	for _, providedOptType := range providedOptTypes {
		if providedOptType == requiredOptType {
			// break out in case of a successful match
			return true
		}
	}

	return false
}

// Checks if the provided collection has all the required types.
// In other words, it checks if the provided collection is a superset of required collection.
func isSuperSetOptTypes(providedOptTypes []OptionType, requiredOptTypes ...OptionType) bool {

	truthy := true

	for _, requiredOptType := range requiredOptTypes {
		truthy = hasOptType(providedOptTypes, requiredOptType)

		// break out if no match
		if !truthy {
			return truthy
		}
	}

	return truthy
}

// This logic is critical to the functioning of any OpenEBS operation.
// We assume that any OpenEBS operation can have multiple variants/modes of
// execution.
//
// e.g. It may be a vanilla execution or a profiled execution or execution of a
// particular version, etc.
//
// NOTE - Logic will be correct when choice of options are exercized properly.
// TODO - Can this be re-factored to a fitting structural pattern !!!
func InferredOptType(providedOptions []Option) OptionType {

	providedOptTypes := getOptTypes(providedOptions)

	// This is the verbose mode.
	// This indicates the combination of all possible modes of an operation.
	// This will be a time taking operation.
	optA := []OptionType{AllOpt}

	// This mode will profile the execution, collect the
	// possible errors, warnings, etc in addition to executing
	// the given operation.
	// e.g. list VSMs by exposing default properties of each VSM
	// along with the errors that have happened so far within each
	// of these VSMs and finally include the profiling details during
	// the listing of each VSM.
	optPnI := []OptionType{ProfileOpt, IssuesOpt}

	// This mode will profile in addition to executing the given operation.
	optPnD := []OptionType{ProfileOpt, DefaultOpt}

	// This mode will collect the possible errors, warnings, etc
	// in addition to executing the given operation.
	optI := []OptionType{IssuesOpt}

	// This is same as profile & default mode of operation.
	optP := []OptionType{ProfileOpt}

	// This mode is the vanilla execution of any operation.
	// This mode is expected to be used often.
	optD := []OptionType{DefaultOpt}

	// This is the mode when client does not provide any
	// mode of operation.
	optN := []OptionType{NoneOpt}

	// If provided option types is a superset of All mode
	if isSuperSetOptTypes(providedOptTypes, optA...) {
		return AllOpt

		// If provided option types is a superset of Profile & Issues mode
	} else if isSuperSetOptTypes(providedOptTypes, optPnI...) {
		return ProfileIssuesOpt

		// If provided option types is a superset of Profile & Default mode
	} else if isSuperSetOptTypes(providedOptTypes, optPnD...) {
		return ProfileOpt

		// If provided option types is a superset of Issues mode
	} else if isSuperSetOptTypes(providedOptTypes, optI...) {
		return IssuesOpt

		// If provided option types is a superset of Profile mode
	} else if isSuperSetOptTypes(providedOptTypes, optP...) {
		return ProfileOpt

		// If provided option types is a superset of Default mode
	} else if isSuperSetOptTypes(providedOptTypes, optD...) {
		return DefaultOpt

		// If provided option types is a superset of None mode
	} else if isSuperSetOptTypes(providedOptTypes, optN...) {
		return NoneOpt

	}

	return NoneOpt
}

// A public function that may be invoked to return default mode
// if the provided mode is none type.
func SetOptToDefaultIfNone(providedOptType OptionType) OptionType {

	if providedOptType == NoneOpt {
		return DefaultOpt
	}

	return providedOptType
}

///////////////////////////
// Storage operation types
///////////////////////////

// TODO deprecate
type VSMListOptions struct {
	All bool
}

// This holds request paramters required to list the VSMs.
// The options available in this request will determine the
// operational mode of listing the VSMs.
type VSMListRequest struct {
	All  bool
	Opts []Option
}

// This holds request parameters required to create a VSM.
// TODO deprecate
type VSMCreateOptions struct {
	Name      string
	IP        string
	Interface string
	Subnet    string
	Router    string
	Volume    string
	Storage   string
}

// This holds the request parameters to create a VSM.
// The options available in this request will determine the
// operational mode of creating a VSM.
type VSMCreateRequest struct {
	VsmV2
	Opts []Option
}
