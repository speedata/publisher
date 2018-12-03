// +build darwin

package main

// FontFolder returns the name of the system wide font folder
func FontFolder() (string, error) {
	return "/Library/Fonts:/System/Library/Fonts", nil
}
