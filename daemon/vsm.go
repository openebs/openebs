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

func firstOptType(options []types.Option) types.OptionType {

	optionType := types.DefaultOpt

	if nil == options || 0 == len(options) {
		return optionType
	}

	// return the very first option type
	return options[0].Type
}

// A option refers to a filter
func lastOptType(options []types.Option) types.OptionType {

	optionType := types.DefaultOpt

	if nil == options || 0 == len(options) {
		return optionType
	}

	// return the last option type
	return options[len(options)-1].Type
}

func getOptTypes(options []types.Option) []types.OptionType {

	optTypes := []types.OptionType{}

	if nil == options || 0 == len(options) {
		optTypes = append(optTypes, types.NoneOpt)
		return optTypes
	}

	for _, option := range options {
		optTypes = append(optTypes, option.Type)
	}

	return optTypes
}

// Checks if the provided collection has the required type.
func hasOptType(providedOptTypes []types.OptionType, requiredOptType types.OptionType) bool {

	for _, providedOptType := range providedOptTypes {
		if providedOptType == requiredOptType {
			// break out in case of a successful match
			return true
		}
	}

	return false
}

// Checks if the provided collection has all the required types.
// In other words, it checks if the provided collection is a superset of required collection.
func isSuperSetOptTypes(providedOptTypes []types.OptionType, requiredOptTypes ...types.OptionType) bool {

	truthy := true

	for _, requiredOptType := range requiredOptTypes {
		truthy = hasOptType(providedOptTypes, requiredOptType)

		// break out if no match
		if !truthy {
			return truthy
		}
	}

	return truthy
}

// This logic is critical to the functioning of any OpenEBS operation.
// We assume that any OpenEBS operation can have multiple variants/modes of
// execution.
//
// e.g. It may be a vanilla execution or a profiled execution or execution of a
// particular version, etc.
//
// NOTE - Logic will be correct when choice of options are exercized properly.
func inferredOptType(options []types.Option) types.OptionType {

	providedOptTypes := getOptTypes(options)

	// This is the verbose mode.
	// This indicates the combination of all possible modes of an operation.
	// This will be a time taking operation.
	optA := []types.OptionType{types.AllOpt}

	// This mode will profile the execution, collect the
	// possible errors, warnings, etc in addition to executing
	// the given operation.
	optPnE := []types.OptionType{types.ProfileOpt, types.ErrCountOpt}

	// This mode will profile in addition to executing the given operation.
	optPnD := []types.OptionType{types.ProfileOpt, types.DefaultOpt}

	// This mode will collect the possible errors, warnings, etc
	// in addition to executing the given operation.
	optE := []types.OptionType{types.ErrCountOpt}

	// This is same as profile & default mode of operation.
	optP := []types.OptionType{types.ProfileOpt}

	// This mode is the vanilla execution of any operation.
	// This mode is expected to be used often.
	optD := []types.OptionType{types.DefaultOpt}

	// This is the mode when client does not provide any
	// mode of operation.
	optN := []types.OptionType{types.NoneOpt}

	if isSuperSetOptTypes(providedOptTypes, optA...) {
		return types.AllOpt

	} else if isSuperSetOptTypes(providedOptTypes, optPnE...) {
		return types.ProfiledErrOpt

	} else if isSuperSetOptTypes(providedOptTypes, optPnD...) {
		return types.ProfiledDefaultOpt

	} else if isSuperSetOptTypes(providedOptTypes, optE...) {
		return types.ErrCountOpt

	} else if isSuperSetOptTypes(providedOptTypes, optP...) {
		return types.ProfiledDefaultOpt

	} else if isSuperSetOptTypes(providedOptTypes, optD...) {
		return types.DefaultOpt

	} else if isSuperSetOptTypes(providedOptTypes, optN...) {
		return types.NoneOpt

	}

	return types.NoneOpt
}

func setOptToDefaultIfNone(providedOptType types.OptionType) types.OptionType {

	if providedOptType == types.NoneOpt {
		return types.DefaultOpt
	}

	return providedOptType
}

// Check if the option is meant for Create operation
func isValidCreateOption(providedOpt types.OptionType) bool {

	switch providedOpt {
	case types.DefaultOpt, types.ProfileOpt, types.ProfiledDefaultOpt:
		return true
	default:
		return false
	}
}

// This creates a new VSM.
// Version 2
func (daemon *Daemon) VsmCreateV2(opts *types.VSMCreateOptionsV2) (*types.VsmV2, error) {

	// find the appropriate option type for this operation
	inferredOptionType := inferredOptType(opts.Opts)

	// set the option type to default if provided option type is None
	finalOptionType := setOptToDefaultIfNone(inferredOptionType)

	// check if resulting option type is valid w.r.t create operation
	if isValidType := isValidCreateOption(finalOptionType); !isValidType {
		return nil, types.InvalidOptionType
	}

	//
	switch finalOptionType {
	case types.ProfileOpt, types.ProfiledDefaultOpt:
		// execute the operation with profiling
	case types.DefaultOpt:
		// just execute the operation
	default:
		// this is probably un-supported
		return nil, types.UnsupportedOptionType
	}

	return nil, nil
}
