package system

import (
	"github.com/openebs/openebs/api/server/router"
)

// systemRouter provides information about the openebs system overall.
// It gathers system information.
type systemRouter struct {
	backend         Backend
	routes          []router.Route
}

// NewRouter initializes a new system router
func NewRouter(b Backend) router.Router {
	r := &systemRouter{
		backend:         b,
	}

	r.routes = []router.Route{
		router.NewOptionsRoute("/{anyroute:.*}", optionsHandler),
		router.NewGetRoute("/info", r.getInfo),
		router.NewGetRoute("/version", r.getVersion),
	}

	return r
}

// Routes returns all the API routes dedicated to the openebs system
func (s *systemRouter) Routes() []router.Route {
	return s.routes
}
