---
linktitle: "DefineColorprofile"
weight: 260
type: docs
---

# `DefineColorprofile`
_since version 3.5.7_

Associate an external color profile with a name. To be used in PDFOptions.



## Child elements

(none)

## Parent elements

<a href="../layout"><code>Layout</code></a>, <a href="../section"><code>Section</code></a>

## Attributes


`colors` (number)
: Number of the colors in this color profile



`condition` (text, optional)
: Description of the output condition.



`filename` (text)
: Filename of the color profile.



`identifier` (text)
: The official identifier for the registry.



`info` (text)
: Short text about the color profile.



`name` (text)
: The internal name of the color profile. To be used in [`PDFOptions`]({{% relref "pdfoptions" %}}).



`registry` (text, optional)
: The name of the registry. Defaults to `http://www.color.org/`.






## Example


```xml
<DefineColorprofile
  name="fogra51"
  identifier="FOGRA51"
  condition="Offset printing, according to ISO 12647-2:2013, 115 g/m2, tone value increase curves A (CMYK)"
  filename="PSOcoated_v3.icc"
  info="Coated FOGRA 51 (ISO 12647-2:2013)"
  registry="http://www.color.org"
  colors="4"
/>

<PDFOptions format="PDF/X-3" colorprofile="fogra51"/>

```



## Info


The profile “FOGRA39” - Coated FOGRA39 (ISO 12647-2:2004) is included in the distribution.




