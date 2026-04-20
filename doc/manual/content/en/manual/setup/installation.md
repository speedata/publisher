---
title: "Installation instructions"
weight: 10
type: docs
---


{{< callout >}}
The speedata Publisher can be downloaded in two versions: `stable` and `development`. Both versions are easy to use. Extensive quality assurance prevents errors from creeping in undetected. In the development version, the documentation may be behind the current status. To try it out, you can usually download the development version. The speedata Publisher also comes with a Standard and a Pro plan. The Pro plan offers additional features that are helpful for professional PDF generation.
{{< /callout >}}

There are three ways to install speedata Publisher:

## Binary packages (The recommended way)

Go to our [download page](https://download.speedata.de/) and download the latest package for your operating system. You can unzip the file anywhere in the filesystem you want. You don't need root/administrator rights to use the Publisher this way. There are extra installer packages for windows, if you don't want to set the `PATH` variable yourself. This is the method if you want to install the [speedata Publisher Pro plan]({{< relref "speedatapro" >}}) software.

## APT repository

If you have root or sudo rights on Debian or Ubuntu GNU/Linux (or a similar system), you can install the .deb files we have prepared from our APT repository. (For now, only the 64 bit architecture is supported.) This is very easy, just follow a few steps:

Add our GPG key to the system to make sure you get the correct software:

```
# all on one line:
curl -fsSL
   http://de.speedata.s3.amazonaws.com/gpgkey-speedata.txt
   | sudo gpg --dearmor
   -o /usr/share/keyrings/speedata_de.gpg
```

Add the following file to /etc/apt/sources.list.d/speedata.list for the development version (unstable):

```
deb
   [arch=amd64 signed-by=/usr/share/keyrings/speedata_de.gpg]
   https://software.speedata.de/download/devel stable main
```

or for the main (stable) releases:

```
deb
   [arch=amd64 signed-by=/usr/share/keyrings/speedata_de.gpg]
   https://software.speedata.de/download/public stable main
```

{{< callout >}}
The previous three commands and source code entries must be on one line.
{{< /callout >}}

Now you can run `sudo apt update` and `apt install speedata-publisher` and have a working installation.

## Build from source

If you want to build the Publisher from source, see [BUILDING.md](https://github.com/speedata/publisher/blob/develop/BUILDING.md) in the GitHub repository.
