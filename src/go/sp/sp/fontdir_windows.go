//go:build windows

// See http://stackoverflow.com/a/17953976/

package main

import (
	"golang.org/x/sys/windows"
)

func FontFolder() (string, error) {
	return windows.KnownFolderPath(windows.FOLDERID_Fonts, 0)

}
