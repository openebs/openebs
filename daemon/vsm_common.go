package daemon

import (
	"bufio"
	"io"
	"os"
	"os/exec"

	log "github.com/Sirupsen/logrus"
	"github.com/openebs/openebs/types"
)

const (
	MAKECMD      = "make"
	MAKEFILEBASE = "/etc/openebs/make/"
	// directory contains the list of VSMs created via OpenEBS
	vsmsDir = "/etc/openebs/.vsms/"
)

type mapper func(dest *types.Vsm, src string)

// This will execute the OS command and fill the received std output
// against the dest passed here. This logic is done via the mapper
// callback function. Caller of this function is expected to pass
// a dest object and an appropriate mapper function.
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
		}
	}(reader, dest)

	// execute the command
	if err := cmd.Start(); nil != err {
		log.WithFields(log.Fields{
			"os_cmd":           cmd.Path,
			"os_cmd_start_err": err.Error(),
		}).Warn("Failed to start the command!")

		return err
	}

	cmd.Wait()

	// no error if logic has reached here
	return nil
}
