css
===

[![Build Status](https://travis-ci.org/thejerf/css.png?branch=master)](https://travis-ci.org/thejerf/css)

A CSS3 tokenizer.

This is gratefully forked from the [Gorilla CSS
scanner](http://www.gorillatoolkit.org/pkg/css/scanner), and had
significant and __BACKWARDS-INCOMPATIBLE__ changes applied to it.

Status
======

Jerf-standard 100% coverage, [full
godoc](https://godoc.org/github.com/thejerf/css/scanner) and is clean by
the standards of many linters. Run through
[go-fuzz](https://github.com/dvyukov/go-fuzz). I have shipped
production-quality software on it, thought as I write this it's not too
heavy a workout yet.

Semantic versioning is being used, so this may also be imported via
`gopkg.in/thejerf/css.v1/scanner`.

Accepting PRs if you have them.

Starting with the commit after dad94e3e4d, I will be signing this repo
with the [jerf keybase.io key](https://keybase.io/jerf).

Versions
========

1. 1.0.1 - June 21, 2016
  * Fix issue with over-consuming strings delimited by apostrophes.
1. 1.0.0
  * Initial release.

Backwards Incompatibility With Gorilla
======================================

This codebase has been made heavily backwards-incompatible to the original
codebase. The tokens emitted by this scanner are
post-processed into their "actual" value... that is, the CSS identifiers
`test` and `te\st` will both yield an Ident token containing `test`.
The URL token will contain the literal URL, with the CSS encoding processed
away. Etc. Code to correctly emit legal tokens has also been added.

I've also taken the liberty of exporting the `Type` (`TokenType` in
Gorilla's version), which turns out to be pretty useful for external
processors. To reduce code stuttering, the Tokens have been renamed to
remove the `Token` prefix, and `TokenChar` is now `TokenDelim`, as that is
what CSS calls it. (Even if I tend to agree `TokenChar` makes more sense,
for this sort of code, best to stick to the standard.)

It turns out the combination of tokens having their "actual" value,
exposing the token types, and having code to re-emit the CSS has made
this useful to other people. If that's what you need, well, here it is.

On The Utility of Godoc.org
===========================

This project taught to me to [search on godoc.org](https://godoc.org/) for Go
packages rather than Google. Google only showed the Gorilla tokenizer,
which I could tell I needed many changes to make work. Much later,
search on godoc, and had I found the [benbjohnson css
parser](https://github.com/benbjohnson/css) I probably would have used that
instead. By the time I found it, it was too late to switch practically.

That said, I _am_ still using this in what is now a production environment
for a non-trivial application, so for all I just said, this is a serious
codebase.
