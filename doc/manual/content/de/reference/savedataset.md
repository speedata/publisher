---
linktitle: "SaveDataset"
weight: 800
type: docs
---

# `SaveDataset`


Speichert eine XML-Datei auf Festplatte. Diese Datei muss als Kindelement hierarchische Struktur, zum Beispiel aus den Befehlen Element und Attribut enthalten, wahlweise zusammengesetzt durch Variablen. Eine ausführlichere Erläuterung findet sich im Abschnitt über automatisch generierte Verzeichnisse.



## Kindelemente

<a href="../copy-of"><code>Copy-of</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../makeindex"><code>Makeindex</code></a>, <a href="../sortsequence"><code>SortSequence</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`attributes` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}), optional)
: Der Variablenname (als XPath-Ausdruck, also `$foo`), der [`Attribute`]({{% relref "attribute" %}})-Elemente beinhaltet. Diese Attribute werden zum Wurzelelement hinzugefügt.



`elementname` (Text)
: Name des Wurzelelements, das erzeugt wird.



`name` (Text)
: Name der Dateisatzdatei. Beispiel: toc. Der resultierende Dateiname ist $jobname-$name.xml.



`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}), optional)
: Alternativ zur Angabe des Datensatzes im Kindelement.






## Beispiel


```xml
<SaveDataset name="toc" elementname="Inhalt">
   <Copy-of select="$Inhalt"/>
</SaveDataset>
```

Äquivalent dazu ist:



```xml
<SaveDataset name="toc" elementname="Inhalt" select="$Inhalt" />
```



