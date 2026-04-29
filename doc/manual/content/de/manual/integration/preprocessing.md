---
title: "Lua-Filter / Vorverarbeitung"
weight: 63
type: docs
---


Manchmal möchte man vor der eigentlichen PDF-Erstellung die Daten in ein anderes Format überführen oder auf Korrektheit überprüfen.
Dafür gibt es die Möglichkeit (seit Version 3.1.9), ein Lua-Skript vor dem eigentlichen Publishing-Lauf auszuführen.
Lua ist eine einfache, aber mächtige Programmiersprache, die dafür vorgesehen ist, in andere Programme als Skriptsprache einzubauen.

Im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/technical) sind drei Anwendungsfälle zu finden.

{{< callout >}}
Seit Version 5.5.14 läuft die Filter-Vorverarbeitung unter Lua 5.4 (vorher Lua 5.1). Skripte, die `setfenv`/`getfenv`, `unpack(...)` (statt `table.unpack`), `loadstring` oder `module(...)` nutzen, müssen entsprechend angepasst werden.
{{< /callout >}}

## Aufruf des Lua-Skripts

Gestartet wird der Filter entweder über die Kommandozeile

```sh
sp --filter myfile.lua
```

oder über die Konfigurationsdatei, die folgenden Eintrag enthalten muss:

```sh
filter=myfile.lua
```

Das angegebene Lua-Skript wird ausgeführt, bevor die Erzeugung der PDF-Datei beginnt. Das Skript muss im [Publisher-Suchpfad]({{< relref "fileorganization" >}}) liegen.
Daher ist die Hauptanwendung dieses Pre-Processing die Transformation von Daten in ein Format, das für den speedata Publisher geeignet ist. So können CSV oder Excel-Dateien nach XML konvertiert und anschließend die PDF-Erzeugung gestartet werden. Daneben ist es auch möglich, Daten zu validieren.

Im Folgenden werden die Anwendungsmöglichkeiten beschrieben, ganz zum Schluss gibt es nochmals eine Übersicht über die eingebauten Funktionen und Methoden.

## Validieren von Eingabedaten

Um RELAX NG-Dateien zu validieren gibt es mehrere Möglichkeiten. Neben einer Variante, direkt im XML Editor das Schema zu validieren (siehe den entsprechenden [ Abschnitt im Handbuch]({{< relref "schema" >}})) gibt es die Möglichkeit,  ein externes Programm dafür zu nutzen.
Eines davon ist Jing. Es wird mit dem Publisher mitgeliefert.

In der Lua-Vorverarbeitung gibt es eine Funktion, die die Validierung übernimmt:

```lua
runtime = require("runtime")
runtime.validate_relaxng(‹xmlfile›,‹schemafile›)
```

Die Funktion liefert im Fehlerfall `false` und die Fehlermeldung zurück. Beispiel:

```lua
-- adjust the paths, of course
runtime = require("runtime")
ok, msg = runtime.validate_relaxng("layout.xml","../schema/layoutschema-en.rng")
if not ok then
    print(msg)
    os.exit(-1)
end
```

Das speichert man in einer Datei, z.B. `validate.lua` und ruft dann den Publisher mit

```sh
sp --filter validate.lua
```

auf. Vor jedem Lauf wird nun überprüft, ob die Layoutdatei dem Schema entspricht und nur dann wird mit der Verarbeitung fortgefahren.

{{< callout >}}
Man kann nicht nur die Layoutdatei auf Korrektheit überprüfen, sondern auch alle anderen XML-Dateien.
{{< /callout >}}

Hierzu muss man sich jedoch ein eigenes RELAX NG-Schema erstellen.
Eine Anleitung dazu ist unter https://speedata.github.io/relaxngtutorial-de/ verfügbar.
Je nach Datendatei ist das auch recht einfach.
Insbesondere wenn man immer wieder Daten aus fremden Quellen geliefert bekommt, kann man sich so sicher sein, dass die gewünschte Struktur eingehalten wird.

## Ausführen einer Transformation

Eine XSLT-Transformation verarbeitet eine XML-Datei mit einem XSLT-Skript und erzeugt eine Ausgabedatei.
XSLT ist eine Programmiersprache, die für die Verarbeitung von XML-Daten entworfen wurde.
Häufig sind Daten aus PIM-Systemen oder Datenbanken nicht in der Form, die für den Publisher optimal sind.
Mit XSLT kann man solche Ausgangsdaten verarbeiten und verändern.

Das Programm `saxon` (mit dem speedata Publisher mitgeliefert) kann ein XSLT-Skript ausführen.
Der Aufruf ist folgender:

```lua
runtime = require("runtime")
runtime.run_saxon(‹XSL›,‹source›,‹outfile›,‹parameter›)
```

Es kann nur ein Parameter angegeben werden (`key=value`).
Für mehrere Parameter muss die alternative Version über benannte Parameter benutzt werden.

```lua
runtime = require("runtime")
ok, msg = runtime.run_saxon("transformation.xsl","sourcefile.xml","data.xml")

-- quit the publishing process if the transformation fails
if not ok then
    print(msg)
    os.exit(-1)
end
```

Alternativ kann der Aufruf von Saxon auch wie folgt geschehen:

```lua
runtime = require("runtime")
ok, msg = runtime.run_saxon({ key = value, key = value, ... })
```

Erlaubte key/value-Paare sind:

| Schlüssel | Wert |
| --- | --- |
| `source` | Quelldatei (XML) |
| `stylesheet` | Stylesheetdatei (XSL) |
| `out` | Resultat |
| `initialtemplate` | Name des Template, das aufgerufen werden soll |
| `params` | Tabelle mit Parametern für das Stylesheet |


Beispiel:

```lua
runtime = require("runtime")
ok, msg = runtime.run_saxon({stylesheet = 'json2xml.xsl',
                             out = 'data.xml',
                             initialtemplate = 'main',
                             params = { ["key"] = "value" }})
```

Siehe dazu auch das Beispiel im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/technical/jsonreader).

## Erstellen von XML-Dateien

Man kann die zu verarbeitende Datendatei auch mit dem Lua-Skript erstellen.
Dazu gibt es im Modul `xml` die Funktion `encode_table()`, die aus einer Lua-Tabelle eine XML-Datei erstellt.

Das Skript

```lua
xml = require("xml")
tbl = {
    ["_type"] = "element",
    ["_name"] = "data",
    {
       ["_type"] = "element",
       ["_name"] = "child",
       "Hello, world",
    }
}

ok, msg = xml.encode_table(tbl)
if not ok then
    print(msg)
    os.exit(-1)
end
```

erzeugt die XML-Datei

```xml
<data><child>Hello, world</child></data>
```

die für den folgenden Publisher-Lauf zur Verfügung steht.
Das ist besonders dann von Nutzen, wenn die Datenquelle nicht in XML vorliegt.

## Verarbeiten von Excel-Dateien

Ein häufig anzutreffender Anwendungsfall ist, dass die Daten für die Verarbeitung aus Excel-Dateien gelesen werden sollen.
Dazu gibt es im Modul `xlsx` die Funktion `open()`, die eine vorhandene Datei öffnet:

```lua
xlsx = require("xlsx")
spreadsheet, err = xlsx.open("myfile.xlsx")
if not spreadsheet then
    print(err)
    os.exit(-1)
end
```

Das Objekt `spreadsheet` beinhaltet die einzelnen Arbeitsblätter (Worksheets).
Die Anzahl der Arbeitsblätter lässt sich über den length-Operator feststellen und die einzelnen Arbeitsblätter per Index (1 ist das erste Arbeitsblatt).

```lua
numWorksheets = #spreadsheet
ws = spreadsheet[1]
```

Mit dem Objekt `ws` kann direkt auf die Zelleninhalte zugegriffen werden.
Dazu wird es als Funktion aufgerufen und liefert eine Zeichenkette zurück.
Die erste Zelle oben links hat die Koordinaten 1,1, die erste Zelle in der zweiten Zeile 1,2 und so weiter.

```lua
cell1 = ws(1,1)
cell2 = ws(1,2)
```

Den Namen des Arbeitsblattes kann man über den Wert `name` ermitteln:

```lua
name = ws.name
```

## Lesen von CSV-Dateien

Ähnlich wie bei Excel-Dateien kann man auch CSV-Dateien direkt einlesen.
Die Struktur ist jedoch einfacher, da es nur ein »Arbeitsblatt« gibt.

```lua
csv = require("csv")
csvtab, msg = csv.decode("myfile.csv",{columns = {1,2,3}})
if not csvtab then
    print(msg)
    os.exit(-1)
end
```

Der zweite Parameter bei `csv.decode()` ist optional.
In diesem Beispiel werden nur die Spalten 1, 2 und 3 ausgegeben.
Das Ergebnis ist eine Tabelle aus Zeilen.
Jede Zeile ist wiederum eine Tabelle, die die einzelnen Werte der Zeile enthält.

Im Beispiele-Repository wird gezeigt, wie man [aus der CSV-Datei eine XML-Datei erstellen](https://github.com/speedata/examples/tree/master/technical/csvreader) kann.

## Funktionsreferenz

### `runtime`

In diesem Modul werden alle Funktionen und Einstellungen gesammelt, die eher allgemeiner Natur sind.

`projectdir`

Eine Zeichenkette, die das aktuelle Projektverzeichnis enthält (das Verzeichnis mit der `layout.xml` bzw. `publisher.cfg`-Datei)

`variables`

Eine Tabelle mit alle Variablen, die per `-v` auf der Kommandozeile oder in der Konfigurationsdatei mit `vars=...` angegeben wurden.

`finalizer`

Ist dieser Variablen eine Funktion zugewiesen, so wird sie nach der PDF-Erzeugung aufgerufen (callback). Die Funktion hat keine Parameter und keinen Rückgabewert.
```lua
runtime = require("runtime")

function finished()
    print("PDF is finished now.")
end

runtime.finalizer = finished
```

`options`

Tabelle mit Konfigurationswerten (siehe [konfiguration]({{< relref "configuration" >}})). Kann sowohl zum Lesen der Werte als auch zum Setzen benutzt werden.

`validate_relaxng(‹xmldatei›,‹schemadatei›)`

Diese Funktion validiert die angegebene XML-Datei mit dem im zweiten Parameter angegebenen RELAX NG (XML-Syntax) Schema.
Die Rückgabe ist ein boolean-Wert, der true ist, wenn der Befehl fehlerfrei ausgeführt wurde. Ansonsten wird ein zweiter Rückgabewert (string) zurückgegeben, der die Fehlermeldung enthält.

`run_saxon(‹XSL›,‹Quelldatei›,‹Ausgabedatei›,‹Parameter›)`
Diese Funktion ruft das zum Publisher mitgelieferte Programm `saxon` auf. Sie erwartet drei string-Argumente (das Stylesheet, die Eingabe- und die Ausgabedatei) und ein optionales Argument das als Parameter an saxon übergeben wird. Die Rückgabe ist ein boolean-Wert, der true ist, wenn der Befehl fehlerfrei ausgeführt wurde. Ansonsten wird ein zweiter Rückgabewert (string) zurückgegeben, der die Fehlermeldung enthält. Der Parameter hat die Form `keyword=value`.

`run_saxon(‹tabelle›)`
Diese Funktion ruft das zum Publisher mitgelieferte Programm `saxon` auf. Sie erwartet eine Tabelle als Argument mit den Schlüsselwörtern, die unten aufgelistet sind. Die Rückgabe ist ein boolean-Wert, der true ist, wenn der Befehl fehlerfrei ausgeführt wurde. Ansonsten wird ein zweiter Rückgabewert (string) zurückgegeben, der die Fehlermeldung enthält.
| Schlüssel | Wert |
| --- | --- |
| `source` | Quelldatei (XML) |
| `stylesheet` | Stylesheetdatei (XSL) |
| `out` | Resultat |
| `initialtemplate` | Name des Template, das aufgerufen werden soll |
| `params` | Tabelle mit Parametern für das Stylesheet |


`execute(‹Tabelle mit Programmname und Argumenten›)`
Führt ein Programm aus und gibt dessen Ausgabe in die Konsole aus. Um den speedata Publisher z.B. selbst zu starten, funktioniert folgende Syntax:
```lua
runtime.execute({"sp","--runs","2"})
```
Falls erforderlich, muss der erste Parameter (der Programmname) mit dem absoluten Pfad des Programms angegeben werden. Unter Windows funktionieren auch Schrägstriche (`/`) als Trennzeichen anstelle von umgekehrten Schrägstrichen (`\`).
Der erste Rückgabewert ist ein bool (success). Im Fehlerfall ist der zweite Rückgabewert ein Fehlercode (Zahl, falls das Programm mit einem Exit-Code ungleich 0 beendet wurde) oder eine Fehlermeldung (String, falls das Programm gar nicht gestartet werden konnte). Bei Erfolg gibt es keinen zweiten Wert.

`find_file(‹Dateiname oder URL›)`
Findet die angegebene Datei im Publisher-Suchpfad und gibt den absoluten Pfad zurück. Bei nicht gefunden: nil bzw. false und eine Fehlermeldung.

### `xml`

Mit dem XML-Modul werden XML-Dateien erzeugt bzw. gelesen.

`encode_table(‹tabelle›,[dateiname])`

Erzeugt eine XML-Datei (`data.xml` bzw. der optional gegebene Dateiname) der übergebenen Tabelle.
Rückgabewert 1 ist ein bool (success), Wert 2 ist die Fehlermeldung, wenn der erste Wert `false` ist.
Die Tabelle hat folgende Struktur:
```lua
element = {
    ["_type"] = "element",
    ["_name"] = "elementname",
    attribute1 = "value1",
    attribute2 = "value2",
    child1,
    child2,
    child3,
    ...
}
```
`child1`, `...` sind entweder Zeichenketten, Elemente oder Kommentare. Kommentare haben folgende Form:
```lua
comment = {
         _type = "comment",
         _value = " Das ist ein Kommentar! "
   }
```

`decode_xml(‹dateiname›)`

Liest eine XML-Datei ein und gibt eine Tabelle in der Struktur wie unter `encode_table()` beschrieben zurück. Die Rückgabewerte der Funktion sind ein Boolean-Wert und im Falle von true, eine Tabelle wie oben und im Falle von false, eine Fehlermeldung.

### `CSV`

CSV-Dateien

`decode(‹dateiname›,‹parameter›)`

Liest eine CSV-Datei ein. Der Rückgabewert ist eine Tabelle bzw. im Fehlerfall `false` und eine Fehlermeldung.
Die `parameter` werden in einer Tabelle kodiert:
`charset`:
Wenn die CSV-Datei Latin-1 kodiert ist, muss dieser Wert auf ISO-8859-1 stehen. Andere Kodierungen auf Anfrage. Die Voreinstellung (ohne Angabe von charset) ist UTF-8.
`separator`:
Entweder ein Komma (Voreinstellung), ein Semikolon oder das entsprechend genutzte Trennzeichen.

`columns`:

Eine Tabelle, die die gewünschten Spalten in ihrer Reihenfolge enthält.
Z.B. `{3,2,1}` für die ersten drei Spalten in umgekehrter Reihenfolge.

### `xlsx`

Liest eine Excel-Datei ein.

`open(‹dateiname›)`

Öffnet die angegebene Datei. Der Rückgabewert ist ein `spreadsheet`-Objekt bzw. im Fehlerfall `false` und eine Fehlermeldung.
Das `spreadsheet`-Objekt beinhaltet die einzelnen Arbeitsblätter. Die Anzahl der Arbeitsblätter kann mit dem `#`-Operator ermittelt werden. Auf die einzelnen Arbeitsblätter kann man mit dem Index-Operator `[]` zugreifen, wobei das erste Arbeitsblatt den Index 1 hat.
Die einzelnen Arbeitsblätter können als Funktion mit zwei Parametern benutzt werden (siehe Beispiel oben).
Die Parameter sind die x und y Koordinaten der auszulesenden Zelle, die erste Zelle oben links hat die Koordinate 1,1.
Die Ausmaße des Inhalts kann über die Parameter `minrow`, `maxrow`, `mincol` und `maxcol` ermittelt werden.
Der Name ist im Parameter `name` enthalten.

`string_to_date(‹string›)`

Wandelt eine Zahl (kodiert als Zeichenkette) in ein Datum um.
Rückgabe ist eine Tabelle mit den Schlüsseln `day`, `month`, `year`, `hour`, `minute` und `second`. Beispiel: `xlsx.string_to_date("43458")` ergibt
```lua
{
  ["day"] = "24"
  ["month"] = "12"
  ["year"] = "2018"
  ["hour"] = "0"
  ["minute"] = "0"
  ["second"] = "0"
}
```

### `http`

Das `http`-Modul stellt einen einfachen HTTP-Client bereit. Für jede HTTP-Methode gibt es eine eigene Funktion sowie einen generischen `request`-Aufruf:

```lua
http = require("http")
response, err = http.get(‹url›[, ‹optionen›])
response, err = http.post(‹url›[, ‹optionen›])
response, err = http.put(‹url›[, ‹optionen›])
response, err = http.delete(‹url›[, ‹optionen›])
response, err = http.head(‹url›[, ‹optionen›])
response, err = http.patch(‹url›[, ‹optionen›])
response, err = http.request(‹methode›, ‹url›[, ‹optionen›])
```

Im Erfolgsfall wird ein Response-Objekt zurückgegeben, im Fehlerfall `nil` und eine Fehlermeldung. Die Optionen werden als Tabelle übergeben:

| Schlüssel | Wert |
| --- | --- |
| `query` | Query-String (z.B. `"a=1&b=2"`); wird an die URL angehängt |
| `body` | String mit dem Request-Body |
| `form` | String wie `body`, setzt zusätzlich `Content-Type: application/x-www-form-urlencoded` |
| `headers` | Tabelle mit Header-Namen → Werten |
| `cookies` | Tabelle mit Cookie-Namen → Werten |
| `auth` | Tabelle `{user = ..., pass = ...}` für HTTP Basic Auth |
| `timeout` | Zahl (Sekunden) oder String (Go-Duration, z.B. `"500ms"`) |

Auf das Response-Objekt kann mit den folgenden Feldern zugegriffen werden:

| Feld | Beschreibung |
| --- | --- |
| `status_code` | HTTP-Statuscode (Zahl) |
| `body` | Response-Body als String |
| `body_size` | Größe des Bodys in Bytes |
| `headers` | Tabelle mit Response-Headern |
| `cookies` | Tabelle mit Response-Cookies |
| `url` | finale URL nach Redirects |

Beispiel:

```lua
http = require("http")
response, err = http.post("https://api.example.com/users", {
    headers = { ["Content-Type"] = "application/json" },
    body    = '{"name":"Alice"}',
    timeout = 10,
})
if not response then
    print(err)
    os.exit(-1)
end
if response.status_code == 200 then
    print(response.body)
end
```
