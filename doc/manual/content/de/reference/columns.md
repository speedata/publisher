---
linktitle: "Columns"
weight: 210
type: docs
---

# `Columns`


Legt die Spaltenbreiten und andere Eigenschaften einer Tabelle fest.



## Kindelemente

<a href="../column"><code>Column</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../table"><code>Table</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute
(keine)


## Bemerkungen

Die `*`-Breitenangaben im Element »Column« ermöglicht eine dynamische Aufteilung der Spaltenbreite. Dazu muss die Tabellenbreite vorgegeben sein und das Attribut `stretch` bei [`Table`]({{% relref "table" %}}) auf `max`
        stehen. Die Spaltenbreiten berechnen sich wie folgt: erst werden die fixen Breitenangaben berücksichtigt. Anschließend werden die `*`-Spalten auf den verbleibenden Platz verteilt. Die Angaben
        vor den Sternchen dienen der Verteilung innerhalb der `*`-Spalten. Im Beispiel unten nimmt die vierte Spalte in etwa den fünffachen Platz der dritten Spalte ein. Angenommen die Tabelle sollte
        32mm breit werden. Die fixen Spalten nehmen davon 20mm in Anspruch, übrig bleiben 12 mm. Diese 12mm werden auf die beiden Spalten verteilt, 2mm entfallen auf die `1*`-Spalte (1/6 von 12mm), 10mm
        auf die `5*`-Spalte (5/6 von 12mm).




## Beispiel


```xml
<Table>
  <Columns>
    <Column width="14mm" />
    <Column width="2" />
    <Column width="1*" align="right" valign="top" />
    <Column width="5*" />
    <Column width="5mm" background-color="grau" />
  </Columns>
</Table>
```



