---
linktitle: "DefineTextformat"
weight: 310
type: docs
---

# `DefineTextformat`


Definiert ein Textformat. Ein Textformat dient zur Formatierung von Absätzen (Einrückung und Ausrichtung). Auf die definierten Textformate kann im Layout (in den Elementen Paragraph und Textblock) zurückgegriffen werden.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`alignment` (optional)
: Bestimmt die Formatierung des Textes. Voreinstellung ist justified.


  - `justified`: Der Text hat eine rechteckige Form.
  - `leftaligned`: Der Text flattert am rechten Rand.
  - `rightaligned`: Der Text flattert am linken Rand
  - `centered`: Der Text ist im Flattersatz an beiden Rändern (rechts und links) gesetzt.
  - `start`: Der Text flattert am rechten Rand für links-nach-rechts Texte und am linken Rand für rechts-nach-links Texte.
  - `end`: Der Text flattert am linken Rand für links-nach-rechts Texte und am rechten Rand für rechts-nach-links Texte.

`border-bottom` (Längenangabe, optional)
: Die Dicke der Linie unter dem Text



`border-top` (Längenangabe, optional)
: Die Dicke der Linie über dem Text



`break-before` (optional, _seit Version 4.21.15_)
: Umbruch überhalb des Textes erzwingen. Das funktioniert nur wenn der vorherige Text innerhalb derselben [`Output`]({{% relref "output" %}}) Umgebung ist.


  - `auto`: Voreinstellung: Seitenumbruch nicht erzwingen.
  - `page`: Erzwinge einene Seitenumbruch vor dem Text.

`break-below` (optional)
: Umbruch unterhalb des Textes verbieten/erlauben. Das funktioniert nur innerhalb derselben [`Output`]({{% relref "output" %}}) Umgebung.


  - `yes`: Umbruch unterhalb des Textes erlauben (Voreinstellung).
  - `no`: Seitenumbruch unterhalb des Textes verhindern.

`column-padding-top` (optional, _seit Version 3.2.1_)
: Die Höhe des Innenabstands in einer Spalte (oben) mit Output/Text.



`cssfontsize` (yes oder no, optional, _seit Version 5.3.9_)
: Wenn »yes«, wird die Schriftgröße als CSS Schriftgröße interpretiert (z.B. 1.2em, 150%, etc.). Wenn »nein«, wird die Schriftgröße aus der Fontfamilie genommen. Voreinstellung ist »no«.



`fill-last-line` (0 bis 100, optional, _seit Version 3.3.11_)
: Mindestlänge der letzten Zeile im Absatz. Prozentangabe (0 bis 100). Mit Vorsicht anzuwenden. Voreinstellung ist 0.



`html-vertical-spacing` (optional, _seit Version 4.1.6_)
: Setze den vertikalen Abstand für HTML Inhalte. Voreinstellung ist »off«.


  - `all`: Erlaube jeden vertiaklen Abstand.
  - `inner`: Ignoriere ersten und letzten vertikalen Abstand.
  - `off`: Ignoriere alle vertikale Abstände.

`hyphenate` (optional)
: Silbentrennung erlauben oder abschalten (Voreinstellung ist an).


  - `yes`: Silbentrennung erlauben (Voreinstellung).
  - `no`: Silbentrennung für den Absatz verhindern.

`hyphenchar` (Text, optional)
: Das Zeichen, das für Trennung benutzt wird (Voreinstellung: -)



`indentation` (Längenangabe, optional)
: Die Länge des Absatzeinzugs.



`letter-spacing` (Zahl, optional, _seit Version 5.3.18_)
: Zusätzlicher Abstand zwischen Zeichen in 1/1000 em. Beispiel: Ein Wert von 50 fügt 0,05 em zwischen jedem Zeichen ein. Der Wert ist schriftgrößenunabhängig und skaliert mit dem Text.



`margin-bottom` (Längenangabe, optional)
: Abstand zwischen der Linie unten und dem nachfolgenden Absatz.



`margin-top` (Längenangabe, optional)
: Abstand zwischen der Linie oben und dem vorhergehenden Text.



`margin-top-box-start` (optional, _seit Version 3.9.7_)
: Der obere Rand am Start einer Seite. Voreinstellung ist der Wert bei `margin-top`.



`name` (Text)
: Name des Textformats, unter dem es später im Layoutregelwerk angesprochen wird.



`orphan` (yes, no oder eine Zahl, optional)
: Wenn »yes«, Schusterjungen erlauben (erste Zeile eines Absatzes ist auf der vorherigen Seite). Wenn eine Zahl angegeben wird, ist dies die Anzahl der Zeilen, die zusammengehalten werden. Voreinstellung ist »no«.



`padding-top` (Längenangabe, optional)
: Abstand zwischen der Oberkante des Texts und der Linie oben.



`rows` (Zahl, optional)
: Anzahl der Zeilen, die eingezogen werden (wenn `indentation` angegeben ist) bzw. falls die Zahl negativ ist, die Anzahl der Zeilen, die nicht eingerückt werden.



`tab` (optional, _seit Version 3.1.5_)
: Was ist beim Tabulator (& #09;) zu tun?


  - `space`: Tabulator als Leerzeichen interpretieren
  - `hspace`: Interpretiere Tabulator als dehnbaren Leerraum

`widow` (yes, no oder eine Zahl, optional)
: Wenn »yes«, Hurenkinder erlauben (letzte Zeile eines Absatzes ist auf der nächsten Seite). Wenn eine Zahl angegeben wird, ist dies die Anzahl der Zeilen, die zusammengehalten werden. Voreinstellung ist »no«.





## Bemerkungen

Die Textformate `text`, `centered`, `left` und `right` sind vordefiniert. Sie stehen für Blocksatz, zentrierten, linksbündigen und rechtsbündigen Text.

Einrückung funktioniert nicht mit negativen Werten für row im HTML-Modus.




## Beispiel


```xml
<Layout>
  <DefineTextformat name="Text mit Einrückung" alignment="justified" indentation="1cm" />
  ...
  <Record element="...">
    <Textblock textformat="Text mit Einrückung">
      <Paragraph>
        <Value>Text ...</Value>
      </Paragraph>
    </Textblock>
  </Record>
</Layout>
```



