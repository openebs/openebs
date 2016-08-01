// +build linux freebsd

package daemon

import (
	"os"
	"fmt"

	"github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/pkg/parsers/kernel"
)

const (
	platformSupported = true
)

func checkKernelVersion(k, major, minor int) bool {
        if v, err := kernel.GetKernelVersion(); err != nil {
                logrus.Warnf("error getting kernel version: %s", err)
        } else {
                if kernel.CompareKernelVersion(*v, kernel.VersionInfo{Kernel: k, Major: major, Minor: minor}) < 0 {
                        return false
                }
        }
        return true
}


func checkKernel() error {
	// Check for unsupported kernel versions
	// FIXME: it would be cleaner to not test for specific versions, but rather
	// test for specific functionalities.
	// Unfortunately we can't test for the feature "does not cause a kernel panic"
	// without actually causing a kernel panic, so we need this workaround until
	// the circumstances of pre-3.10 crashes are clearer.
	// For details see https://github.com/docker/docker/issues/407
	// https://github.com/docker 1.11 and above doesn't actually run on kernels older than 3.4,
	// due to containerd-shim usage of PR_SET_CHILD_SUBREAPER (introduced in 3.4).
	if !checkKernelVersion(3, 10, 0) {
		v, _ := kernel.GetKernelVersion()
		if os.Getenv("OPENEBS_NOWARN_KERNEL_VERSION") == "" {
			logrus.Fatalf("Your Linux kernel version %s is not supported for running OpenEBS. Please upgrade your kernel to 3.10.0 or newer.", v.String())
		}
	}
	return nil
}

// checkSystem validates platform-specific requirements
func checkSystem() error {
	if os.Geteuid() != 0 {
		return fmt.Errorf("The OpenEBS daemon needs to be run as root")
	}
	return checkKernel()
}


// setupDaemonProcess sets various settings for the daemon's process
func setupDaemonProcess(config *Config) error {
	// setup the daemons oom_score_adj
	return nil
}

