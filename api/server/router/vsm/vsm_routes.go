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

// This is responsible for implementing the http handlers
// w.r.t VSM. The function names start with <<http-verb>> prefix.
package vsm

import (
	"net/http"

	"github.com/openebs/openebs/api/server/httputils"
	"github.com/openebs/openebs/types"
	"golang.org/x/net/context"
)

// This will return a list of VSMs in JSON format
func (s *vsmRouter) getVsmLsJSON(ctx context.Context, w http.ResponseWriter, r *http.Request, vars map[string]string) error {
	if err := httputils.ParseForm(r); err != nil {
		return err
	}

	config := &types.VSMListOptions{
		All: httputils.BoolValue(r, "all"),
	}

	vsms, err := s.backend.Vsms(config)
	if err != nil {
		return err
	}

	return httputils.WriteJSON(w, http.StatusOK, vsms)
}

// This will create a VSM
func (s *vsmRouter) postVsmCreate(ctx context.Context, w http.ResponseWriter, r *http.Request, vars map[string]string) error {
	if err := httputils.ParseForm(r); err != nil {
		return err
	}

	//if err := httputils.CheckForJSON(r); err != nil {
	//	return err
	//}

	name := r.Form.Get("name")
	ip := r.Form.Get("ip")
	ninterface := r.Form.Get("interface")
	subnet := r.Form.Get("subnet")
	router := r.Form.Get("router")
	volume := r.Form.Get("volume")
	storage := r.Form.Get("storage")

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

//func (s *containerRouter) deleteContainers(ctx context.Context, w http.ResponseWriter, r *http.Request, vars map[string]string) error {
//	if err := httputils.ParseForm(r); err != nil {
//		return err
//	}
//
//	name := vars["name"]
//	config := &types.ContainerRmConfig{
//		ForceRemove:  httputils.BoolValue(r, "force"),
//		RemoveVolume: httputils.BoolValue(r, "v"),
//		RemoveLink:   httputils.BoolValue(r, "link"),
//	}
//
//	if err := s.backend.ContainerRm(name, config); err != nil {
//		// Force a 404 for the empty string
//		if strings.Contains(strings.ToLower(err.Error()), "prefix can't be empty") {
//			return fmt.Errorf("no such container: \"\"")
//		}
//		return err
//	}
//
//	w.WriteHeader(http.StatusNoContent)
//
//	return nil
//}
