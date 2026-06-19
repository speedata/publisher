<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="doc/images/banner-dark.svg">
    <img src="doc/images/banner-light.svg" alt="speedata Publisher — Database in. PDF out." width="900">
  </picture>
</p>

<p align="center">
  <a href="https://doc.speedata.de/publisher/en/installation/"><img src="https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-FFC72C?labelColor=000000" alt="Platforms"></a>
  <a href="COPYING"><img src="https://img.shields.io/badge/license-AGPLv3-FFC72C?labelColor=000000" alt="License: AGPLv3"></a>
  <a href="https://doc.speedata.de/"><img src="https://img.shields.io/badge/manual-online-FFC72C?labelColor=000000" alt="Manual"></a>
  <a href="https://constellation.speedata.de"><img src="https://img.shields.io/badge/Explore%20in-Constellation-FFC72C?labelColor=000000" alt="Explore in Constellation"></a>
</p>

---

Database in. PDF out. Layout-as-code for high-volume, high-precision PDFs — catalogs, reports, manuals, anything where InDesign would mean fifty thousand clicks. Open source, deterministic, scriptable, in production since 2011.

## Real-world performance

Three projects, same binary, same machine (M4 MacBook Air):

```console
# Multi-level TOC, cross-references, PDF bookmarks
$ sp --data produkte.xml --layout katalog.xml
1828 pages rendered in 2m 56s
exit status 0
```

```console
# Table of contents
$ sp --layout reisebroschuere.xml --data kundendaten.xml
13 pages rendered in 0.54s
exit status 0
```

```console
# ZUGFeRD invoice with PDF/A-3 validation
$ sp --data facturx.xml --layout zugferd.xml
1 page rendered in 0.21s
exit status 0
```

<p align="center">
  <img src="doc/images/showcase-brochure.jpg" alt="Sample brochure spread" width="1000">
</p>
<p align="center"><sub>Sample brochure spread — layout-driven, image cutouts, branded tables, cross-references with page numbers.</sub></p>

## Try it in 60 seconds

Grab a ready-to-run package from <https://download.speedata.de/> (extract, set `PATH`, done — no TeX install, no InDesign license, everything bundled including LuaTeX). Then:

```bash
sp new mycatalog && cd mycatalog
sp                # → publisher.pdf
```

Full setup walkthrough in the [installation guide](https://doc.speedata.de/publisher/en/manual/setup/installation/).

## Why speedata Publisher

- **Deterministic.** Same data → bit-identical PDF. Reviewable, diff-able, CI-ready.
- **Scales.** 1,000-page catalogs are the normal case, not the stress test.
- **Layout-as-code.** XML layout language with XPath. Anything that takes a thousand clicks in InDesign is one rule here.
- **Open source.** AGPLv3, builds from source, no closed-source dependencies.
- **Battle-tested.** Production use since 2011, hundreds of QA test cases, long-term-support releases.

Think of it as *XSL-FO on steroids* or *server-side InDesign*.

## Documentation & examples

- **Manual:** <https://doc.speedata.de/> — every command, every attribute, both XML parsers, HTML/CSS mode, REST server mode.
- **Examples repository:** <https://github.com/speedata/examples>
- **Showcase:** <https://www.speedata.de/en/#showcase>
- **QA suite:** the [`qa/`](qa/) directory contains hundreds of self-contained test cases — small, readable, copy-paste-ready.
- **Architecture:** [`ARCHITECTURE.md`](ARCHITECTURE.md)
- **News & changelog:** [`News.md`](News.md), [`news.speedata.de`](https://news.speedata.de/)

## Community & support

- **Bugs & feature requests:** [GitHub issues](https://github.com/speedata/publisher/issues)
- **Commercial support and consulting:** [speedata.de/imprint](https://www.speedata.de/imprint/)
- **Contributing:** fork, branch, PR. Build instructions in [`BUILDING.md`](BUILDING.md).

## Ecosystem

The speedata Publisher is part of a broader ecosystem of PDF, typesetting and publishing technologies.

**[Explore the constellation →](https://constellation.speedata.de)**

## License

AGPLv3 — see [`COPYING`](COPYING).

speedata Publisher uses [LuaTeX](https://www.luatex.org/) for PDF generation (GPLv2 or later). LuaTeX is bundled in the release packages; full third-party list in [`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md).

---
<sub>Source: <https://github.com/speedata/publisher/> · Web: <https://www.speedata.de/></sub>
