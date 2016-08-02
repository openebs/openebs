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
	"net/http"

	"github.com/openebs/openebs/api/server/httputils"
	"github.com/openebs/openebs/types"
	"golang.org/x/net/context"
)

func (s *vsmRouter) getVsmsJSON(ctx context.Context, w http.ResponseWriter, r *http.Request, vars map[string]string) error {
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

//func (s *containerRouter) postContainersCreate(ctx context.Context, w http.ResponseWriter, r *http.Request, vars map[string]string) error {
//	if err := httputils.ParseForm(r); err != nil {
//		return err
//	}
//	if err := httputils.CheckForJSON(r); err != nil {
//		return err
//	}
//
//	name := r.Form.Get("name")
//
//	config, hostConfig, networkingConfig, err := s.decoder.DecodeConfig(r.Body)
//	if err != nil {
//		return err
//	}
//	version := httputils.VersionFromContext(ctx)
//	adjustCPUShares := versions.LessThan(version, "1.19")
//
//	validateHostname := versions.GreaterThanOrEqualTo(version, "1.24")
//	ccr, err := s.backend.ContainerCreate(types.ContainerCreateConfig{
//		Name:             name,
//		Config:           config,
//		HostConfig:       hostConfig,
//		NetworkingConfig: networkingConfig,
//		AdjustCPUShares:  adjustCPUShares,
//	}, validateHostname)
//	if err != nil {
//		return err
//	}
//
//	return httputils.WriteJSON(w, http.StatusCreated, ccr)
//}
//
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
