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
// common storage types
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

// Various options whose combinations will determine
// the storage operation. These will play a crucial
// role in executing the vanilla operation
// or a variation of the operation.

type OptionType string

// Various options that may be exercised during
// a request against a particular operation.
const (
	// Pure types
	IopsOpt     OptionType = "iops"
	SizeOpt     OptionType = "size"
	UsageOpt    OptionType = "usage"
	NoneOpt     OptionType = "none"
	DefaultOpt  OptionType = "default"
	ErrCountOpt OptionType = "errorcount"
	// Verbose mode
	AllOpt     OptionType = "all"
	ProfileOpt OptionType = "profile"

	// Derived types based on combinations of above types
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
