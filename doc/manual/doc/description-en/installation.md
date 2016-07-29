title: speedata Publisher installation instructions
---

# How to install the speedata Publisher on your system

There are three ways to install speedata Publisher:

2. **Binary packages** (The recommended way): Go to [our download page](https://download.speedata.de/publisher/) and download the latest package for your operating system. You can unzip the file anywhere in the filesystem you want. You don't need root/administrator rights to use the Publisher this way.


1. **APT repository**: If you have root or sudo rights on Debian or Ubuntu GNU/Linux (or a similar system), you can install the .deb files we have prepared from our APT repository. See [the wiki](https://github.com/speedata/publisher/wiki/Linux-packages) for details.

3. **Build from source**: For developers interested in contributing to speedata Publisher, the program and documentation can be built directly from source in the git repository using [rake](https://github.com/ruby/rake), if you have the [Go language](https://golang.org/) version 1.5 or later installed. For example, on Debian or Ubuntu GNU/Linux, where Go is packaged as 'golang', you can use the commands:
 
```
sudo apt install build-essential git rake golang
git clone https://github.com/speedata/publisher.git
cd publisher
rake build
rake doc
```

(Please note that the version of golang in Debian stable (jessie), version 1.3.3, is not recommended for building speedata Publisher. The current golang version 1.6.2 can be installed on this distribution with:
```
sudo apt install -t jessie-backports golang
```
as long as the jessie-backports repository is enabled in the `/etc/apt/sources.list` file on your machine).

If you are building speedata Publisher from source, you will also need to install LuaTeX manually. The recommended way is to download a binary from <https://download.speedata.de/extra/> and copy it into the bin/ directory of the Publisher. For example, to download and install LuajitTeX 0.79.1 on a Linux amd64 system, you could use the commands:

```
wget https://download.speedata.de/extra/luatex_079-win-mac-linux.zip
unzip luatex_079-win-mac-linux.zip
cp luatex/linux/amd64/0_79_1/sdluatex bin
```

After installation, you can run `bin/sdluatex --version` to confirm the program version.

<!--
## Optional: Add `bin` directory to the PATH environment variable

This step is required to run the `sp` program from paths other than the installation directory.

Note: We have prepared installer files for windows, so you can skip this part if you use them.

### Non-permanent: use the terminal to change to the `bin` directory of unzipped file:

On Linux / Mac OS X:

    $ cd speedata-publisher/bin
    $ export PATH=$PATH:$PWD

(the `$` is the command prompt)

On Windows systems:

    C:\>cd speedata-publisher\bin
    C:\>set PATH=%PATH%;%CD%

(where `C:\>` is the command prompt)

The name of the directory will be different on your system.

### Permanent

On Linux

Edit the startup file for your system. This depends heavily on your shell/distribution. Usually it is something like `.bashrc` or `.bash_profile` in your home  directory or `/etc/profile` for a system wide installation. Add a line like this:

    export PATH=$PATH:/path/to/your/installation

On Mac OS X:

Add a file in `/etc/paths.d` with one line (the path do the bin directory):

    $ cd speedata-publisher/bin
    $ echo $PWD | sudo tee /etc/paths.d/speedata

For a local installation see Linux

On Windows:

See http://www.computerhope.com/issues/ch000549.htm for instructions.
 -->