//go:build linux

package main

import (
	"os/exec"
	"syscall"
)

// setSysProcAttr sets platform-specific process attributes.
// On Linux, this sets Pdeathsig to SIGTERM so the child process
// receives SIGTERM when the parent process dies.
func setSysProcAttr(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Pdeathsig: syscall.SIGTERM,
	}
}
