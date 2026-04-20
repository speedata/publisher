---
linktitle: "Tr"
weight: 1000
type: docs
---

# `Tr`


Erstellt eine Tabellenzeile



## Kindelemente

<a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../td"><code>Td</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`align` (optional)
: Die horizontale Ausrichtung des Tabelleninhalts (gilt für die gesamte Zeile).


  - `left`: Der Inhalt der Zelle ist am linken Rand ausgerichtet. (Voreinstellung)
  - `right`: Der Inhalt der Zelle ist rechtsbündig ausgerichtet.
  - `center`: Der Inhalt der Zelle ist auf der Mittelachse ausgerichtet mit links und rechts Flatterrand.
  - `justify`: Text im Blocksatz.

`background-color` (Text, optional)
: Die Farbe der Zellen in der Zeile.



`break-below` (optional)
: Erlaubt einen Tabellenumbruch zwischen dieser und der nächsten Zeile.


  - `yes`: Erlaubt einen Tabellenumbruch zwischen dieser und der nächsten Zeile (Voreinstellung).
  - `no`: Verhindert einen Tabellenumbruch zwischen dieser und der nächsten Zeile.

`data` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}), optional)
: Auf diese Daten können im Tabellenkopf und Tabellenfuß mit `$_last_tr_data` zugegriffen werden.



`minheight` (Zahl oder Längenangabe, optional)
: Die Mindesthöhe der Zeile in Rasterzellen oder als Längenangabe.



`parent` (Text, optional, _seit Version 4.19.23_)
: Die ID der Elternstruktur für tagged PDF



`role` (optional, _seit Version 4.19.23_)
: Die Rolle für PDF/UA (barrierefreiheit, tagged PDF)



`sethead` (optional)
: Diese Zeile für zukünftige Kopfzeilen benutzen.


  - `yes`: Diese Zeile für zukünftige Kopfzeilen benutzen.
  - `no`: Diese Zeile wird nicht besonders behandelt (Voreinstellung).
  - `clear`: Kopf löschen. Weitere Seiten haben keine Kopfzeile bis eine neue gesetzt wird.

`top-distance` (Zahl oder Längenangabe, optional)
: Der Leerraum über dieser Zeile, wenn sie nicht die erste Zeile auf einer Seite/Bereich ist



`valign` (optional)
: Die vertikale Ausrichtung des Tabelleninhalts (gilt für die gesamte Zeile).


  - `top`: Die Objekte dieser Zeile werden oben ausgerichtet.
  - `middle`: Die Objekte dieser Zeile werden auf der Mittelachse ausgerichtet.
  - `bottom`: Die Objekte dieser Zeile werden am unteren Rand ausgerichtet.



## Bemerkungen

Das Attribut `background-color` war `backgroundcolor` bis Version 4.16.




## Beispiel


```xml
<Tr minheight="8mm" background-color="yellow">
  <Td align="center"><Paragraph><Value>4</Value></Paragraph></Td>
  <Td><Paragraph><Value>Borussia Dortmund</Value></Paragraph></Td>
  <Td align="center"><Paragraph><Value>45</Value></Paragraph></Td>
  <Td align="center"><Paragraph><Value>+10</Value></Paragraph></Td>
  <Td><Paragraph><Value>EL Qual.</Value></Paragraph></Td>
</Tr>
```



