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
	"fmt"
	"os"
	"os/exec"
	"github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/types"
)

// Vsms returns the list of VSMs to show given the user's filtering.
func (daemon *Daemon) Vsms(config *types.VSMListOptions) ([]*types.Vsm, error) {
	vsms := []*types.Vsm{}

	//TODO - Fetch this data from a registry
	for i := 1; i < 2; i++ {
		vsm := &types.Vsm {
			Name:		"vsm",
			IPAddress:	"10.10.1.1",
			IOPS:		"100",
			Volumes:	"1",
			Status:		"active",
		}
		vsms = append(vsms, vsm)
	}

	logrus.Debugf("Total VSMs %d\n", len(vsms))
	return vsms, nil
}

// This returns the newly created VSM.
func (daemon *Daemon) VsmCreate(opts *types.VSMCreateOptions) (*types.Vsm, error) {

	fmt.Printf("VSM Create at server ...\n")
	fmt.Printf("Provided ip: %s\n", opts.IP)
	fmt.Printf("Provided vsm name: %s\n", opts.Name)
	fmt.Printf("Provided iface: %s\n", opts.Interface)
	fmt.Printf("Provided subnet: %s\n", opts.Subnet)
	fmt.Printf("Provided router: %s\n", opts.Router)
	fmt.Printf("Provided volume name: %s\n", opts.Volume)

	name := opts.Name
	ip := opts.IP
	netface := opts.Interface
	subnet := opts.Subnet
	router := opts.Router
	volume := opts.Volume

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
		"debug=1"}

	// Preparing the final command
	finalcmd := exec.Command(MAKECMD, args...)

	PrintCommand(finalcmd)

	// We want to see what's going on
	finalcmd.Stdout = os.Stdout
	finalcmd.Stderr = os.Stderr

	// Actual execution
	err := finalcmd.Run()
	if err != nil {
		return nil, err
	}

	vsm := &types.Vsm{
		Name: name,
		IPAddress: netface,
		IOPS: "0",
		Volumes: "1",
		Status: "Active",
	}

	return vsm, err
}
