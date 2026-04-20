---
title: "Compatibility with other software"
weight: 220
type: docs
---


The speedata Publisher is licensed under the AGPL (GNU Affero General Public License), which does not provide any warranty for the functioning of software.
Nevertheless, it is speedata's endeavor to ensure that the software runs on the most common operating systems and interacts with external software without any problems.

This section summarizes experience reports about compatibility. If something is missing or incorrect here, correction is requested (info@speedata.de).

## Operating systems

| OS | Installer | Last check | Publisher version | Remarks |
| --- | --- | --- | --- | --- |
| macOS 10.14.4 | ZIP | 2021-03-17 | 4.3.12 |  |
| Windows 7 64 bit | ZIP | 2021-03-17 | 4.3.12 |  |
| Windows Server 2012 R2 | ZIP | 2021-03-12 | 4.3.6 | (1) |
| Ubuntu (Docker) | ZIP | 2021-03-17 | 4.3.12 |  |
| Ubuntu 20.04.1 64 bit | Installer (development) | 2021-03-18 | 4.3.12 |  |


1. Additional requirement: Microsoft Visual C++ 2015-2019 Redistributable (x86) 14.24.28127, VCRuntime140.dll

## External software

| Software | OS | Last check | Publisher version | Remarks |
| --- | --- | --- | --- | --- |
| Inkscape 0.92 | Windows 7 64 bit | 2021-03-17 | 4.3.12 | (1) |
| Inkscape 1.0.2 | Windows 7 64 bit | 2021-03-17 | 4.3.12 | (2) |
| Inkscape 0.92 | macOS 10.14.6 | 2021-03-17 | 4.3.12 |  |


1. Configuration in `publisher.cfg` : `inkscape=C:\Program Files\Inkscape\bin\inkscape.com` and `inkscape-command=--export-pdf`.
2. Configuration in `publisher.cfg` : `inkscape=C:\Program Files\Inkscape\bin\inkscape.com` and `inkscape-command=--export-filename`.

## File formats, output

| File type | Allowed formats | Remarks |
| --- | --- | --- |
| Images | PDF, JPEG, PNG |  |
| Fonts | PostScript Type1, TrueType, OpenType (ttf, otf) | Not all fontloaders might support all formats. |
| PDF-Output | PDF/X-3, PDF/X-4, PDF/A-3, PDF/UA |  |
| ZUGFeRD | Version 1 and 2 | Electronic invoice |


## Known problems

* The speedata Publisher installation path on Windows must not contain non-ascii characters (see bug [#310](https://github.com/speedata/publisher/issues/310)).
* The Windows installer truncates the PATH variable to 1024 characters (see bug [#582](https://github.com/speedata/publisher/issues/582).)

