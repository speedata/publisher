// +build darwin

package main

func FontFolder() (string, error) {
	return "/Library/Fonts:/System/Library/Fonts", nil
}
