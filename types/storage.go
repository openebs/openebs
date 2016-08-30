// Copyright 2016 CloudByte, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package types

import "time"

// This will have the common stuctures w.r.t Open EBS storage

// A very generic type that can be used for any value
type OEBSValue interface{}

// A type that may be used to represent a particular storage
// component.
type OEBSComponent interface{}

// A type that may be used to represent a error or warning
// or anything that has to do with level.
type OEBSLevel interface{}

// A type that will be used to represent a ID value.
type OEBSId interface{}

// An option or a combination of these options determine
// the orthogonal execution of any storage operation.
// e.g. These will ensure executing the vanilla operation
// or a variation of the same operation.
type OptionType string

// Various options that may be exercised during
// a request against a particular operation.
const (

	// Possible range options
	// This indicates a range i.e. a min value & a max value
	// e.g. a listing operation that prefers to filter the list
	// by the range of IOPS.
	RangeIopsOpt  OptionType = "iops-range"
	RangeSizeOpt  OptionType = "size-range"
	RangeUsageOpt OptionType = "usage-range"
	// To list entities that have `n` no of issues, etc
	RangeIssuesOpt OptionType = "issues-range"

	// If no option was exercised during a storage operation
	NoneOpt    OptionType = "none"
	DefaultOpt OptionType = "default"

	// If it is desired to record the timing of each inidividual tasks
	// of a storage operation and export the data to some external tool.
	TimingOpt OptionType = "timing"

	// If it is desired to audit the storage operation and export to
	// some external tool.
	AuditOpt OptionType = "audit"

	// Not sure if this is the right place !!
	VersionOpt OptionType = "version"
)

// An option can be value based or range based.
type Option struct {
	Type  OptionType
	Truth bool
	Val   OEBSValue
	Min   uint64
	Max   uint64
}

// A generic structure to contain Name, Id fields.
type NameID struct {
	Name string
	Id   OEBSId
	Desc string
}

// A typical storage structure
type Storage struct {
	Size uint64
	Used uint64
	Iops uint64
}

// A typical network structure
type Network struct {
	Ip     string
	Iface  string
	Subnet string
	Router string
}

// A mesage structure that will help the clients
type Message struct {
	Id    OEBSId
	Level OEBSLevel
	Val   OEBSValue
	From  OEBSComponent
	Date  time.Time
}

type Response struct {
	Val    OEBSValue
	Date   time.Time
	Infos  []Message
	Errors []Message
	Warns  []Message
}

// Merges source response to destination response
func (dr *Response) Merge(sr *Response) {
	if sr == nil {
		return
	}

	if sr.Errors != nil {
		if dr.Errors != nil {
			dr.Errors = append(dr.Errors, sr.Errors...)
		} else {
			dr.Errors = sr.Errors
		}
	}

	if sr.Infos != nil {
		if dr.Infos != nil {
			dr.Infos = append(dr.Infos, sr.Infos...)
		} else {
			dr.Infos = sr.Infos
		}
	}

	if sr.Warns != nil {
		if dr.Warns != nil {
			dr.Warns = append(dr.Warns, sr.Warns...)
		} else {
			dr.Warns = sr.Warns
		}
	}

	if sr.Val != nil {
		msg := Message{
			Val:  sr.Val,
			Date: sr.Date,
		}

		if dr.Infos != nil {
			dr.Infos = append(dr.Infos, msg)
		} else {
			dr.Infos = []Message{
				msg,
			}
		}
	}
}

type VsmType struct {
	NameID      *NameID
	Network     *Network
	VolumeCount uint64
}

type VolumeType struct {
	NameID  *NameID
	Storage *Storage
}

// This holds request parameters required to list the VSMs.
// The options available in this request will determine the
// operational mode of listing the VSMs.
type VSMListRequest struct {
	All  bool
	Opts []Option
}

// This holds the request parameters to create a VSM.
// The options available in this request will determine the
// operational mode of creating a VSM.
type VSMCreateRequest struct {
	Vsm  *VsmType
	Opts []Option
}
