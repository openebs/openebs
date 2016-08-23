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

import (
	"os"
	"os/exec"
	"path/filepath"

	"github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/types"
)

// This returns the list of VSMs.
func (daemon *Daemon) VsmList(config *types.VSMListOptions) ([]*types.Vsm, error) {
	vsms := []*types.Vsm{}

	err := filepath.Walk(vsmsDir, func(d string, fileInfo os.FileInfo, err error) error {
		if err != nil {
			if os.IsNotExist(err) && d != vsmsDir {
				return nil
			}
			return err
		}
		if fileInfo == nil || fileInfo.IsDir() {
			return nil
		}
		logrus.Debugf("Found VSM %s\n", fileInfo.Name())

		vsm, err := vsmDetails(fileInfo.Name())
		if err != nil {
			return err
		}

		vsms = append(vsms, vsm)

		return nil
	})

	if err != nil {
		logrus.Errorf("Unable to fetch VSMs from %s\n", vsmsDir)
		return vsms, err
	}

	logrus.Debugf("Total VSMs %d\n", len(vsms))
	return vsms, nil
}

// This creates a new VSM.
func (daemon *Daemon) VsmCreate(opts *types.VSMCreateOptions) (*types.Vsm, error) {

	name := opts.Name
	ip := opts.IP
	netface := opts.Interface
	subnet := opts.Subnet
	router := opts.Router
	volume := opts.Volume
	storage := opts.Storage

	// This is make based !!!
	// Base path of Makefile
	makefilename := MAKEFILEBASE + "vsm_create"

	// Subcommand i.e. makefile's target name
	subcommand := "create"

	// Non-silent mode to execute make commands
	makeopts := "-sf"

	// Preparing the arguments
	args := []string{makeopts, makefilename,
		subcommand,
		"name=" + name,
		"interface=" + netface,
		"ip=" + ip,
		"subnet=" + subnet,
		"volume=" + volume,
		"router=" + router,
		"storage=" + storage,
		"debug=1"}

	// Preparing the final command
	finalcmd := exec.Command(MAKECMD, args...)

	// We want to see what's going on
	finalcmd.Stdout = os.Stdout
	finalcmd.Stderr = os.Stderr

	// Actual execution
	err := finalcmd.Run()
	if err != nil {
		return nil, err
	}

	vsm := &types.Vsm{
		Name:      name,
		IPAddress: netface,
		IOPS:      "0",
		Volumes:   "1",
		Status:    "Active",
	}

	return vsm, err
}

// This creates a new VSM.
func (daemon *Daemon) VsmCreateV2(req *types.VSMCreateRequest) (*types.VsmV2, error) {

	// find the appropriate option type for this operation
	inferredOptionType := types.InferredOptType(req.Opts)

	// set the option type to default if provided option type is None
	finalOptionType := types.SetOptToDefaultIfNone(inferredOptionType)

	CreateVsm(req.Vsm, finalOptionType)

	return nil, nil
}
