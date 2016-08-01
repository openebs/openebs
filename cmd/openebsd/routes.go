// +build !experimental

package main

import "github.com/openebs/openebs/api/server/router"

func addExperimentalRouters(routers []router.Router) []router.Router {
	return routers
}
