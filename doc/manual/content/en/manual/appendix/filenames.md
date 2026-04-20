---
title: "File name in the Publisher"
weight: 20
type: docs
---


External files are referenced at various points in the layout, mainly in the images.
These can have the following formats:

* Absolute path in the file system: `/path/to/file.png`.
* Relative path in the file system: `../directory/file.png`.
* File within the search tree: `file.png`. Before starting, the current directory is searched recursively (see [File organization]({{< relref "fileorganization" >}})).
* Absolute paths under Windows like `c:\Users\...\file.png`.
* file scheme: `file://c/Users/Joe%20User/file.png` or `file:///home/user/file.png`.
* http-scheme: `http://picsum.photos/400/300` or https: `https://picsum.photos/400/300` ([Pro feature]({{< relref "speedatapro" >}})).

These file names can be used for [Images]({{< relref "/reference/image" >}}), for [XPath- and layoutfunctions]({{< relref "xpath" >}}) as well as on the command line.
So it is possible to start the Publisher with

```sh
sp --dummy --data https://raw.githubusercontent.com/speedata/examples/master/technical/rotating/layout.xml
```

First the resource is cached on the local computer and then loaded from there.

{{< callout >}}
Sometimes the backslash (`\`) itself must be provided with a backslash (`\\`). This is mostly necessary at shell level, i.e. when passing arguments when calling the speedata publisher.
{{< /callout >}}