---
title: "Schema-Validierung"
weight: 60
type: docs
---


Eine Besonderheit beim speedata Publisher ist, dass die Eingabesprache in XML formuliert ist.
Im Vergleich zu anderen Programmiersprachen ist XML »geschwätzig«:
Man muss für die Start-Tags auch immer Ende-Tags schreiben:

```xml
<PlaceObject>
   ...
</PlaceObject>
```

Im Vergleich zu einer C-ähnlichen Schreibweise wie

```
placeObject(...)
```

ist das mehr Tipparbeit. Die Lösung für dieses »Problem« ist die Verwendung eines Texteditors, der gut mit XML umgehen kann.
Die Eingabe eines Start-Tags würde beispielsweise sofort auch das Ende-Tag einfügen.
Oder bei einer Änderung im Tagnamen würden sowohl Start-Tag als auch das Ende-Tag gleichzeitig geändert werden.
Gute XML-Editoren bewirken noch viel mehr, als nur die erleichterte Eingabe von Tags, z.B. die Validierung des Codes gegen ein Schema.

## Was ist ein Schema?

In einem Schema (z. B. [XML-Schema](https://de.wikipedia.org/wiki/XML_Schema) oder [RELAX NG](https://de.wikipedia.org/wiki/RELAX_NG)) stehen Informationen über den erlaubten Aufbau einer XML-Datei.
So steht im Schema, das mit dem speedata Publisher mitgeliefert wird, beispielsweise:

* Das Wurzelelement muss `<Layout>` heißen
* Das Kindelement von `<PlaceObject>` muss entweder `<Barcode>`, `<Box>`, `<Circle>`, `<Frame>`, `<Image>`, `<Rule>`, `<Table>`, `<Textblock>` oder `<Transformation>` sein.
* Das Attribut `valign` in der Tabellenzeile darf eines der Werte `top`, `middle` oder `bottom` sein
* u.v.m.

Ebenso steht in dem mitgelieferten Schema die Dokumentation der einzelnen Befehle sowie die der Auwahlmöglichkeiten.
Ein guter XML-Editor kann ein solches Schema einlesen und dem Anwender die Eingabe des Quelltextes *erheblich* erleichtern.
Die Eingabe mit einem guten Schema mach viel Spaß und hat einige Vorteile gegenüber dem klassischen Texteditor:

* Syntaxfehler werden sofort angezeigt
* Befehle (Tags) müssen nicht vollständig eingegeben werden, weil der Editor eine Autovervollständigung bietet
* Die Attribute werden sofort auf sinnvolle Werte überprüft
* Dokumentation steht direkt im Editor bereit

\... im Prinzip das, was man von einer integrierten Entwicklungsumgebung  (IDE) erwartet.

![Auswahl an erlaubten Kindelementen](/img/29-autocomplete1.png)

![Erlaubte Attribute bei Textblock](/img/29-autocomplete2.png)

## Geeignete Editoren

Um das Schema zu nutzen, braucht man einen XML-Editor, der RELAX NG oder XML Schema (XSD) verarbeiten kann, zum Beispiel:

-   [OxygenXML](https://www.oxygenxml.com) (Mac, Windows, Linux)
-   [Visual Studio Code](https://code.visualstudio.com) (Mac, Windows, Linux, kostenlos)
-   [XMLSpy](https://www.altova.com/xml-editor/) (Windows)
-   [XML Blueprint](https://www.xmlblueprint.com/) (Windows)
-   [GNU Emacs](https://www.gnu.org/software/emacs/) mit [nxml-mode](https://www.gnu.org/software/emacs/manual/html_mono/nxml-mode.html) (alle Betriebssysteme, kostenlos)
-   [jEdit](http://www.jedit.org) (Mac, Windows, Linux, kostenlos)

## Einbinden der Schemata

Die Schemadateien liegen in der ZIP-Datei im Verzeichnis `share/schema/` unter den Dateinamen

```
layoutschema-de.rng
layoutschema-en.rng
```

für RELAX NG und

```
layoutschema-de.xsd
layoutschema-en.xsd
```

für XSD, je nach gewünschter Sprache der Dokumentation.

Wie das Schema eingebunden wird, ist abhängig vom Editor.
Für verschiedene Editoren ([oXygen XML Editor]({{< relref "oxygenxmlschema" >}}) bzw. [Visual Studio Code]({{< relref "vscodeschema" >}})) gibt es Schritt-für-Schritt-Anleitungen.
