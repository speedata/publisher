---
title: "XPath-Standardfunktionen"
weight: 164
type: docs
---

Der Publisher unterstützt die folgenden XPath-Standardfunktionen.
Daneben gibt es die Publisher-spezifischen [Layoutfunktionen]({{< relref "layoutfunctions" >}}) und [selbstdefinierte Funktionen]({{< relref "/reference/commands/function" >}}).


## Zeichenketten

`concat(<Wert>,<Wert>, ...)`
: Erzeugt einen neuen Text aus der Verkettung der Werte.

`contains(<Heuhaufen>,<Nadel>)`
: Wahr, wenn `Heuhaufen` die `Nadel` enthält. Beispiel: `contains('bana','na')` ergibt `true()`.

`starts-with(<String>, <String>)`
: Wahr, wenn die erste Zeichenkette mit der zweiten anfängt.

`ends-with(<String>, <String>)`
: Wahr, wenn die erste Zeichenkette mit der zweiten endet.

`substring(<Eingabe>,<Start>[,<Länge>])`
: Gibt einen Teil der Zeichenkette zurück. `substring('Goldfarb', 5, 3)` gibt `far` zurück. `Start` kann auch negativ sein (zählt vom Ende).

`substring-before(<String>,<String>)`
: Gibt den Teil der ersten Zeichenkette zurück, der vor der zweiten steht. Beispiel: `substring-before("tattoo", "attoo")` ergibt `"t"`.

`substring-after(<String>,<String>)`
: Gibt den Teil der ersten Zeichenkette zurück, der nach der zweiten steht. Beispiel: `substring-after("tattoo", "tat")` ergibt `"too"`.

`string-length(<String>)`
: Gibt die Länge der Zeichenkette zurück. Multibyte-UTF-8-Sequenzen werden als eine Position gezählt.

`string-join(<Sequenz>, <Separator>)`
: Verbindet die Elemente der Sequenz mit dem Separator.

`normalize-space(<Text>)`
: Entfernt führende und nachstehende Leerzeichen. Mehrfache Leerzeichen und Zeilenumbrüche werden durch ein einzelnes Leerzeichen ersetzt.

`upper-case(<Text>)`
: Wandelt den Text in Großbuchstaben. `upper-case('Text')` ergibt `TEXT`.

`lower-case(<Text>)`
: Wandelt den Text in Kleinbuchstaben. `lower-case('Text')` ergibt `text`.

`translate(<Eingabe>,<Von>,<Nach>)`
: Ersetzt alle Zeichen in `Eingabe`, die in `Von` vorkommen, durch das entsprechende Zeichen in `Nach`. Beispiel: `translate('banana','an','uo')` ergibt `buouou`. Wenn `Nach` kürzer als `Von` ist, werden überzählige Zeichen gelöscht.

`compare(<String>,<String>)`
: Vergleicht zwei Zeichenketten: ergibt `-1`, wenn die erste Zeichenkette kleiner als die zweite ist, `0`, wenn beide gleich sind, und `1`, wenn sie größer ist. Beispiel: `compare('a','b')` ergibt `-1`.

`matches(<Text>,<Regexp>[,<Flags>])`
: Prüft, ob der Text auf den regulären Ausdruck passt. Flags: `s`, `i`, `m` (siehe [XPath-Spezifikation](https://www.w3.org/TR/xpath-functions-31/#flags)). Beispiel: `matches("banana", "^(.a)+$")` ergibt wahr.

`replace(<Eingabe>,<Regexp>,<Ersetzung>)`
: Ersetzt alle Treffer des regulären Ausdrucks durch den Ersetzungstext. Beispiel: `replace('banana', 'a', 'o')` ergibt `bonono`. Mit Gruppen: `replace('W151TBH','^[A-Z]([0-9]+)[A-Z]+$', '$1')` ergibt `151`.

`tokenize(<Eingabe>,<Regexp>)`
: Zerlegt die Eingabe anhand des regulären Ausdrucks in eine Sequenz von Zeichenketten. Beispiel: `tokenize("Go home, Jack!", "\W+")` ergibt die Sequenz `"Go", "home", "Jack", ""`.

`string(<Sequenz>)`
: Gibt den Textwert der Sequenz zurück.

`codepoints-to-string(<Codepoints>)`
: Konvertiert eine Sequenz von Codepoints in eine Zeichenkette.

`string-to-codepoints(<String>)`
: Konvertiert eine Zeichenkette in eine Sequenz von Codepoints.


## Zahlen

`number(<Wert>)`
: Konvertiert den Wert in eine Zahl. Falls nicht möglich, wird NaN zurückgegeben.

`abs(<Zahl>)`
: Gibt den Absolutwert zurück. `abs(-1.34)` ergibt `1.34`.

`ceiling(<Zahl>)`
: Rundet auf die nächsthöhere Ganzzahl. `ceiling(1.34)` ergibt `2`.

`floor(<Zahl>)`
: Rundet auf die nächstniedrigere Ganzzahl. `floor(1.7)` ergibt `1`.

`round(<Zahl>[,<Nachkommastellen>])`
: Rundet auf die angegebene Anzahl Nachkommastellen (Voreinstellung: 0).

`round-half-to-even(<Zahl>[,<Nachkommastellen>])`
: Rundet kaufmännisch (Banker's Rounding): bei .5 wird auf die nächste gerade Zahl gerundet.

`format-number(<Zahl>, <Muster>)`
: Formatiert die Zahl nach dem Muster. Beispiel: `format-number(12345.67, '#,##0.00')` ergibt `12,345.67`.

`max(<Sequenz>)`
: Gibt das Maximum zurück. `max((1.1, 2.2, 3.3))` ergibt `3.3`.

`min(<Sequenz>)`
: Gibt das Minimum zurück. `min((1.1, 2.2, 3.3))` ergibt `1.1`.

`sum(<Sequenz>[,<Nullwert>])`
: Gibt die Summe der Werte zurück. `sum((1, 2, 3))` ergibt `6`. Bei einer leeren Sequenz wird `0` zurückgegeben, oder das zweite Argument, falls angegeben.

`avg(<Sequenz>)`
: Gibt den Durchschnitt der Werte zurück. `avg((1, 2, 3))` ergibt `2.0`. Bei einer leeren Sequenz wird die leere Sequenz zurückgegeben.


## Boolesche Funktionen

`true()`
: Gibt wahr zurück.

`false()`
: Gibt falsch zurück.

`not(<Wert>)`
: Negiert den Wahrheitswert. `not(true())` ergibt `false()`.

`boolean(<Sequenz>)`
: Gibt den [effektiven Booleschen Wert](https://www.w3.org/TR/xpath20/#id-ebv) zurück.

`empty(<Sequenz>)`
: Wahr, wenn die Sequenz leer ist (z.B. ein nicht vorhandenes Attribut oder Element).

`exists(<Sequenz>)`
: Wahr, wenn die Sequenz nicht leer ist. Das Gegenteil von `empty()`.


## Sequenzen und Knoten

`count(<Knoten>)`
: Zählt die Kindelemente mit dem angegebenen Namen. Beispiel: `count(article)`.

`position()`
: Gibt die Position des aktuellen Datensatzes zurück.

`last()`
: Gibt die Anzahl der gleichnamigen Geschwister-Elemente zurück.

`distinct-values(<Sequenz>)`
: Gibt die eindeutigen Werte zurück. `distinct-values((1,2,2,3))` ergibt `(1,2,3)`.

`reverse(<Sequenz>)`
: Kehrt die Reihenfolge der Sequenz um.

`index-of(<Sequenz>,<Suchwert>)`
: Gibt die Positionen der Einträge zurück, die gleich dem Suchwert sind. `index-of((10, 20, 30, 20), 20)` ergibt `(2, 4)`.

`insert-before(<Sequenz>,<Position>,<Einträge>)`
: Fügt die Einträge an der angegebenen Position ein. `insert-before(('a', 'b'), 2, 'x')` ergibt `('a', 'x', 'b')`. Positionen außerhalb der Sequenz fügen am Anfang bzw. am Ende ein.

`remove(<Sequenz>,<Position>)`
: Entfernt den Eintrag an der angegebenen Position. `remove(('a', 'b', 'c'), 2)` ergibt `('a', 'c')`.

`subsequence(<Sequenz>,<Start>[,<Länge>])`
: Gibt den Teil der Sequenz ab der Position `Start` zurück (der erste Eintrag ist 1). Ohne `Länge` wird alles bis zum Ende zurückgegeben. `subsequence((1, 2, 3, 4), 2, 2)` ergibt `(2, 3)`.

`deep-equal(<Sequenz>,<Sequenz>)`
: Wahr, wenn beide Sequenzen gleich lang sind und alle Einträge gleich sind. Elemente werden rekursiv verglichen, einschließlich ihrer Attribute und Inhalte.

`zero-or-one(<Sequenz>)`
: Gibt die Sequenz zurück, wenn sie höchstens einen Eintrag enthält, sonst wird ein Fehler ausgelöst.

`one-or-more(<Sequenz>)`
: Gibt die Sequenz zurück, wenn sie mindestens einen Eintrag enthält, sonst wird ein Fehler ausgelöst.

`exactly-one(<Sequenz>)`
: Gibt die Sequenz zurück, wenn sie genau einen Eintrag enthält, sonst wird ein Fehler ausgelöst.

`local-name()`
: Gibt den Namen des aktuellen Knotens zurück (ohne Namensraum).

`name()`
: Gibt den Namen des aktuellen Knotens zurück (mit Namensraum-Präfix).

`namespace-uri([<Knotensequenz>])`
: Gibt den Namensraum-URI des ersten Knotens zurück.

`root(<Element>)`
: Gibt das Wurzelelement zurück.

`doc(<Dateiname>)`
: Öffnet die Datei und gibt den Inhalt als XML-Baum zurück.

`serialize(<Knoten>)`
: Gibt die XML-Serialisierung des Knotens als Zeichenkette zurück. Beispiel: Wenn das aktuelle Element `<item color="red">Text</item>` ist, ergibt `serialize(.)` die Zeichenkette `<item color="red">Text</item>`. Sonderzeichen werden korrekt escaped (`&amp;`, `&lt;`, `&gt;`, `&quot;`).

`unparsed-text(<Dateiname>)`
: Gibt den Inhalt der Datei als uninterpretierten Text zurück.


## Arrays und Maps

Die Funktionen der Namensräume `array:` und `map:` sind im Kapitel [Arrays und Maps]({{< relref "datastructures" >}}) beschrieben, zusammen mit den nötigen Namensraum-Deklarationen und Beispielen.
