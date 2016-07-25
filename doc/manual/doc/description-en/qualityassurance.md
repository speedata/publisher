title: speedata Publisher manual
---
Quality assurance and PDF comparison
====================================

To assure that new versions of the speedata Publisher produce the exact
the same results as before, it has a built in functionality to check for
unwanted changes of behavior.

The idea is as follows: with a layout file and a “good” result (a
reference PDF) the publisher can check whether the current version of
the publisher gets the same result. For that one has to create a layout
and data XML file, run the speedata Publisher and save the result under
the name `reference.pdf`. When the publisher is invoked with
`sp compare <directory>` it will re-create the document and compare,
page by page, if the resulting PDF is visually the same as the
previously created file `reference.pdf`.

Prerequisites for the comparison
--------------------------------

The speedata publisher searches recursively from the given directory for
directories that contain the file `layout.xml` or `publisher.cfg`. In
these directories a new publisher run will be started. The layout file
must be named `layout.xml`, the data file must be named `data.xml`
unless configured otherwise in the optional configuration file
`publisher.cfg`.

The PDF comparison requires an installation of the free software
ImageMagick, that is able to manipulate and compare images without user
interaction. ImageMagick is available for Windows, Mac OS X, Linux and
other platforms.

How to use `sp compare`
-----------------------

Having a layout and a data file you create the PDF as usual. The easiest
way is to create it directly with the name `reference.pdf`.

    sp --jobname reference

creates the correct PDF file. With

    sp --jobname reference clean

the redundant and not needed temporary files are removed. The directory
now looks like this:

    example/
    ├── data.xml
    ├── layout.xml
    └── reference.pdf
     
    0 directories, 3 files

When you run `sp compare example`, no error messages should be given in
the output:

    $ sp compare example/
    Total run time: 1.62956s

If a future version of the publisher introduces a visual change of the
layout, the output would be something like this:

    $ sp compare example/
    /path/to/example
    Comparison failed. Bad pages are: [0]
    Max delta is 2162.760009765625
    Total run time: 862.898ms

The differences are available as a PNG file in the directory:

    example/
    ├── data.xml
    ├── layout.xml
    ├── pagediff.png
    ├── publisher.pdf
    ├── reference.pdf
    ├── reference.png
    └── source.png

The files `source.png` and `reference.png` (with documents that contain
more than one page the file name looks like this: `source-1.png`)
contain the current version and the reference as a bitmap graphic. The
file `pagediff.png` (same numbering scheme as above) contains the
highlighted differences between the two former files.

Quality assurance
-----------------

The facilities of the PDF comparison can be used to create a collection
of sample documents, that are typical for production documents. The
practice is now to install a directory structure as follows:

    qa/
    ├── example1
    │   ├── data.xml
    │   ├── layout.xml
    │   └── reference.pdf
    ├── example2
    │   ├── data.xml
    │   ├── layout.xml
    │   └── reference.pdf
    ├── example3
    │   ├── data.xml
    │   ├── layout.xml
    │   └── reference.pdf
    ├── example4
    │   ├── data.xml
    │   ├── layout.xml
    │   └── reference.pdf
    └── example5
        ├── data.xml
        ├── layout.xml
        └── reference.pdf

When you run `sp compare qa` all subdirectories are visited and checked.
In the best case the output is:

    $ sp compare qa/
    Total run time: 4.541458s

