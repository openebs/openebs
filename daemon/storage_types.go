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

// This will consist of structures responsible for inner workings of
// OpenEBS storage operations. These structures are categorized into
// input and output options w.r.t a particular storage operation. These
// structures should be common even if the storage backend changes.

// NOTE - A layman explanation of an OpenEBS storage backend is one that
// comprises of an OS container and a filesystem.

package daemon

/////////////////////////
// common storage types
/////////////////////////

type NameID struct {
	name string
	id   string
	desc string
}

type Storage struct {
	size uint64
	iops uint64
}

type Network struct {
	ip     string
	iface  string
	subnet string
	router string
}

type Message struct {
	id    string
	level string
	desc  string
}

type Response struct {
	value  interface{}
	infos  []Message
	errors []Message
	warns  []Message
}

type Vsm struct {
	NameID
	Network
}

type Volume struct {
	NameID
	Storage
}
