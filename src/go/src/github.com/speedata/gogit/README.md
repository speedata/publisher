gogit
=====

Pure Go read access to a git repository.

**State**: Actively maintained, used in production site, but without warranty, of course.<br>
**Maturity level**: 4/5 (works well in all tested repositories, expect API change, few corner cases not implemented yet)<br>
**License**: Free software (MIT License)<br>
**Installation**: Just run `go get github.com/speedata/gogit`<br>
**API documentation**: http://godoc.org/github.com/speedata/gogit<br>
**Contact**: <gundlach@speedata.de>, [@speedata](https://twitter.com/speedata)<br>
**Repository**: https://github.com/speedata/gogit<br>
**Dependencies**: None<br>
**Contribution**: We like to get any kind of feedback (success stories, bug reports, merge requests, ...)

Example
-------

Sample application to list the latest directory (recursively):

```Go
package main

import (
    "github.com/speedata/gogit"
    "log"
    "os"
    "path"
    "path/filepath"
)

func walk(dirname string, te *gogit.TreeEntry) int {
    log.Println(path.Join(dirname, te.Name))
    return 0
}

func main() {
    wd, err := os.Getwd()
    if err != nil {
        log.Fatal(err)
    }
    repository, err := gogit.OpenRepository(filepath.Join(wd, "src/github.com/speedata/gogit/_testdata/testrepo.git"))
    if err != nil {
        log.Fatal(err)
    }
    ref, err := repository.LookupReference("HEAD")
    if err != nil {
        log.Fatal(err)
    }
    ci, err := repository.LookupCommit(ref.Oid)
    if err != nil {
        log.Fatal(err)
    }
    ci.tree.Walk(walk)
}
```

Sample application
-------------------

We use `gogit` as the backend in http://ctanmirror.speedata.de. This is a
mirror of CTAN, the comprehensive TeX archive network with approx. 25GB of
data. We rsync it from the main site at ctan.org every night and add the
changes to a git repository (with the regular git command). Then we use this web
front end to retrieve the historic files.

The git repository is around 60 GB (Oct. 2013).
