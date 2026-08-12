---
title: "Datenaufbereitung: vorweg oder im Layout?"
weight: 10
type: docs
---

Diese Frage steht am Anfang jedes Projekts, und ihre Antwort prägt alles Weitere: In welcher Form kommen die Daten in den Publisher? Je näher die Struktur der Datendatei am fertigen Dokument liegt, desto einfacher wird das Layoutregelwerk. Umgekehrt gilt: Wer die Rohdaten aus PIM, Datenbank oder Warenwirtschaft unverändert übernimmt, verlagert die ganze Umbauarbeit ins Layout.

Es gibt drei Wege, die sich auch kombinieren lassen.

## Weg 1: Vorverarbeitung mit XSLT

XSLT ist eine Sprache, die genau für das Umbauen von XML entworfen wurde: umgruppieren, verschachteln, sortieren, mehrere Quelldateien zusammenführen. Der Publisher liefert das XSLT-Programm Saxon mit; gestartet wird die Transformation über einen kleinen [Lua-Filter]({{< relref "preprocessing" >}}):

```lua
runtime = require("runtime")
ok, msg = runtime.run_saxon("transform.xsl", "rawdata.xml", "data.xml")
if not ok then
    print(msg)
    os.exit(-1)
end
```

Der Aufruf `sp --filter transform.lua` (oder der Eintrag `filter=transform.lua` in der `publisher.cfg`) führt das Skript vor jedem Lauf aus.

Die Stärken: XSLT kann kräftig umstrukturieren (etwa gruppieren mit `for-each-group` oder Quellen mit `document()` zusammenführen), die Transformation ist unabhängig vom Publisher entwickel- und testbar, und das Ergebnis liegt als Datei vor, die man ansehen, validieren und archivieren kann. Der Preis: eine weitere Sprache im Projekt, die jemand beherrschen und warten muss.

## Weg 2: Lua-Filter

Der Lua-Filter kann mehr als Saxon starten: Er ist der richtige Weg, wenn die Quelle gar kein XML ist. Die eingebauten Module lesen CSV-, Excel- und beliebige andere Dateien, holen Daten per HTTP von einer API und schreiben mit dem `xml`-Modul die Datendatei für den anschließenden Lauf; auch das Validieren der Eingabe mit RELAX NG gehört hierher. Die Möglichkeiten samt Funktionsreferenz beschreibt das Kapitel [Lua-Filter / Vorverarbeitung]({{< relref "preprocessing" >}}), lauffähige Beispiele gibt es im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/technical) (CSV, JSON, Excel).

Die Stärken: beliebige Datenquellen und volle Programmierlogik, mit demselben Inspizierbarkeits-Vorteil wie bei XSLT (das Ergebnis ist eine Datei). Der Preis ist derselbe: eine Programmiersprache im Projekt.

## Weg 3: Verarbeitung im Layout

Das Layoutregelwerk selbst kann sortieren, filtern, gruppieren und rechnen: XPath-Ausdrücke wählen Daten aus, [`<ForAll>`]({{< relref "programming" >}}) läuft über Elementmengen, [`<SortSequence>` und `<Makeindex>`]({{< relref "indexcreation" >}}) sortieren und gruppieren, mit Variablen und `<Copy-of>` lassen sich Strukturen aufbauen. Für kleine Handgriffe ist das der kürzeste Weg: keine zusätzliche Werkzeugkette, alles steht in einer Datei.

Der Preis zeigt sich beim Wachsen: Komplexe Umstrukturierungen im Layout werden schnell unübersichtlich, es gibt kein Zwischenergebnis, das man zur Fehlersuche ansehen könnte, und die Datenlogik vermischt sich mit der Gestaltungslogik.

## Woran man den richtigen Weg erkennt

* **Wie stark muss umstrukturiert werden?** Nur sortieren, filtern oder Summen bilden: im Layout gut aufgehoben. Umgruppieren, Verschachteln, Aggregieren über mehrere Ebenen: vorweg transformieren.
* **Liegen die Daten überhaupt als XML vor?** CSV, Excel, JSON oder eine API sprechen für den Lua-Filter.
* **Müssen mehrere Datenquellen zusammengeführt werden?** Das gehört in die Vorverarbeitung (XSLT mit `document()` oder Lua), nicht ins Layout.
* **Soll das Zwischenergebnis inspizierbar sein?** Eine Vorverarbeitung schreibt eine Datei, die man ansehen, gegen ein Schema validieren und zu einem Problemfall archivieren kann. Bei der Fehlersuche ist das Gold wert; die Verarbeitung im Layout hat diesen Haltepunkt nicht.
* **Wer wartet das Projekt später?** Die beste Technik nützt nichts, wenn die Person, die das Projekt übernimmt, kein XSLT (oder kein Lua) kann. Diese Frage entscheidet in der Praxis öfter als jede technische.
* **Wie oft ändert sich das Datenformat?** Häufige Formatwechsel sprechen für eine klar abgetrennte, eigenständig testbare Vorverarbeitung, hinter der das Layout stabil bleiben kann.

<!-- TODO PG: Praxiserfahrung ergänzen – z. B. typische Projektverläufe (wann ist ein Projekt von Weg 3 zu Weg 1 gewechselt?), Erfahrungen mit Kunden-Wartbarkeit, Größenordnungen (ab wie vielen Umbauschritten lohnt XSLT?). -->

## Faustregel

Die Datendatei sollte so aussehen wie das Dokument, nicht wie die Datenbank. Alles, was nötig ist, um dahin zu kommen (Reihenfolge, Gruppierung, Zusammenführung), gehört in die Vorverarbeitung. Die kleinen Handgriffe (eine Sortierung, ein Filter, eine Summe) darf das Layout übernehmen. Und die Wege schließen sich nicht aus: Ein Lua-Filter kann erst Excel einlesen und dann Saxon starten, und das Layout sortiert am Ende trotzdem noch eine Artikelliste um.

Wie die Datendatei sinnvoll aufgebaut wird, beschreibt der Abschnitt [Struktur der Datendatei]({{< relref "structuredatafile" >}}).
