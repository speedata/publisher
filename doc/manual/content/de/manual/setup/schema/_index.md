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

## Einbinden der Schemata

Wie das Schema eingebunden wird, ist abhängig vom Editor.
Im Anhang finden sich für verschiedene Editoren ([oXygen XML Editor]({{< relref "oxygenxmlschema" >}}) bzw. [Visual Studio Code]({{< relref "vscodeschema" >}})) Schritt für Schritt Anleitungen.
Weitere Informationen gibt es im Kapitel [anhang-schemazuweisen]({{< relref "schema" >}}).
