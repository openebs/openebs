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
	"strings"

	log "github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/types"
)

const (
	// commands
	LxcInfoCmd = "lxc-info"

	// keys i.e. headers for lxc info's output
	LxcInfoOpInvalidKey  = "Error"
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

	// generic values
	ErrMsg = "ERROR"
)

func parseLxcInfoOpAsKV(rawLxcInfoOp string) (key string, value string) {

	// a valid output will list the details of the LXC
	// in `key: value` format with each `key: value`
	// separated by new lines
	values := strings.Split(rawLxcInfoOp, ":")

	// A very basic parsing validation
	if len(values) < 2 {
		key = LxcInfoOpInvalidKey

		log.WithFields(log.Fields{
			"raw_lxc_info_op": rawLxcInfoOp,
		}).Warn("Unexpected lxc info!")
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
	case LxcInfoOpInvalidKey:
		vsm.Name = LxcInfoOpInvalidName
		vsm.Status = rawLxcInfoOp
	default:
		vsm.Name = LxcInfoOpInvalidName
		vsm.Status = rawLxcInfoOp
	}

	// TODO remove these hard codings
	vsm.IOPS = "0"
	vsm.Volumes = "0"
}

func vsmDetails(vsmName string) (*types.Vsm, error) {

	// an empty vsm will be passed while
	// a filled up vsm will be received
	vsm := &types.Vsm{}
	cmd := LxcInfoCmd
	args := []string{"--name=" + vsmName}

	err := execOsCmd(
		cmd,
		args,
		vsm,
		mapVsmFromLxcInfo)

	if nil != err {
		return nil, err
	}

	// A very primitive error handling for cases when the std output
	// provides unexpected stuff that is not handled in parsing.
	// Looking from a different angle, we expect `Name` and `Status`
	// to be filled up after execution of above logic. In case it does not
	// then below is a crude error handling as it does not know the root cause.
	if strings.TrimSpace(vsm.Status) == "" || strings.TrimSpace(vsm.Name) == "" {
		vsm.Name = vsmName
		vsm.Status = ErrMsg
	}

	return vsm, nil
}
