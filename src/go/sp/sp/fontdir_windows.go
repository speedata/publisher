// +build windows

// See http://stackoverflow.com/a/17953976/

package main

import (
	"syscall"
	"unsafe"
)

type GUID struct {
	Data1 uint32
	Data2 uint16
	Data3 uint16
	Data4 [8]byte
}

var (
	FOLDERID_Fonts = GUID{0xFD228CB7, 0xAE11, 0x4AE3, [8]byte{0x86, 0x4C, 0x16, 0xF3, 0x91, 0x0A, 0xB8, 0xFE}}
)

var (
	modShell32               = syscall.NewLazyDLL("Shell32.dll")
	modOle32                 = syscall.NewLazyDLL("Ole32.dll")
	procSHGetKnownFolderPath = modShell32.NewProc("SHGetKnownFolderPath")
	procCoTaskMemFree        = modOle32.NewProc("CoTaskMemFree")
)

func SHGetKnownFolderPath(rfid *GUID, dwFlags uint32, hToken syscall.Handle, pszPath *uintptr) (retval error) {
	r0, _, _ := syscall.Syscall6(procSHGetKnownFolderPath.Addr(), 4, uintptr(unsafe.Pointer(rfid)), uintptr(dwFlags), uintptr(hToken), uintptr(unsafe.Pointer(pszPath)), 0, 0)
	if r0 != 0 {
		retval = syscall.Errno(r0)
	}
	return
}

func CoTaskMemFree(pv uintptr) {
	syscall.Syscall(procCoTaskMemFree.Addr(), 1, uintptr(pv), 0, 0)
	return
}

func FontFolder() (string, error) {
	var path uintptr
	err := SHGetKnownFolderPath(&FOLDERID_Fonts, 0, 0, &path)
	if err != nil {
		return "", err
	}
	defer CoTaskMemFree(path)
	folder := syscall.UTF16ToString((*[1 << 16]uint16)(unsafe.Pointer(path))[:])
	return folder, nil
}
