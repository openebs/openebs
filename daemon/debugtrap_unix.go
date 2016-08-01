// +build !windows

package daemon

import (
	"os"
	"os/signal"
	"syscall"

	psignal "github.com/openebs/openebs/pkg/signal"
)

func setupDumpStackTrap() {
	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGUSR1)
	go func() {
		for range c {
			psignal.DumpStacks()
		}
	}()
}
