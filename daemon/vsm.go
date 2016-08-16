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
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/types"
)

var (
	// directory contains the list of VSMs created via OpenEBS
	vsmsDir = "/etc/openebs/.vsms/"
)

const (
	InvalidLxcInfoOp     = "Error"
	LxcInfoOpState       = "State"
	LxcInfoOpIP          = "IP"
	LxcInfoOpName        = "Name"
	LxcInfoOpInvalidName = "NA"
	LxcInfoOpPID         = "PID"
	LxcInfoOpCPUUse      = "CPU use"
	LxcInfoOpBlkIOUse    = "BlkIO use"
	LxcInfoOpMemoryUse   = "Memory use"
	LxcInfoOpKMemUse     = "KMem use"
	LxcInfoOpLink        = "Link"
	LxcInfoOpTotalBytes  = "Total bytes"
)

type mapper func(dest *types.Vsm, src string)

func parseLxcInfoOpAsKV(rawLxcInfoOp string) (key string, value string) {

	// a valid output will list the details of the LXC
	// in `key: value` format with each `key: value`
	// separated by new lines
	values := strings.Split(rawLxcInfoOp, ":")

	// A very basic parsing validation
	if len(values) < 2 {
		key = InvalidLxcInfoOp
	} else {
		key = strings.TrimSpace(values[0])
		value = strings.TrimSpace(values[1])
	}

	return key, value
}

func mapVsmFromLxcInfo(vsm *types.Vsm, rawLxcInfoOp string) {

	key, val := parseLxcInfoOpAsKV(rawLxcInfoOp)

	switch key {
	case LxcInfoOpState:
		vsm.Status = val
	case LxcInfoOpIP:
		vsm.IPAddress = val
	case LxcInfoOpName:
		vsm.Name = val
	case LxcInfoOpPID, LxcInfoOpCPUUse, LxcInfoOpBlkIOUse, LxcInfoOpMemoryUse, LxcInfoOpKMemUse, LxcInfoOpLink, LxcInfoOpTotalBytes:
		// do nothing
	case InvalidLxcInfoOp:
		vsm.Name = LxcInfoOpInvalidName
		vsm.Status = rawLxcInfoOp
		//fmt.Println("Some error: ", data)
	default:
		vsm.Name = "NA"
		vsm.Status = rawLxcInfoOp
		//fmt.Println("default: ", data)
	}

	// TODO remove these hard codings
	vsm.IOPS = "0"
	vsm.Volumes = "0"
}

func execOsCmd(cmdName string, cmdArgs []string, dest *types.Vsm, mapper mapper) error {

	// prepare the command
	cmd := exec.Command(cmdName, cmdArgs...)

	// capture the std err
	cmd.Stderr = os.Stderr

	// capture the std output
	stdout, err := cmd.StdoutPipe()
	if nil != err {
		return err
	}

	// read the std output
	reader := bufio.NewReader(stdout)
	go func(reader io.Reader, dest *types.Vsm) {
		scanner := bufio.NewScanner(reader)
		for scanner.Scan() {
			mapper(dest, scanner.Text())
			fmt.Println(scanner.Text())
		}
	}(reader, dest)

	// execute the command
	if err := cmd.Start(); nil != err {
		fmt.Println("Error executing: %s, %s", cmd.Path, err.Error())
		return err
	}

	cmd.Wait()

	// no error if logic has reached here
	return nil
}

func vsmDetails(vsmName string) (*types.Vsm, error) {

	// an empty vsm will be passed while
	// a filled up vsm will be received
	vsm := &types.Vsm{}
	cmd := "lxc-info"
	args := []string{"--name=" + vsmName}

	err := execOsCmd(
		cmd,
		args,
		vsm,
		mapVsmFromLxcInfo)

	if nil != err {
		return nil, err
	}

	if strings.TrimSpace(vsm.Status) == "" || strings.TrimSpace(vsm.Name) == "" {
		vsm.Name = vsmName
		vsm.Status = "ERROR"
	}

	return vsm, nil
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
