title: Server-Modus
---

Server-Modus
============

(Experimentell)

Wird der speedata Publisher im Server-Modus gestartet (`sp server`), erwartet das Programm HTTP-Anfragen auf Port 5266 (konfigurierbar).

## `/available`

Gibt den HTTP-Status 200 zurück.

## `/v0/publish`

Wird die URL mit einem POST-Request aufgerufen, erwartet der speedata Publisher eine JSON-Datei im folgenden Format:



    {<dateiname>:<base64 kodierter Inhalt>,
     <dateiname>:<base64 kodierter Inhalt>,
     ...
     }

also z.B.

    {"layout.xml":"PD94bWwgdmVyc2lv....",
     "data.xml":"PGRhdGE+CiAgICA8Y29udGVudHM+PCFbQ0RBVEFbPHV..." }

Diese Dateien werden in ein leeres Verzeichnis kopiert und dort wird `sp` aufgerufen. Die Rückgabe ist in der Form

    {"id":"752869708"}

mit einem HTTP-Statuscode 201 (Created).

Falls die JSON-Datei fehlerhaft ist, wird derzeit ein HTTP-Statuscode 400 (Bad
Request) zurückgegeben, mit dem textuellen Inhalt der Fehlermeldung, z.B.:

    illegal base64 data at input byte 0


### Parameter

Ein URL-Parameter kann angegeben werden, um die Ausgabe der PDF-Datei (ohne Dateiendung) anzugeben:

`/v0/publish?jobname=meinedatei` setzt den Jobname auf "meinedatei", so  dass `/v0/pdf/<id>` die PDF-Datei mit dem Dateinamen `meinedatei.pdf` zurückgibt. Das wird mithilfe des HTTP-Headers `Content-Disposition` erreicht. Wird dieser Parameter nicht angegeben, so wird der `jobname` aus der Datei `publisher.cfg` entnommen, die übermittelt wird. Ist dort keine Option `jobname` gesetzt oder wurde die Datei nicht übermittelt, dann wird der jobname 'publisher' genommen.

Ebenso können zusätzliche Variablen angegeben werden: `/v0/publish?vars=var1%3Dwert1`. Dies entspricht der Angabe auf der Kommandozeile. Die Übergabe erfolgt in der (URL-Kodierten) Form `var1=wert1,var2=wert2,var3=wert3...`.

## `/v0/delete/<id>`

GET: Löscht das Verzeichnis mit dieser ID. Gibt 200 zurück, wenn die ID vorhanden ist, 404 falls nicht.

## `/v0/publish/<id>`

Ein GET-Request mit einer Id aus dem oben beschriebenen POST-Request liefert eine JSON-Datei, mit dem Inhalt:

    {"status":"ok","path":"/pfad/zu/publisher.pdf","blob":"<base64 kodiertes PDF>",
      finished:"2015-03-03T13:12:55+01:00"}

oder, im Fehlerfall, falls die Id unbekannt ist:

    {"status":"error","path":"","blob":"id unknown"}

Falls die PDF-Datei noch nicht geschrieben wurde:

    {"status":"error","path":"","blob":"in progress"}

Das Verzeichnis mit der PDF-Datei wird nach diesem Request gelöscht, es sei denn, die URL enthält die Endung `?delete=false`.

## `/v0/pdf/<id>`

Ein GET-Request mit der Id aus dem POST-Request von `/v0/publish`. Es wird im Erfolgsfall die PDF-Datei mit dem Statuscode 200 und dem Dateinamen `publisher.pdf` zurückgegeben. Der Request wartet auf die Fertigstellung des Publishing Prozesses. Im Fehlerfall wird nur ein Fehlercode zurück gegeben:

Statuscode  | Beschreibung
------------|--------------
200 OK              | PDF wurde fehlerfrei generiert
404 Not Found       | Id ungültig
406  Not Acceptable | PDF wurde fehlerhaft generiert

## `/v0/status`

Liefert den Status aller Publishing-Läufe zurück, die mit `/v0/publish` gestartet wurden.

Die zurückgegebene JSON-Datei hat folgende Schlüssel:

    {
      "1997009134": {
        "errorstatus": "ok",
        "result": "finished",
        "message": "no errors found",
        "finished": "2016-05-23T11:14:14+02:00"
      },
      "1997329145": {
        "errorstatus": "ok",
        "result": "finished",
        "message": "no errors found",
        "finished": "2016-05-23T11:14:14+02:00"
      }
    }

Die einzelnen Felder haben dieselbe Bedeutung wie unter `/v0/status/<id>` beschrieben.

## `/v0/status/<id>`

Ermittelt den Status des Publisher-Laufs, der per POST-Request an `/v0/publish` gesendet wurde.

Die zurückgegebene JSON Datei hat folgende Schlüssel:

Schlüssel   | Beschreibung
------------|--------------
`errorstatus` | Ist die Anfrage gültig? Mögliche Antworten `error` und `ok`. Wenn `error`, dann enthält der Schlüssel `message` den Grund für den Fehler, das Feld `result` ist in dem Fall ohne Bedeutung. Wenn `ok`, dann enthält das Feld `result` den Wert `not finished`, falls die PDF-Datei noch nicht erzeugt wurde.
`result`      | Ist eine PDF-Datei erzeugt worden, enthält das Feld `result` `failed`, falls bei der PDF-Erzeugung Fehler aufgetreten sind, `not finished`, falls der Publishing-Prozess noch fortdauert, ansonsten `ok`.
`message`     | Enthält eine informelle Nachricht zum Ergebnis. Bsp. `no errors found` oder `2 errors occurred during publishing run`.
`finished`    | Enthält den Zeitstempel, zu dem das PDF fertig gestellt wurde. Format entspricht RFC3339, zum Beispiel `2015-12-25T12:03:04+01:00`.



## `/v0/format`

Erzeugt Trennstellen für einen Text, der per POST-Request übergeben wird. Der Text wird mit XML kodiert und kann feste Umbrüche (`<br class="keep" />`) oder Trennvorschläge (`<shy class="keep" />`) enthalten.

Die Rückgabe erfolgt in demselben Format wie die Anfrage.

Die XML-Struktur der Anfrage als auch der Rückgabe muss folgendem RelaxNG-Compact-Schema entsprechen:

    namespace a = "http://relaxng.org/ns/compatibility/annotations/1.0"
    start =
      element root {
        element text {
          (attribute hyphenate-limit-before { xsd:unsignedInt },
           attribute hyphenate-limit-after { xsd:unsignedInt })?,
          mixed {
            element br {
              attribute class { "keep" | "soft" }?,
              empty
            }+,
            element shy {
              attribute class { "keep" | "soft" }?,
              empty
            }+
          }
        }+
      }


