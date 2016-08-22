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
	IopsOpt     OptionType = "iops"
	SizeOpt     OptionType = "size"
	UsageOpt    OptionType = "usage"
	NoneOpt     OptionType = "none"
	DefaultOpt  OptionType = "default"
	ErrCountOpt OptionType = "errorcount"
	// Verbose mode
	AllOpt     OptionType = "all"
	ProfileOpt OptionType = "profile"

	// Derived options based on combinations of above types
	ProfiledDefaultOpt OptionType = "pdefault"
	ProfiledErrOpt     OptionType = "perrors"
	ProfiledAllOpt     OptionType = "pall"

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

func GetOptTypes(options []Option) []OptionType {

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
func HasOptType(providedOptTypes []OptionType, requiredOptType OptionType) bool {

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
func IsSuperSetOptTypes(providedOptTypes []OptionType, requiredOptTypes ...OptionType) bool {

	truthy := true

	for _, requiredOptType := range requiredOptTypes {
		truthy = HasOptType(providedOptTypes, requiredOptType)

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
// TODO - Re-factor to a fitting structural pattern !!!
func InferredOptType(options []Option) OptionType {

	providedOptTypes := GetOptTypes(options)

	// This is the verbose mode.
	// This indicates the combination of all possible modes of an operation.
	// This will be a time taking operation.
	optA := []OptionType{AllOpt}

	// This mode will profile the execution, collect the
	// possible errors, warnings, etc in addition to executing
	// the given operation.
	optPnE := []OptionType{ProfileOpt, ErrCountOpt}

	// This mode will profile in addition to executing the given operation.
	optPnD := []OptionType{ProfileOpt, DefaultOpt}

	// This mode will collect the possible errors, warnings, etc
	// in addition to executing the given operation.
	optE := []OptionType{ErrCountOpt}

	// This is same as profile & default mode of operation.
	optP := []OptionType{ProfileOpt}

	// This mode is the vanilla execution of any operation.
	// This mode is expected to be used often.
	optD := []OptionType{DefaultOpt}

	// This is the mode when client does not provide any
	// mode of operation.
	optN := []OptionType{NoneOpt}

	if IsSuperSetOptTypes(providedOptTypes, optA...) {
		return AllOpt

	} else if IsSuperSetOptTypes(providedOptTypes, optPnE...) {
		return ProfiledErrOpt

	} else if IsSuperSetOptTypes(providedOptTypes, optPnD...) {
		return ProfiledDefaultOpt

	} else if IsSuperSetOptTypes(providedOptTypes, optE...) {
		return ErrCountOpt

	} else if IsSuperSetOptTypes(providedOptTypes, optP...) {
		return ProfiledDefaultOpt

	} else if IsSuperSetOptTypes(providedOptTypes, optD...) {
		return DefaultOpt

	} else if IsSuperSetOptTypes(providedOptTypes, optN...) {
		return NoneOpt

	}

	return NoneOpt
}

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

// Version 2
// This holds request paramters required to list the VSMs.
// This will determine the variation w.r.t listing the VSMs.
type VSMListOptionsV2 struct {
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

// Version 2
// This holds the request parameters to create a VSM.
// This will determine the variations required w.r.t creating a VSM.
type VSMCreateOptionsV2 struct {
	VsmV2
	Opts []Option
}
