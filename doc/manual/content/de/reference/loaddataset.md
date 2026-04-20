---
linktitle: "LoadDataset"
weight: 520
type: docs
---

# `LoadDataset`


Lädt eine Datensatzdatei, die in einem vorherigen Durchlauf des Publishers erzeugt wurde (Attribut name), oder eine reguläre XML-Datei (Attribut filename). Die »normale« Verarbeitung des Layoutregelwerks wird unterbrochen und mit dem Inhalt der Datensatzdatei fortgeführt. Nachdem die Verarbeitung der neu geladenen Datensatzdatei beendet ist, wird die Verarbeitung des Layoutregelwerks mit dem ursprünglichen Datensatz fortgesetzt. Eine ausführlichere Erläuterung findet sich im Abschnitt über automatisch generierte Verzeichnisse.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`filename` (Text, optional)
: Name der XML-Datei, die geladen werden soll. Beispiel: `meinedatei.xml`.



`name` (Text, optional)
: Name der Dateisatzdatei. Beispiel: toc






## Beispiel


```xml
<Record element="planeten">
  <SetVariable variable="spalte" select="2" />
  <LoadDataset name="toc"/>
  <SetVariable variable="Inhalt" select="''"/>
  <ClearPage/>
  <ProcessNode select="planet"/>
</Record>
```



