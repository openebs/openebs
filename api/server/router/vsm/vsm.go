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
	"github.com/openebs/openebs/api/server/router"
)

type validationError struct {
	error
}

func (validationError) IsValidationError() bool {
	return true
}

// vsmRouter is a router to talk with the VSMs 
type vsmRouter struct {
	backend Backend
	routes  []router.Route
}

// NewRouter initializes a new vsm router
func NewRouter(b Backend) router.Router {
	r := &vsmRouter{
		backend: b,
	}
	r.initRoutes()
	return r
}

// Routes returns the available routes to the vsm controller
func (r *vsmRouter) Routes() []router.Route {
	return r.routes
}

// initRoutes initializes the routes in vsm router
func (r *vsmRouter) initRoutes() {
	r.routes = []router.Route{
		// HEAD
		//router.NewHeadRoute("/containers/{name:.*}/archive", r.headContainersArchive),
		// GET
		router.NewGetRoute("/vsm/json", r.getVsmsJSON),
		// POST
		//router.NewPostRoute("/containers/create", r.postContainersCreate),
		// PUT
		//router.NewPutRoute("/containers/{name:.*}/archive", r.putContainersArchive),
		// DELETE
		//router.NewDeleteRoute("/containers/{name:.*}", r.deleteContainers),
	}
}
