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

package vsm

import (
	"github.com/openebs/openebs/types"
)


// stateBackend includes functions to implement to provide container state lifecycle functionality.
//type stateBackend interface {
//	ContainerCreate(config types.ContainerCreateConfig, validateHostname bool) (types.ContainerCreateResponse, error)
//}

// monitorBackend includes functions to implement to provide containers monitoring functionality.
type monitorBackend interface {
	Vsms(config *types.VSMListOptions) ([]*types.Vsm, error)
}

// Backend is all the methods that need to be implemented to provide VSM specific functionality.
type Backend interface {
//	stateBackend
	monitorBackend
}
