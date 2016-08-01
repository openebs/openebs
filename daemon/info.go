package daemon

import (
	"runtime"
	"time"

	"github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/version"
	"github.com/openebs/openebs/pkg/parsers/kernel"
	"github.com/openebs/openebs/pkg/parsers/operatingsystem"
	"github.com/openebs/openebs/pkg/platform"
	"github.com/openebs/openebs/pkg/sysinfo"
	"github.com/openebs/openebs/pkg/system"
	"github.com/openebs/openebs/utils"
	"github.com/openebs/openebs/types"
)

// SystemInfo returns information about the host server the daemon is running on.
func (daemon *Daemon) SystemInfo() (*types.Info, error) {
	kernelVersion := "<unknown>"
	if kv, err := kernel.GetKernelVersion(); err != nil {
		logrus.Warnf("Could not get kernel version: %v", err)
	} else {
		kernelVersion = kv.String()
	}

	operatingSystem := "<unknown>"
	if s, err := operatingsystem.GetOperatingSystem(); err != nil {
		logrus.Warnf("Could not get operating system name: %v", err)
	} else {
		operatingSystem = s
	}

	meminfo, err := system.ReadMemInfo()
	if err != nil {
		logrus.Errorf("Could not read system memory info: %v", err)
		meminfo = &system.MemInfo{}
	}

	v := &types.Info{
		ID:                 daemon.ID,
		Debug:              utils.IsDebugEnabled(),
		SystemTime:         time.Now().Format(time.RFC3339Nano),
		KernelVersion:      kernelVersion,
		OperatingSystem:    operatingSystem,
		OSType:             platform.OSType,
		Architecture:       platform.Architecture,
		NCPU:               sysinfo.NumCPU(),
		MemTotal:           meminfo.MemTotal,
		ExperimentalBuild:  utils.ExperimentalBuild(),
		ServerVersion:      version.Version,
	}

	return v, nil
}

// SystemVersion returns version information about the daemon.
func (daemon *Daemon) SystemVersion() types.Version {
	v := types.Version{
		Version:      version.Version,
		GitCommit:    version.GitCommit,
		GoVersion:    runtime.Version(),
		Os:           runtime.GOOS,
		Arch:         runtime.GOARCH,
		BuildTime:    version.BuildTime,
		Experimental: utils.ExperimentalBuild(),
	}

	kernelVersion := "<unknown>"
	if kv, err := kernel.GetKernelVersion(); err != nil {
		logrus.Warnf("Could not get kernel version: %v", err)
	} else {
		kernelVersion = kv.String()
	}
	v.KernelVersion = kernelVersion

	return v
}
