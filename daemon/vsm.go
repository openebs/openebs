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
	"bufio"
	"fmt"
	"github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/types"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

var (
	// directory contains the list of VSMs created via OpenEBS
	vsmsDir = "/etc/openebs/.vsms/"
)

func fillVsmType(vsm *types.Vsm, data string) {

	values := strings.Split(data, ":")

	var key, val string
	if len(values) < 2 {
		key = "Error"
	} else {
		key = strings.TrimSpace(values[0])
		val = strings.TrimSpace(values[1])
	}

	switch key {
	case "State":
		vsm.Status = val
	case "IP":
		vsm.IPAddress = val
	case "Name":
		vsm.Name = val
	case "PID", "CPU use", "BlkIO use", "Memory use", "KMem use", "Link", "Total bytes":
		// do nothing
	case "Error":
		vsm.Name = "NA"
		vsm.Status = data
		fmt.Println("Some error: ", data)
	default:
		vsm.Name = "NA"
		vsm.Status = data
		fmt.Println("default: ", data)
	}

	// TODO remove these hard codings
	vsm.IOPS = "100"
	vsm.Volumes = "1"
}

func vsmDetails(vsmname string) (*types.Vsm, error) {

	// Preparing the arguments
	args := []string{"--name=" + vsmname}

	// Preparing the command
	cmd := exec.Command("lxc-info", args...)

	PrintCommand(cmd)

	cmd.Stderr = os.Stderr

	stdout, err := cmd.StdoutPipe()
	if nil != err {
		return nil, err
	}

	vsm := types.Vsm{}
	reader := bufio.NewReader(stdout)

	go func(reader io.Reader, vsm *types.Vsm) {
		scanner := bufio.NewScanner(reader)
		for scanner.Scan() {
			fillVsmType(vsm, scanner.Text())
			fmt.Println(scanner.Text())
		}
	}(reader, &vsm)

	if err := cmd.Start(); nil != err {
		fmt.Println("Error starting program: %s, %s", cmd.Path, err.Error())
		return nil, err
	}

	cmd.Wait()

	if strings.TrimSpace(vsm.Status) == "" || strings.TrimSpace(vsm.Name) == "" {
		vsm.Name = vsmname
		vsm.Status = "ERROR"
	}

	return &vsm, nil
}

// Vsms returns the list of VSMs to show given the user's filtering.
func (daemon *Daemon) Vsms(config *types.VSMListOptions) ([]*types.Vsm, error) {
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

		//vsm := &types.Vsm{
		//	Name:      fileInfo.Name(),
		//	IPAddress: "10.10.1.1",
		//	IOPS:      "100",
		//	Volumes:   "1",
		//	Status:    "active",
		//}
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

// This returns the newly created VSM.
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
		Name:      name,
		IPAddress: netface,
		IOPS:      "0",
		Volumes:   "1",
		Status:    "Active",
	}

	return vsm, err
}
