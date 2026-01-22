//go:build !linux && !freebsd

package main

import "os/exec"

// setSysProcAttr sets platform-specific process attributes.
// On platforms without Pdeathsig support (macOS, Windows),
// this is a no-op. Child process cleanup is handled by
// exitProgram() and sigIntCatcher().
func setSysProcAttr(cmd *exec.Cmd) {
	// No Pdeathsig support on this platform
}
