---
linktitle: "DefineMatter"
weight: 300
type: docs
---

# `DefineMatter`
_seit Version 4.3.5_

Definiere einen neuen Abschnitt im Dokument.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`label` (optional)
: Setze das Label für die Benutzersichtbare Seitenzahl.


  - `decimal`: Setze die Seitennummerierung auf Dezimalzahlen
  - `lowercase-romannumeral`: Setze die Seitennummerierung auf römische Zahlen (Kleinbuchstaben)
  - `uppercase-romannumeral`: Setze die Seitennummerierung auf römische Zahlen (Großbuchstaben)
  - `lowercase-letter`: Setze die Seitennummerierung auf Buchstaben (a-z)
  - `uppercase-letter`: Setze die Seitennummerierung auf Buchstaben (A-Z)

`name` (Text)
: Der Name des Abschnitts, der definiert werden soll.



`prefix` (Text, optional)
: Der Präfix für die angezeigte Seitenzahl



`resetafter` (yes oder no, optional)
: Setze Seitenzahl auf 1 nach diesem Abschnitt.



`resetbefore` (yes oder no, optional)
: Setze Seitenzahl auf 1 bei Beginn des Abschnitts.





## Bemerkungen

Es gibt zwei vordefinierte Bereiche: mainmatter (Voreinstellung) und frontmatter (das auf römische Zahlen in Kleinbuchstaben umschaltet).




## Beispiel


Setze die Seitennummerierung auf »A-1, A-2, ... «



```xml
<DefineMatter name="mainmatter" label="decimal" prefix="A-" />
```



