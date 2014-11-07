package gogit

import (
	"testing"
)

// Guard for runtime error: slice bounds out of range
func TestParseCommitData(t *testing.T) {
	str := "tree 47e960bd3b10e549716c31badb1fc06aacd708e1\n" +
		"author Artiom <kron@example.com> 1379666165 +0300" +
		"committer Artiom <kron@example.com> 1379666165 +0300\n\n" +
		"if case if ClientForAction will return error, client can absent (be nil)\n\n" +
		"Conflicts:\n" +
		"	app/class.js\n"

	commit, _ := parseCommitData([]byte(str))

	if commit.treeId.String() != "47e960bd3b10e549716c31badb1fc06aacd708e1" {
		t.Fatalf("Got bad tree %s", commit.treeId)
	}
}
