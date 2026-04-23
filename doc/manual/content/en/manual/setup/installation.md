---
title: "Installation instructions"
weight: 10
type: docs
---

The speedata Publisher is available as a pre-built binary package for macOS, Windows and GNU/Linux.
It comes in two plans: Standard and Professional.
The Professional plan offers additional features for professional PDF generation.

## Stable or Development?

The [download page](https://download.speedata.de/) offers two release lines:

- Stable: Tested and proven. This version is recommended for production use.
- Development: Always contains the latest features. Occasionally, new functionality may introduce bugs that are only noticed a few versions later. Choose the development version if you want early access to new features.

![The download page](/img/download-page.png)

## Installation

Download the appropriate ZIP file for your operating system from the [download page](https://download.speedata.de/) and extract it to any location. No administrator rights are required.

{{< callout type="warning" >}}
Do not modify the extracted directory structure — the speedata Publisher expects the original file layout.
{{< /callout >}}

On Windows, there are additional installer packages (.exe) that automatically set the search path, making `sp.exe` available directly from the command line.

On macOS and Linux, you need to add the `bin` directory from the extracted archive to your `PATH`, or call `sp` using its full path.

{{< callout >}}
If you want to build the Publisher from source, see [BUILDING.md](https://github.com/speedata/publisher/blob/develop/BUILDING.md) in the GitHub repository.
{{< /callout >}}
