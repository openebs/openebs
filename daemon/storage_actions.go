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

// This will consist of common signatures of actions w.r.t OpenEBS storage.
// In programming design patterns' terminology, this file will expose behaviors
// as interfaces, also known as contracts in some programming languages.

package daemon

/////////////////////////////////////
// Individual common storage actions
/////////////////////////////////////

type Timer interface {
	Time() (err error)
}

type Profiler interface {
	Start() (err error)
	Stop() (err error)
}

//////////////////////////
// Individual VSM actions
//////////////////////////

type VsmCreator interface {
	Create() (err error)
}

type VsmReader interface {
	Read() (err error)
}

type VsmUpdater interface {
	Update() (err error)
}

type VsmDestroyer interface {
	Destroy() (err error)
}

//////////////////////////
// Composable VSM actions
//////////////////////////

type VsmStatisticsReader interface {
	Stats(r VsmReader) (err error)
}

type VsmLister interface {
	List(rdrs []VsmReader) (err error)
}

type VsmStatisticsLister interface {
	List(sr []VsmStatisticsReader) (err error)
}

type VsmCreateReader interface {
	VsmCreator
	VsmReader
}

type VsmCreateReadProfiler interface {
	VsmCreateReader
	Profiler
}

type VsmCreateUpdateReader interface {
	VsmCreator
	VsmUpdater
	VsmReader
}

type VsmCreateUpdateReadProfiler interface {
	VsmCreateUpdateReader
	Profiler
}

type VsmRangeLister struct {
	VsmLister
	Begin int
	End   int
}
