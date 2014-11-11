// Copyright (c) 2013 Patrick Gundlach, speedata (Berlin, Germany)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

package gogit

import (
	"bytes"
	"compress/zlib"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
)

// A Repository is the base of all other actions. If you need to lookup a
// commit, tree or blob, you do it from here.
type Repository struct {
	Path       string
	indexfiles []*idxFile
}

type SHA1 [20]byte

// Who am I?
type ObjectType int

const (
	ObjectCommit ObjectType = 0x10
	ObjectTree   ObjectType = 0x20
	ObjectBlob   ObjectType = 0x30
	ObjectTag    ObjectType = 0x40
)

func (t ObjectType) String() string {
	switch t {
	case ObjectCommit:
		return "Commit"
	case ObjectTree:
		return "Tree"
	case ObjectBlob:
		return "Blob"
	default:
		return ""
	}
}

type Object struct {
	Type ObjectType
	Oid  *Oid
}

// idx-file
type idxFile struct {
	indexpath    string
	packpath     string
	packversion  uint32
	offsetValues map[SHA1]uint64
}

func readIdxFile(path string) (*idxFile, error) {
	ifile := &idxFile{}
	ifile.indexpath = path
	ifile.packpath = path[0:len(path)-3] + "pack"
	idx, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, err
	}

	if !bytes.HasPrefix(idx, []byte{255, 't', 'O', 'c'}) {
		return nil, errors.New("Not version 2 index file")
	}
	pos := 8
	var fanout [256]uint32
	for i := 0; i < 256; i++ {
		// TODO: use range
		fanout[i] = uint32(idx[pos])<<24 + uint32(idx[pos+1])<<16 + uint32(idx[pos+2])<<8 + uint32(idx[pos+3])
		pos += 4
	}
	numObjects := int(fanout[255])
	ids := make([]SHA1, numObjects)

	for i := 0; i < numObjects; i++ {
		for j := 0; j < 20; j++ {
			ids[i][j] = idx[pos+j]
		}
		pos = pos + 20
	}
	// skip crc32 and offsetValues4
	pos += 8 * numObjects

	excessLen := len(idx) - 258*4 - 28*numObjects - 40
	var offsetValues8 []uint64
	if excessLen > 0 {
		// We have an index table, so let's read it first
		offsetValues8 = make([]uint64, excessLen/8)
		for i := 0; i < excessLen/8; i++ {
			offsetValues8[i] = uint64(idx[pos])<<070 + uint64(idx[pos+1])<<060 + uint64(idx[pos+2])<<050 + uint64(idx[pos+3])<<040 + uint64(idx[pos+4])<<030 + uint64(idx[pos+5])<<020 + uint64(idx[pos+6])<<010 + uint64(idx[pos+7])
			pos = pos + 8
		}
	}
	ifile.offsetValues = make(map[SHA1]uint64, numObjects)
	pos = 258*4 + 24*numObjects
	for i := 0; i < numObjects; i++ {
		offset := uint32(idx[pos])<<24 + uint32(idx[pos+1])<<16 + uint32(idx[pos+2])<<8 + uint32(idx[pos+3])
		offset32ndbit := offset & 0x80000000
		offset31bits := offset & 0x7FFFFFFF
		if offset32ndbit == 0x80000000 {
			// it's an index entry
			ifile.offsetValues[ids[i]] = offsetValues8[offset31bits]
		} else {
			ifile.offsetValues[ids[i]] = uint64(offset31bits)
		}
		pos = pos + 4
	}
	// sha1Packfile := idx[pos : pos+20]
	// sha1Index := idx[pos+21 : pos+40]
	fi, err := os.Open(ifile.packpath)
	if err != nil {
		return nil, err
	}
	defer fi.Close()

	packVersion := make([]byte, 8)
	_, err = fi.Read(packVersion)
	if err != nil {
		return nil, err
	}
	if !bytes.HasPrefix(packVersion, []byte{'P', 'A', 'C', 'K'}) {
		return nil, errors.New("Pack file does not start with 'PACK'")
	}
	ifile.packversion = uint32(packVersion[4])<<24 + uint32(packVersion[5])<<16 + uint32(packVersion[6])<<8 + uint32(packVersion[7])
	return ifile, nil
}

// If the object is stored in its own file (i.e not in a pack file),
// this function returns the full path to the object file.
// It does not test if the file exists.
func filepathFromSHA1(rootdir, sha1 string) string {
	return filepath.Join(rootdir, "objects", sha1[:2], sha1[2:])
}

// Read deflated object from the file.
func readCompressedDataFromFile(file *os.File, start int64, inflatedSize int64) ([]byte, error) {
	_, err := file.Seek(start, os.SEEK_SET)
	if err != nil {
		return nil, err
	}

	rc, err := zlib.NewReader(file)
	if err != nil {
		return nil, err
	}
	defer rc.Close()
	zbuf := make([]byte, inflatedSize)
	// rc.Read can return less than len(zbuf), so we keep reading.
	// I believe it reads at most 0x8000 bytes
	var n, count int
	for count < int(inflatedSize) {
		n, err = rc.Read(zbuf[count:])
		if err != nil {
			return nil, err
		}
		count += n
	}
	return zbuf, nil
}

// buf must be large enough to read the number.
func readLittleEndianBase128Number(buf []byte) (int64, int) {
	zpos := 0
	toread := int64(buf[zpos] & 0x7f)
	shift := uint64(0)
	for buf[zpos]&0x80 > 0 {
		zpos += 1
		shift += 7
		toread |= int64(buf[zpos]&0x7f) << shift
	}
	zpos += 1
	return toread, zpos
}

// We take “delta instructions”, a base object, the expected length
// of the resulting object and we can create a resulting object.
func applyDelta(b []byte, base []byte, resultLen int64) []byte {
	resultObject := make([]byte, resultLen)
	var resultpos uint64
	var basepos uint64
	zpos := 0
	for zpos < len(b) {
		// two modes: copy and insert. copy reads offset and len from the delta
		// instructions and copy len bytes from offset into the resulting object
		// insert takes up to 127 bytes and insert them into the
		// resulting object
		opcode := b[zpos]
		zpos += 1
		if opcode&0x80 > 0 {
			// Copy from base to dest

			copy_offset := uint64(0)
			copy_length := uint64(0)
			shift := uint(0)
			for i := 0; i < 4; i++ {
				if opcode&0x01 > 0 {
					copy_offset |= uint64(b[zpos]) << shift
					zpos += 1
				}
				opcode >>= 1
				shift += 8
			}

			shift = 0
			for i := 0; i < 3; i++ {
				if opcode&0x01 > 0 {
					copy_length |= uint64(b[zpos]) << shift
					zpos += 1
				}
				opcode >>= 1
				shift += 8
			}
			if copy_length == 0 {
				copy_length = 1 << 16
			}
			basepos = copy_offset
			for i := uint64(0); i < copy_length; i++ {
				resultObject[resultpos] = base[basepos]
				resultpos++
				basepos++
			}
		} else if opcode > 0 {
			// insert n bytes at the end of the resulting object. n==opcode
			for i := 0; i < int(opcode); i++ {
				resultObject[resultpos] = b[zpos]
				resultpos++
				zpos++
			}
		} else {
			log.Fatal("opcode == 0")
		}
	}
	// TODO: check if resultlen == resultpos
	return resultObject
}

// The object length in a packfile is a bit more difficult than
// just reading the bytes. The first byte has the length in its
// lowest four bits, and if bit 7 is set, it means 'more' bytes
// will follow. These are added to the »left side« of the length
func readLenInPackFile(buf []byte) (length int, advance int) {
	advance = 0
	shift := [...]byte{0, 4, 11, 18, 25, 32, 39, 46, 53, 60}
	length = int(buf[advance] & 0x0F)
	for buf[advance]&0x80 > 0 {
		advance += 1
		length += (int(buf[advance]&0x7F) << shift[advance])
	}
	advance++
	return
}

// Read from a pack file (given by path) at position offset. If this is a
// non-delta object, the (inflated) bytes are just returned, if the object
// is a deltafied-object, we have to apply the delta to base objects
// before hand.
func readObjectBytes(path string, offset uint64, sizeonly bool) (ot ObjectType, length int64, data []byte, err error) {
	offsetInt := int64(offset)
	file, err := os.Open(path)
	defer file.Close()
	if err != nil {
		return
	}
	pos, err := file.Seek(offsetInt, os.SEEK_SET)
	if err != nil {
		return
	}
	if pos != offsetInt {
		err = errors.New("Seek went wrong")
		return
	}
	buf := make([]byte, 1024)
	n, err := file.Read(buf)
	if err != nil {
		return
	}
	if n == 0 {
		err = errors.New("Nothing read from pack file")
		return
	}
	ot = ObjectType(buf[0] & 0x70)

	l, p := readLenInPackFile(buf)
	pos = int64(p)
	length = int64(l)

	var baseObjectOffset uint64
	switch ot {
	case ObjectCommit, ObjectTree, ObjectBlob, ObjectTag:
		if sizeonly {
			// if we are only interested in the size of the object,
			// we don't need to do more expensive stuff
			return
		}

		data, err = readCompressedDataFromFile(file, offsetInt+pos, length)
		return
	case 0x60:
		// DELTA_ENCODED object w/ offset to base
		// Read the offset first, then calculate the starting point
		// of the base object
		num := int64(buf[pos]) & 0x7f
		for buf[pos]&0x80 > 0 {
			pos = pos + 1
			num = ((num + 1) << 7) | int64(buf[pos]&0x7f)
		}
		baseObjectOffset = uint64(offsetInt - num)
		pos = pos + 1
	case 0x70:
		// DELTA_ENCODED object w/ base BINARY_OBJID
		log.Fatal("not implemented yet")
	}
	var base []byte
	ot, _, base, err = readObjectBytes(path, baseObjectOffset, false)
	if err != nil {
		return
	}
	b, err := readCompressedDataFromFile(file, offsetInt+pos, length)
	if err != nil {
		return
	}
	zpos := 0
	// This is the length of the base object. Do we need to know it?
	_, bytesRead := readLittleEndianBase128Number(b)
	zpos += bytesRead
	resultObjectLength, bytesRead := readLittleEndianBase128Number(b[zpos:])
	zpos += bytesRead
	if sizeonly {
		// if we are only interested in the size of the object,
		// we don't need to do more expensive stuff
		length = resultObjectLength
		return
	}

	data = applyDelta(b[zpos:], base, resultObjectLength)
	return
}

// Return length as integer from zero terminated string
// and the beginning of the real object
func getLengthZeroTerminated(b []byte) (int64, int64) {
	i := 0
	var pos int
	for b[i] != 0 {
		i++
	}
	pos = i
	i--
	var length int64
	var pow int64
	pow = 1
	for i >= 0 {
		length = length + (int64(b[i])-48)*pow
		pow = pow * 10
		i--
	}
	return length, int64(pos) + 1
}

// Read the contents of the object file at path.
// Return the content type, the contents of the file and error, if any
func readObjectFile(path string, sizeonly bool) (ot ObjectType, length int64, data []byte, err error) {
	file, err := os.Open(path)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()
	r, err := zlib.NewReader(file)
	if err != nil {
		return
	}
	defer r.Close()
	first_buffer_size := int64(1024)
	b := make([]byte, first_buffer_size)
	n, err := r.Read(b)
	if err != nil {
		return
	}
	spaceposition := int64(bytes.IndexByte(b, ' '))

	// "tree", "commit", "blob", ...
	objecttypeString := string(b[:spaceposition])

	switch objecttypeString {
	case "blob":
		ot = ObjectBlob
	case "tree":
		ot = ObjectTree
	case "commit":
		ot = ObjectCommit
	case "tag":
		ot = ObjectTag
	}

	// length starts at the position after the space
	var objstart int64
	length, objstart = getLengthZeroTerminated(b[spaceposition+1:])

	if sizeonly {
		// if we are only interested in the size of the object,
		// we don't need to do more expensive stuff
		return
	}

	objstart += spaceposition + 1

	// if the size of our buffer is less than the object length + the bytes
	// in front of the object (example: "commit 234\0") we need to increase
	// the size of the buffer and read the rest. Warning: this should only
	// be done on small files
	if int64(n) < length+objstart {
		remainingSize := length - first_buffer_size + objstart
		remainingBuf := make([]byte, remainingSize)
		n = 0
		var count int64
		for count < remainingSize {
			n, err = r.Read(remainingBuf[count:])
			if err != nil {
				return
			}
			count += int64(n)
		}
		b = append(b, remainingBuf...)
	}
	data = b[objstart : objstart+length]
	return
}

func (repos *Repository) getRawObject(oid *Oid) (ObjectType, int64, []byte, error) {
	// first we need to find out where the commit is stored
	objpath := filepathFromSHA1(repos.Path, oid.String())
	_, err := os.Stat(objpath)
	if os.IsNotExist(err) {
		// doesn't exist, let's look if we find the object somewhere else
		for _, indexfile := range repos.indexfiles {
			if offset := indexfile.offsetValues[oid.Bytes]; offset != 0 {
				return readObjectBytes(indexfile.packpath, offset, false)
			}
		}
		return 0, 0, nil, errors.New("Object not found")
	}
	return readObjectFile(objpath, false)
}

// Open the repository at the given path.
func OpenRepository(path string) (*Repository, error) {
	root := new(Repository)
	path, err := filepath.Abs(path)
	if err != nil {
		return nil, err
	}
	root.Path = path
	fm, err := os.Stat(path)
	if err != nil {
		return nil, err
	}
	if !fm.IsDir() {
		return nil, errors.New(fmt.Sprintf("%q is not a directory."))
	}

	indexfiles, err := filepath.Glob(filepath.Join(path, "objects/pack/*idx"))
	if err != nil {
		return nil, err
	}
	root.indexfiles = make([]*idxFile, len(indexfiles))
	for i, indexfile := range indexfiles {
		idx, err := readIdxFile(indexfile)
		if err != nil {
			return nil, err
		}
		root.indexfiles[i] = idx
	}

	return root, nil
}

// Get the type of an object.
func (repos *Repository) Type(oid *Oid) (ObjectType, error) {
	objtype, _, _, err := repos.getRawObject(oid)
	if err != nil {
		return 0, err
	}
	return objtype, nil
}

// Get (inflated) size of an object.
func (repos *Repository) ObjectSize(oid *Oid) (int64, error) {

	// todo: this is mostly the same as getRawObject -> merge
	// difference is the boolean in readObjectBytes and readObjectFile
	objpath := filepathFromSHA1(repos.Path, oid.String())
	_, err := os.Stat(objpath)
	if os.IsNotExist(err) {
		// doesn't exist, let's look if we find the object somewhere else
		for _, indexfile := range repos.indexfiles {
			if offset := indexfile.offsetValues[oid.Bytes]; offset != 0 {
				_, length, _, err := readObjectBytes(indexfile.packpath, offset, true)
				return length, err
			}
		}

		return 0, errors.New("Object not found")
	}
	_, length, _, err := readObjectFile(objpath, true)
	return length, err
}
