---
linktitle: "DefineColorprofile"
weight: 260
type: docs
---

# `DefineColorprofile`
_seit Version 3.5.7_

Weist einem externen Farbprofil einem Namen zu. Für PDFOptions.



## Kindelemente

(keine)

## Elternelemente

<a href="../layout"><code>Layout</code></a>, <a href="../section"><code>Section</code></a>

## Attribute


`colors` (Zahl)
: Anzahl der Farben in dem Farbprofil



`condition` (Text, optional)
: Beschreibung der Ausgabebedingung.



`filename` (Text)
: Dateiname des Farbprofils.



`identifier` (Text)
: Der offizielle Name in der Registrierung.



`info` (Text)
: Zusammenfassung des Profils.



`name` (Text)
: Der interne Name des Farbprofils. Für [`PDFOptions`]({{% relref "pdfoptions" %}}).



`registry` (Text, optional)
: Der Name der Registrierung. Voreinstellung ist `http://www.color.org/`.






## Beispiel


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



## Hinweis


Das Farbprofil »FOGRA39« - Coated FOGRA39 (ISO 12647-2:2004) ist in der Distribution enthalten.




