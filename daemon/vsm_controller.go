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

package daemon

import "github.com/openebs/openebs/types"

// This implements the logic to create an OpenEBS VSM.
// This is a concrete i.e. a specific executor implementation.
func VsmCreator(vsm *types.VsmType) Executor {
	return ExecutorFn(func() (resp *types.Response, err error) {

		resp = &types.Response{
			Val: "Received VSM with name: " + vsm.NameID.Name,
		}

		return resp, nil
	})
}
