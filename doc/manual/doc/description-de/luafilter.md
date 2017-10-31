title: Vorverarbeitung mit dem Lua-Filter
---

Die Möglichkeit, ein Lua-Skript vor dem Publishing-Lauf zu starten, gibt es seit Version 3.1.9.

Die Kommandozeile und die Konfiguration ist dieselbe wie für den XProc-Filter:

    sp --filter myfile.lua

oder

    filter=myfile.lua


Das Lua-Skript wird ausgeführt, bevor die Erzeugung der PDF-Datei beginnt.
Daher ist die Hauptanwendung dieses Pre-Processing wohl die Transformation von Daten in ein Format, das für den speedata Publisher geeignet ist.

In dem Skript ist die volle Unterstützung für Lua gegeben.
Zusätzlich stellt der Publisher mehrere Module (`csv`, `runtime` und `xml`) zur Verfügung, die folgende Einträge beinhalten:

**Hinweis** Die API wird sich noch verändern!

csv
---

`csv.decode(dateiname)`: lädt eine CSV-Datei und erzeugt eine Tabelle mit den
Werten. Die Zeilen sind in den Werten 1-n in der Tabelle gespeichert und
enthalten selber wiederum die Werte in den Indices 1-n. Rückgabewert 1 ist ein
bool (success), Wert 2 ist die Tabelle, wenn der erste Werte `true` ist bzw.
eine Fehlermeldung, wenn der erste Wert `false` ist.



runtime
--------

Wert | Description
------|-------------
`projectdir` | Ein string-Wert, der das aktuelle Projektverzeichnis enthält (das Verzeichnis mit der `layout.xml` bzw. `publisher.cfg`-Datei)
`run_saxon`  | Eine Funktion, die `saxon` aufruft. Sie erwartet drei string-Argumente (das Stylesheet, die Eingabe- und die Ausgabedatei) und ein optionales Argument das als Parameter an saxon übergeben wird. Die Rückgabe ist ein boolean, der true ist, wenn der Befehl fehlerfrei ausgeführt wurde. Ansonsten wird ein zweiter Rückgabewert (string) zurück gegeben, der die Fehlermeldung enthält.


    ok, err = runtime.run_saxon("transformation.xsl","source.xml","data.xml","param1=Wert1 param2=Wert2")

    -- stop the publishing process if an error occurs
    if not ok then
        print(err)
        os.exit(-1)
    end



xml
---

`xml.encode_table(dateiname)`: Erzeugt eine XML-Datei aus einer Tabelle. Rückgabewert 1 ist ein
bool (success), Wert 2 ist die Fehlermeldung, wenn der erste Wert `false` ist.
Die Tabelle hat folgende Stuktur:

Ein Kommentar hat die Form:

    comment = {
             _type = "comment",
             _value = " Das ist ein Kommentar! "
       }


und ein Element:

    element = {
        ["_type"] = "element",
        ["_name"] = "root",
        attribute1 = "value1",
        attribute2 = "value2",
        child1,
        child2,
        child3,
        ...
    }

`child1`, ... sind entweder Zeichenketten, Elemente oder Kommentare.


Die XML-Datei wird unter dem Namen `data.xml` gespeichert.


