//go:build windows

// See http://stackoverflow.com/a/17953976/

package main

import (
	"fmt"

	"github.com/inconshreveable/mousetrap"
	"golang.org/x/sys/windows"
)

func FontFolder() (string, error) {
	return windows.KnownFolderPath(windows.FOLDERID_Fonts, 0)

}

func CheckWindowsGUIDoubleClick() {
	if mousetrap.StartedByExplorer() {
		fmt.Println("This program is a command-line tool.")
		fmt.Println("Please run it from Command Prompt or PowerShell.")
		fmt.Println("Press Enter to exit...")
		fmt.Scanln()
		return
	}
}
