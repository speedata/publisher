---
title: "Lua-Callbacks"
weight: 66
type: docs
---

Einige Teile des Publishing-Laufs lassen sich mit Lua-Funktionen anpassen: die Dateisuche und die Konvertierung von Bildern mit externen Programmen.
Dazu wird eine Lua-Datei über die Konfigurationseinstellung `luafile` (oder auf der Kommandozeile mit `--luafile`) angegeben, zum Beispiel:

```
luafile = hooks.lua
```

Die Datei wird zu Beginn des Publishing-Laufs geladen, noch bevor Layout- und Datendatei geöffnet werden.
Sie registriert Funktionen für feste Callback-Namen mit `register_callback()`:

```lua
register_callback("lookup_file", function(name)
    -- ...
end)
```

Die Einstellung wird mit Absicht nur aus der Konfigurationsdatei und von der Kommandozeile gelesen.
Sie kann nicht im Layout gesetzt werden, damit ein Layout niemals Code in den Publishing-Prozess einschleusen kann (Stichwort Servermodus).

Verfügbar seit Version 5.9.2. Die Callbacks lösen auf lange Sicht die Konfigurationseinstellungen `pathrewrite`, `imagehandler` und `resizehandler` ab; diese Einstellungen funktionieren weiterhin wie bisher und werden immer dann verwendet, wenn kein Callback registriert ist oder der Callback `nil` zurückgibt.

## Die Umgebung der Callback-Datei

Die Callback-Datei sieht die Interna des Publishers nicht.
Sie läuft in einer eingeschränkten Umgebung, die nur die offizielle Schnittstelle bereitstellt:

`register_callback(name, fn)`
: Registriert die Funktion `fn` für einen der unten beschriebenen Callback-Namen.

`log(level, meldung, schlüssel, wert, ...)`
: Schreibt eine Meldung in die Protokolldatei. Der Level ist `debug`, `info`, `warn` oder `error`.

`api.version`
: Die Version der Callback-Schnittstelle. Zurzeit `1`.

Standardbibliothek
: `string`, `table`, `math`, `tonumber`, `tostring`, `error`, `assert`, `pcall`, `pairs`, `ipairs`, `next`, `type`, `select`, `io.open`, `io.lines` und `os.getenv`.

Über die Grenze zwischen Publisher und Callbacks gehen nur einfache Werte (Zeichenketten, Zahlen und Tabellen daraus).
Dadurch bleibt die Callback-Datei unabhängig von den Interna des Publishers.

## lookup_file

Der Callback bekommt den Namen jeder angeforderten Datei (Bilder, Schriften, Layout- und Daten-XML, URLs), bevor die eingebaute Dateisuche läuft.
Er kann einen neuen Namen zurückgeben oder `nil`, um den Namen unverändert zu lassen.
Die reguläre Suche läuft anschließend mit dem Ergebnis.

```lua
register_callback("lookup_file", function(name)
    if string.match(name, "^D:\\MEDIA\\") then
        name = string.gsub(name, "^D:\\MEDIA\\", "bilder/")
        return string.gsub(name, "\\", "/")
    end
end)
```

Das ist der mächtigere Ersatz für die Einstellung `pathrewrite`: der Callback kann mit Mustern arbeiten, Groß- und Kleinschreibung ignorieren oder eine Zuordnungstabelle aus einer externen Datei einlesen.
Da der Callback bei jeder Dateisuche aufgerufen wird (auch für Schriften und interne Dateien), sollte er schnell zurückkehren.
Das Ergebnis wird pro Namen für den Lauf zwischengespeichert, der Callback muss für denselben Namen also immer dasselbe Ergebnis liefern.

## image_handler

Der Callback entscheidet, wie eine Bilddatei in ein Format konvertiert wird, das der Publisher einbinden kann (PDF, PNG oder JPEG).
Er bekommt eine Tabelle mit diesen Einträgen:

`input`
: Der vollständige Pfad der Bilddatei.

`extension`
: Die kleingeschriebene Dateiendung, zum Beispiel `tif`. Leer bei eingebetteten Bildinhalten.

`imagetype`
: Nur bei eingebetteten Bildinhalten (`<Image>` mit Kindelementen): der Wert des Attributs `imagetype`.

`outputbase`
: Ein Pfad im Bildcache (ohne Dateiendung), der für die Ausgabedatei dieser Konvertierung reserviert ist.

Der Callback gibt eine der folgenden Möglichkeiten zurück:

* `nil`: der Callback behandelt das Bild nicht. Die Einstellung `imagehandler` und die eingebauten Handler greifen wie bisher.
* Eine Tabelle mit `command` und `output`: der Publisher führt das Kommando aus (eine Liste mit dem Programm und einem Eintrag pro Argument) und bindet die Datei `output` ein.
* Eine Tabelle nur mit `output`: die Datei wird unverändert eingebunden, ohne ein Programm auszuführen.

```lua
register_callback("image_handler", function(job)
    if job.extension == "tif" then
        local out = job.outputbase .. ".pdf"
        return {
            command = { "magick", job.input, out },
            output = out,
        }
    end
end)
```

Da das Kommando eine Liste ist, sind keine Anführungszeichen oder Escaping nötig, auch nicht bei Dateinamen mit Leerzeichen.
Die Ausgabedatei bleibt im Bildcache: existiert sie schon, wird das Kommando nicht erneut ausgeführt.
Der Cachename in `outputbase` enthält einen Hash über den Eingabepfad und die Callback-Datei; eine geänderte Callback-Datei macht den Cache also automatisch ungültig.
Schlägt das Kommando fehl, landet seine vollständige Ausgabe in der Protokolldatei.

## resize_handler

Pro-Funktion: ist das Attribut `dpi` bei `<PDFOptions>` gesetzt, werden Bilder mit höherer Auflösung verkleinert.
Der Callback `resize_handler` kann diese Konvertierung übernehmen.
Er bekommt dieselbe Tabelle wie `image_handler` mit diesen zusätzlichen Einträgen:

`width`, `height`
: Die gewünschte Größe des Ausgabebilds in Pixeln.

`imagetype`
: Der Typ des Bildes, `png` oder `jpg`.

Der Rückgabewert funktioniert genau wie bei `image_handler`:

```lua
register_callback("resize_handler", function(job)
    local out = job.outputbase .. ".png"
    return {
        command = { "magick", job.input, "-resize", job.width .. "x" .. job.height, out },
        output = out,
    }
end)
```
