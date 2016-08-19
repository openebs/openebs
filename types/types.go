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

type FilterID string

// Various filters that will be used as options
// during request against a particular operation.
const (
	Iops    FilterID = "iops"
	Size    FilterID = "size"
	Usage   FilterID = "usage"
	None    FilterID = "none"
	Default FilterID = "default"
	Err     FilterID = "errors"
	All     FilterID = "all"
	Profile FilterID = "profile"
)

// A filter can be value based or range based.
type OpsFilter struct {
	Id    FilterID
	Truth bool
	Val   string
	Min   uint64
	Max   uint64
}

type Opts struct {
	Filters []OpsFilter
}

// TODO deprecate
type VSMListOptions struct {
	All bool
}

// Version 2
// This holds request paramters required to list the VSMs.
// This will determine the variation w.r.t listing the VSMs.
type VSMListOptionsV2 struct {
	Opts
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
	Opts
}
