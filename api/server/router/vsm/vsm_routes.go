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

// This is responsible for implementing the router handlers
// (esp. http handlers) w.r.t VSM. The function names start with <<http-verb>>
// prefix. Logic implemented here should be simple invocations to server
// side logic.
package vsm

import (
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/openebs/openebs/api/server/httputils"
	"github.com/openebs/openebs/types"
	"golang.org/x/net/context"
)

// A router handler
func (s *vsmRouter) getVsmList(ctx context.Context, w http.ResponseWriter, r *http.Request, vars map[string]string) error {
	if err := httputils.ParseForm(r); err != nil {
		return err
	}

	config := &types.VSMListOptions{
		All: httputils.BoolValue(r, "all"),
	}

	// Actual call to the backend i.e. server side logic.
	// A backend is configured as a server/daemon.
	vsms, err := s.backend.VsmList(config)
	if err != nil {
		return err
	}

	return httputils.WriteJSON(w, http.StatusOK, vsms)
}

// A router handler
func (s *vsmRouter) postVsmCreate(ctx context.Context, w http.ResponseWriter, r *http.Request, vars map[string]string) error {
	if err := httputils.ParseForm(r); err != nil {
		return err
	}

	name := r.Form.Get("name")
	ip := r.Form.Get("ip")
	ninterface := r.Form.Get("interface")
	subnet := r.Form.Get("subnet")
	router := r.Form.Get("router")
	volume := r.Form.Get("volume")
	storage := r.Form.Get("storage")

	// Actual call to the backend i.e. server side logic.
	// A backend is configured as a server/daemon.
	vsmcr, err := s.backend.VsmCreate(&types.VSMCreateOptions{
		Name:      name,
		IP:        ip,
		Interface: ninterface,
		Subnet:    subnet,
		Router:    router,
		Volume:    volume,
		Storage:   storage,
	})
	if err != nil {
		return err
	}

	return httputils.WriteJSON(w, http.StatusCreated, vsmcr)
}

// A router handler
func (s *vsmRouter) postVsmCreateV2(ctx context.Context, w http.ResponseWriter, r *http.Request, vars map[string]string) error {

	if nil == r {
		return errors.New("Nil http request provided.")
	}

	if err := httputils.ParseForm(r); err != nil {
		return err
	}

	vsm := &types.VsmType{
		NameID: &types.NameID{
			Name: r.Form.Get("name"),
			Id:   r.Form.Get("name") + strconv.FormatInt(time.Now().UnixNano(), 10),
		},
	}

	opts := []types.Option{}

	// Actual call to the backend i.e. server side logic.
	// A backend of OpenEBS is the logic in daemon package.
	sres, err := s.backend.VsmCreateV2(vsm, opts)

	if err != nil {
		return err
	}

	return httputils.WriteJSON(w, http.StatusCreated, sres)
}
