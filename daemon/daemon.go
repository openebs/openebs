// Package daemon exposes the functions that occur on the host server
// that the OpenEBS daemon is running.
//
// In implementing the various functions of the daemon, there is often
// a method-specific struct for configuring the runtime behavior.
package daemon

import (
	"net"
	"os"
	"fmt"
	"syscall"

	"github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/utils"
)

var (
	errSystemNotSupported = fmt.Errorf("The OpenEBS daemon is not supported on this platform.")
)

// Daemon holds information about the OpenEBS daemon.
type Daemon struct {
	ID		string
	configStore	*Config
	shutdown	bool
}

func (daemon *Daemon) restore() error {
	var (
		debug         = utils.IsDebugEnabled()
	)

	if ( !debug) {
		logrus.Info("Restore : start.")
	}

	return nil
}


// NewDaemon sets up everything for the daemon to be able to service
// requests from the webserver.
func NewDaemon(config *Config) (daemon *Daemon, err error) {

	// set up SIGUSR1 handler on Unix-like systems, or a Win32 global event
	// on Windows to dump Go routine stacks
	setupDumpStackTrap()


	d := &Daemon{configStore: config}
	// Ensure the daemon is properly shutdown if there is a failure during
	// initialization
	defer func() {
		if err != nil {
			if err := d.Shutdown(); err != nil {
				logrus.Error(err)
			}
		}
	}()

	if err := d.restore(); err != nil {
		return nil, err
	}

	return d, nil
}

// Shutdown stops the daemon.
func (daemon *Daemon) Shutdown() error {
	daemon.shutdown = true

	return nil
}

func isBrokenPipe(e error) bool {
	if netErr, ok := e.(*net.OpError); ok {
		e = netErr.Err
		if sysErr, ok := netErr.Err.(*os.SyscallError); ok {
			e = sysErr.Err
		}
	}
	return e == syscall.EPIPE
}

// IsShuttingDown tells whether the daemon is shutting down or not
func (daemon *Daemon) IsShuttingDown() bool {
	return daemon.shutdown
}

// Reload reads configuration changes and modifies the
// daemon according to those changes.
// These are the settings that Reload changes:
// - Daemon debug log level.
// 
func (daemon *Daemon) Reload(config *Config) error {
	//var err error
	return nil
}

