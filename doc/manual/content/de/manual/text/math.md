---
title: "Mathematische Formeln"
weight: 55
type: docs
---

Mathematische Formeln werden mit dem Kommando [`<Math>`]({{< relref "/reference/commands/math" >}}) gesetzt. Der Inhalt wird in MathML notiert, der Auszeichnungssprache für Formeln, die auch in HTML und in vielen Redaktionssystemen verwendet wird. Die Formeln werden mit der Mathematik-Engine von LuaTeX gesetzt, mit den Abständen und Größen, die man aus TeX kennt.

Das Kommando ist experimentell. Der unterstützte MathML-Umfang wächst mit den nächsten Versionen, die Grenzen sind am Ende dieser Seite aufgeführt.

## Mathematikschrift laden

Formeln benötigen eine OpenType-Schrift mit einer MATH-Tabelle, zum Beispiel Latin Modern Math, STIX Two Math, Libertinus Math oder TeX Gyre Pagella Math. Die Schrift wird wie jede andere Schrift geladen und als Schriftfamilie definiert. Die Größen für Hoch- und Tiefstellungen leitet der Publisher aus den Angaben in der Schrift ab.

```xml
<LoadFontfile name="mathfont" filename="latinmodern-math.otf"/>
<DefineFontfamily name="mathfont" fontsize="10" leading="12">
    <Regular fontface="mathfont"/>
</DefineFontfamily>
```

Das erste `<Math>`-Element im Layout gibt die Schriftfamilie mit dem Attribut `fontfamily` an. Alle weiteren Formeln verwenden dieselbe Schrift, das Attribut kann dann entfallen. Pro Dokument wird derzeit nur eine Mathematikschrift unterstützt.

## Formeln im Fließtext

`<Math>` steht innerhalb von `<Paragraph>` neben `<Value>` und anderen Textkommandos. Die Kindelemente sind MathML, das Wurzelelement `<math>` und der MathML-Namensraum dürfen angegeben werden, sind aber nicht nötig.

```xml
<Paragraph>
  <Value>Der Satz des Pythagoras </Value>
  <Math fontfamily="mathfont">
    <msup><mi>a</mi><mn>2</mn></msup>
    <mo>+</mo>
    <msup><mi>b</mi><mn>2</mn></msup>
    <mo>=</mo>
    <msup><mi>c</mi><mn>2</mn></msup>
  </Math>
  <Value> gilt in rechtwinkligen Dreiecken.</Value>
</Paragraph>
```

![Formeln im Fließtext](/img/math-inline.png)

Die wichtigsten MathML-Elemente:

`<mi>`
: Bezeichner. Einzelne Buchstaben werden kursiv gesetzt (`x`, `a`, `α`), Funktionsnamen aus mehreren Buchstaben aufrecht und mit einem kleinen Abstand zum Argument (`sin`, `lim`, `log`). Mit `mathvariant="normal"` bleibt ein einzelner Buchstabe aufrecht, etwa das d in dx oder die Konstanten e und i.

`<mn>`
: Zahlen.

`<mo>`
: Operatoren. Der Publisher kennt die Klasse jedes Zeichens (Rechenzeichen, Relation, Klammer, großer Operator) und setzt die Abstände entsprechend. Ein Minus kann als `-` oder als `−` geschrieben werden.

`<mrow>`
: Fasst mehrere Elemente zu einer Gruppe zusammen, etwa als Zähler eines Bruchs.

`<mfrac>`, `<msqrt>`, `<mroot>`
: Bruch mit Zähler und Nenner, Quadratwurzel, Wurzel mit Exponent. Mit `linethickness="0"` entfällt der Bruchstrich, so entstehen Binomialkoeffizienten.

`<mspace>`
: Zusätzlicher Abstand, zum Beispiel `<mspace width="1em"/>` vor dem dx eines Integrals.

`<mstyle>`
: Ändert den Stil für die enthaltenen Elemente: `displaystyle="true"` setzt einen Bruch im Fließtext in voller Größe, `scriptlevel="1"` verkleinert den Inhalt auf die Größe einer Hochstellung.

`<msup>`, `<msub>`, `<msubsup>`
: Hoch- und Tiefstellung. Ein Strich als Exponent (`<msup><mi>f</mi><mo>′</mo></msup>`) wird als Ableitungsstrich gesetzt und nicht zusätzlich hochgestellt.

`<munder>`, `<mover>`, `<munderover>`
: Ausdrücke unter und über einer Basis. Bei großen Operatoren wie `∑` werden sie zu Grenzen, bei Akzentzeichen wie `^`, `¯`, `~` oder `→` zu Akzenten (Vektorpfeil, Überstrich), sonst zu einem kleinen Ausdruck über oder unter der Basis, etwa `x → 0` unter `lim`.

## Abgesetzte Formeln

Mit `display="yes"` wird die Formel im Display-Stil gesetzt: Brüche werden größer, Grenzen von Summen stehen über und unter dem Operator. Die Formel bleibt ein Teil des Absatzes; für eine eigene Zeile bekommt sie einen eigenen Absatz.

```xml
<Paragraph>
  <Math display="yes">
    <munderover><mo>∑</mo><mrow><mi>k</mi><mo>=</mo><mn>1</mn></mrow><mi>n</mi></munderover>
    <mi>k</mi>
    <mo>=</mo>
    <mfrac>
      <mrow><mi>n</mi><mo>(</mo><mi>n</mi><mo>+</mo><mn>1</mn><mo>)</mo></mrow>
      <mn>2</mn>
    </mfrac>
  </Math>
</Paragraph>
```

![Abgesetzte Formeln im Display-Stil](/img/math-display.png)

Eine Formelzeile ist mindestens so hoch wie eine Textzeile der Absatzschrift. Für hohe Formeln (Brüche, Summen mit Grenzen) wird die Zeile so weit vergrößert, dass die Formel nicht in die Nachbarzeilen ragt. Wer bei mehreren abgesetzten Formeln einen gleichmäßigen Abstand möchte, verwendet für diese Absätze eine Schriftfamilie mit größerem `leading`.

Die Formel übernimmt die Farbe des Absatzes (Attribut `color` bei `<Paragraph>`).

## Grenzen

Noch nicht unterstützt sind:

* `<mtable>` (Ausrichtung mehrzeiliger Gleichungen)
* die Werte fett, Fraktur und Schreibschrift des Attributs `mathvariant`
* mehrere Mathematikschriften in einem Dokument
* `<mtext>` in der Textschrift des Absatzes; der Text wird derzeit aus der Mathematikschrift gesetzt

Unbekannte MathML-Elemente werden mit einer Warnung wie `<mrow>` behandelt, die Formel wird also nicht verworfen.
