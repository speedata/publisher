litebrite
=========

html syntax highlighting for golang programs

About
-----

litebrite is a library for generating syntax-highlighted HTML from your Go
source code.  For an example of its use, check out its [annotated source
code](http://dhconnelly.github.com/litebrite/litebrite.html).

Getting Started
---------------

Get the source code from [GitHub](https://github.com/dhconnelly/litebrite) and
do `go install`, or just run `go get github.com/dhconnelly/litebrite`.

Make sure you `import "github.com/dhconnelly/litebrite"` in your source file.

Then you can

    h := new(litebrite.Highlighter)
    h.CommentClass = "commentz"
    h.OperatorClass = "opz"
    // add some more classes names, see below
    html := h.Highlight(myCodez)

This will return a string of HTML where every comment in the string myCodez
is wrapped with a `<div class="commentz">` tag and every operator is wrapped
with a `<div class="opz">` tag.

The following string fields are available on a Highlighter struct:

CommentClass
OperatorClass
IdentClass
LiteralClass
KeywordClass

Setting a field to a non-nil value causes tokens of that type to be wrapped
with a `<div>` that has your specified CSS class name.

Author
------

Written by [Daniel Connelly](http://dhconnelly.com) (<dhconnelly@gmail.com>).

License
-------

litebrite is released under a BSD-style license, described here and in the
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
