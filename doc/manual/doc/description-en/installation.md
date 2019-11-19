title: speedata Publisher installation instructions
---

# How to install the speedata Publisher on your system

There are three ways to install speedata Publisher:

2. **Binary packages** (The recommended way): Go to [our download page](https://download.speedata.de/) and download the latest package for your operating system.
You can unzip the file anywhere in the filesystem you want.
You don't need root/administrator rights to use the Publisher this way.
There are extra installer packages for windows, if you don't want to set the PATH variable yourself.

    On macOS 10.15 (Catalina) the securitiy feature »Gatekeeper« asks for special permissions to run the speedata Publisher. This happens when you download the software from a browser. You can use `curl` to circumvent this (on the command line):

    ```
    curl -O https://download.speedata.de/dl/speedata-publisher-darwin-amd64-latest.zip
    ```

    This loads the ZIP file into the current directory.


1. **APT repository**: If you have root or sudo rights on Debian or Ubuntu GNU/Linux (or a similar system), you can install the .deb files we have prepared from our APT repository. (For now, only the 64 bit architecture is supported.) This is very easy, just follow a few steps:

  1. Add the following file to `/etc/apt/sources.list.d/speedata.list` for the development version (unstable):

        ````
        deb https://software.speedata.de/download/devel stable main
        ````

        or for the main (stable) releases:

        ````
        deb https://software.speedata.de/download/public stable main
        ````

  1. Add our GPG key to the system to make sure you get the correct software:

        ````
		curl -O http://de.speedata.s3.amazonaws.com/gpgkey-speedata.txt
		sudo apt-key add gpgkey-speedata.txt
        ````

  1. Now you can run `sudo apt update` and `apt get install speedata-publisher` and have a working installation. You can find the documentation in `/usr/share/doc/speedata-publisher/index.html` which should open with `sp doc` on a desktop system.

3. **Build from source**: For developers interested in contributing to speedata Publisher, the program and documentation can be built directly from source. You can choose between a [prebuilt docker image on dockerhub](https://hub.docker.com/r/speedata/development) or build the software from the git repository using [rake](https://github.com/ruby/rake). You need to have the [Go language](https://golang.org/) version 1.11 or later installed. For example, on Debian or Ubuntu GNU/Linux, where Go is packaged as 'golang', you can use the commands:
 
    ```
    sudo apt install build-essential git rake golang
    git clone https://github.com/speedata/publisher.git
    cd publisher
    rake build
    rake doc
    ```

    If you are building speedata Publisher from source, you will also need to install LuaTeX manually. The recommended way is to download a binary from <https://download.speedata.de/#extra> and copy it into the bin/ directory of the Publisher.
    For example, to download and install LuajitTeX 1.10 on a Linux amd64 system, you could use the commands:

    ```
    wget https://download.speedata.de/files/extra/luatex_110-win-mac-linux.zip
    unzip luatex_110-win-mac-linux.zip
    cp luatex/linux/amd64/1_10/sdluatex bin
    ```

    After installation, you can run `bin/sdluatex --version` to confirm the program version.
