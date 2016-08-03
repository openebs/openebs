package daemon

import (
	"fmt"
	"os/exec"
	"strings"
)

const (
	MAKECMD      = "make"
	MAKEFILEBASE = "/etc/openebs/make/"
)

func PrintCommand(cmd *exec.Cmd) {
	fmt.Printf("Executing: %s\n", strings.Join(cmd.Args, " "))
}
