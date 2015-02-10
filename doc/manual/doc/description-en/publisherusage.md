title: speedata Publisher manual
---
How to use the speedata Publisher
=================================

The speedata Publisher is a program without a graphical user interface.
That means it runs on the command line or in the background if called
from a server process.

To run it on the command line, you have to open a terminal window. On
Mac OS X run Terminal.app which is located in Applications/Utilities. On
Windows you click on the windows button and type in `cmd.exe` in the
search box. On Linux, it depends on the distribution you use, but there
is usually a menu entry called “Terminal”.

This is what the terminal window on Mac looks like. On other systems
it should be similar:

{{ img . "terminal.png" }}

Once you have a terminal window open, you can run the speedata Publisher
with the command `sp`. The description of the command is written in the
[section about the command line](commandline.html).

The speedata Publisher expects the data XML file with the name
`data.xml` and the layout XML with the name `layout.xml` (this can be
changed on the command and set in the configuration file) in the current
directory or any of its subdirectories. This search path can be extended
by configuring the publisher (see the section on [how to configure the
speedata publisher](configuration.html)).

