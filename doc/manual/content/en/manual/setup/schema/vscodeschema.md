---
title: "Visual Studio Code"
weight: 20
type: docs
---


The free (and open source) text editor [Visual Studio Code](https://code.visualstudio.com) (short: VS Code) can be used for many programming languages thanks to numerous extensions. To use the speedata layout schema, the "speedata Publisher" extension is required:

![Open the extensions marketplace and search for `speedata`. Install the "Speedata Publisher" extension.](/img/vscode-speedata-extension.png)

After installing the extension, speedata Publisher layout files are automatically recognized.
A manual association with a schema is no longer necessary.
The extension provides auto-completion and validation based on RELAX NG.

If everything worked out fine, a layout with the namespace `urn:speedata.de:2009/publisher/en` will get the auto-complete with description:

![Auto-complete with short description in Visual Studio Code.](/img/vscode-sample-layout.png)

