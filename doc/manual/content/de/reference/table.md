---
linktitle: "Table"
weight: 920
type: docs
---

# `Table`


Erzeugt eine Tabelle, die in etwa dem HTML Tabellenmodell entspricht.



## Kindelemente

<a href="../columns"><code>Columns</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../tablenewpage"><code>TableNewPage</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../tablerule"><code>Tablerule</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../td"><code>Td</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`balance` (optional, _seit Version 3.1.24_)
: Versucht die letzte Seite anhand der Anzahl der Rahmen auszubalancieren. Experimentell


  - `yes`: Versucht die Spalten auszugleichen.
  - `no`: Erste Spalte wird zuerst ausgefüllt

`border-collapse` (optional)
: Bestimmt, ob benachbarte Zellen die Rahmen teilen. Das Verhalten von border-collapse="collapse" ist nicht definiert wenn die Tablle einen Zeilen- oder Spaltenabstand > 0 haben oder wenn die benachbarten Zellen nicht dieselbe Strichstärke und -farbe haben.


  - `separate`: Die Rahmen sind Teil der Zelle und werden nicht mit den Nachbarzellen geteilt.
  - `collapse`: Die Rahmen benachbarter Zellen überlappen sich.

`columndistance` (Längenangabe, optional)
: Der Abstand zwischen zwei Spalten.



`eval` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}), optional)
: Wertet den angegebenen XPath-Ausdruck aus und ignoriert dessen Ausgabe.



`fontfamily` (Text, optional)
: Name der Schriftfamilie, die benutzt werden soll. Wenn keine Schriftart angegeben ist, wird auf die Schriftart ›text‹ umgeschaltet.



`leading` (Längenangabe, optional)
: Der Abstand zwischen zwei Zeilen.



`padding` (Längenangabe, optional)
: Der Innenabstand innerhalb einer Tabellenzelle.



`parent` (Text, optional, _seit Version 4.19.23_)
: Die ID der Elternstruktur für tagged PDF



`role` (optional, _seit Version 4.19.23_)
: Die Rolle für PDF/UA (barrierefreiheit, tagged PDF)



`stretch` (optional)
: Wenn der Tabelleninhalt schmal ist und stretch den Wert nein hat, dann nimmt die Tabelle nur den benötigten Platz ein. Wenn der Tabelleninhalt breit ist oder stretch den Wert max hat, dann nimmt die Tabelle den Wert aus dem Attribut breite ein.


  - `max`: Die Tabelle zur angegebenen Breite dehnen.
  - `no`: Die Tabelle nimmt den kleinstmöglichen Platz ein.

`textformat` (Text, optional, _seit Version 3.7.23_)
: Textformat für die Tabelle. Voreinstellung ist `__leftaligned`, wenn keine Ausrichtung (align) angegeben wird.



`vexcess` (optional, _seit Version 4.5.12_)
: Setze das Verhalten wenn Zeilen vertikal vergrößert werden wegen eines Rowspans.


  - `stretch`: Vergrößere alle Tabellenzellen gleichmäßig (Voreinstellung).
  - `bottom`: Nur die letzte Tabellenzelle vergrößern.

`width` (Zahl oder Längenangabe, optional)
: Der Bereich, den die Tabelle (maximal) im Raster belegt. Angabe in Rasterzellen oder absoluten Längenangaben. Voreinstellung ist der verfügbare Platz.





## Bemerkungen

Die Tabellenzellen dürfen Absätze (Paragraph), Bilder (Bild) und wiederum Tabellen enthalten.




## Beispiel


Mit den folgenden Daten



```xml
<data>
  <row pos="1" verein="FC Bayern München" punkte="56" diff="+31" bemerkung="CL" />
  <row pos="2" verein="FC Schalke 04" punkte="54" diff="+22" bemerkung="CL" />
  <row pos="3" verein="Bayer 04 Leverkusen" punkte="53" diff="+31" bemerkung="CL Qual." />
  <row pos="4" verein="Borussia Dortmund" punkte="45" diff="+10" bemerkung="EL Qual." />
</data>

```

Kann man die Tabelle über folgendes Layout ausgeben:



```xml
<Record element="data">
  <PlaceObject>
    <Table padding="1mm" stretch="max">
      <Tablehead>
        <Tablerule rulewidth="1pt" />
        <Tr align="center">
          <Td><Paragraph><Value>Platz</Value></Paragraph></Td>
          <Td align="left"><Paragraph><Value>Club</Value></Paragraph></Td>
          <Td><Paragraph><Value>Punkte</Value></Paragraph></Td>
          <Td><Paragraph><Value>Differenz</Value></Paragraph></Td>
          <Td align="left"><Paragraph><Value>Bemerkung</Value></Paragraph></Td>
        </Tr>
        <Tablerule rulewidth="0.6pt" />
      </Tablehead>
      <ForAll select="row">
        <Tr align="center">
          <Td><Paragraph><Value select="@pos"/></Paragraph></Td>
          <Td align="left"><Paragraph><Value select="@verein"/></Paragraph></Td>
          <Td><Paragraph><Value select="@punkte"/></Paragraph></Td>
          <Td><Paragraph><Value select="@diff"/></Paragraph></Td>
          <Td align="left"><Paragraph><Value select="@bemerkung"/></Paragraph></Td>
        </Tr>
      </ForAll>
      <Tablefoot>
        <Tablerule rulewidth="1pt" />
      </Tablefoot>
    </Table>
  </PlaceObject>
</Record>

```

![ref-table-de.png](/img/ref-table-de.png)



