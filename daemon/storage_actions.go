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

// This will consist of signatures of the actions related to OpenEBS storage.
// In programming design patterns' terminology, this file will expose behaviors
// as interfaces, also known as contracts in some programming languages.

package daemon

/////////////////////////////////////
// Individual storage actions
/////////////////////////////////////

type Timer interface {
	Time() (err error)
}

type Profiler interface {
	Start() (err error)
	Stop() (err error)
}

type Creator interface {
	Create() (resp Response, err error)
}

type Reader interface {
	Read() (resp Response, err error)
}

type Updater interface {
	Update() (resp Response, err error)
}

type Destroyer interface {
	Destroy() (resp Response, err error)
}

/////////////////////////////////////
// Composable storage actions
/////////////////////////////////////

type StatisticsReader interface {
	Stats(r Reader) (err error)
}

type Lister interface {
	List(rdrs []Reader) (err error)
}

type StatisticsLister interface {
	List(sr []StatisticsReader) (err error)
}

type CreateReader interface {
	Creator
	Reader
}

type CreateReadProfiler interface {
	CreateReader
	Profiler
}

type CreateUpdateReader interface {
	Creator
	Updater
	Reader
}

type CreateUpdateReadProfiler interface {
	CreateUpdateReader
	Profiler
}

type RangeLister struct {
	Lister
	Begin int
	End   int
}
