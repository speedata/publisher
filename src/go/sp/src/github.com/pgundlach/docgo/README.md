docgo
=====

documentation generator for golang programs

About
-----

`docgo` is a literate-programming-style documentation generator for Go source
code modeled on Jeremy Ashkenas's [`docco`](http://jashkenas.github.com/docco).
See [here](http://dhconnelly.github.com/docgo/docgo.html) for the result of
running docgo on its own source code.

Getting Started
---------------

Get the source code from [GitHub](https://github.com/dhconnelly/docgo) and
do `go install`, or just run `go get github.com/dhconnelly/docgo`.

Then run `docgo source.go` where source.go is a Go source file in the current
directory.  This creates the file `source.html` in the current directory, a
self-contained HTML page containing your annotated source code.

Author
------

Written by [Daniel Connelly](http://dhconnelly.com) (<dhconnelly@gmail.com>).

License
-------

docgo is released under a BSD-style license, described here and in the
`LICENSE.md` file:

Copyright (c) 2012, Daniel Connelly. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of Daniel Connelly nor the names of its contributors may be
   used to endorse or promote products derived from this software without
   specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
