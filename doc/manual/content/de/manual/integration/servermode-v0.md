---
title: "Server-Modus: API v0"
linktitle: "Server-Modus (API v0)"
weight: 65
type: docs
---

{{< profeature "Verfügbar im PRO-Paket" >}}

Diese Seite beschreibt die ältere Version 0 der Server-API (`/v0/...`).
Sie ist weiterhin verfügbar, wird aber nicht mehr weiterentwickelt.
Neue Integrationen sollten die [API Version 1]({{< relref "servermode" >}}) verwenden.
Start, Adresse, Port und Konfiguration des Servers sind dort beschrieben und gelten für beide Versionen.

{{< callout type="warning" >}}
Der Server-Modus ist für eine nicht-öffentliche Umgebung gedacht. Es gibt keine Authentifizierungsmethoden und keine Mechanismen, Dokumente zu schützen.
{{< /callout >}}

Alle Methoden werden über `http://127.0.0.1:5266/v0/...` angesprochen, nur `/available` hat keine Versionsnummer.

| Methode | URL | Kurzbeschreibung |
| --- | --- | --- |
| GET | [`/available`](#available) | Prüfe, ob der Server läuft. |
| POST | [`/v0/publish`](#post-v0publish) | Sende Daten an den Server, um einen Publishing-Lauf zu starten. |
| GET | [`/v0/publish/<id>`](#get-v0publishid) | PDF und Statusdatei als JSON abholen. |
| GET | [`/v0/pdf/<id>`](#get-v0pdfid) | Warte auf die Fertigstellung eines PDF und lade es herunter. |
| POST | [`/v0/pdf`](#post-v0pdf) | Sende Daten und erhalte das PDF in demselben Request. |
| GET | [`/v0/data/<id>`](#get-v0dataid) | Lade die `data.xml` aus dem Publishing-Lauf. |
| GET | [`/v0/layout/<id>`](#get-v0layoutid) | Lade die `layout.xml` aus dem Publishing-Lauf. |
| GET | [`/v0/statusfile/<id>`](#get-v0statusfileid) | Lade die Statusdatei (`publisher.status`) aus dem Publishing-Lauf. |
| GET | [`/v0/protocol/<id>`](#get-v0protocolid) | Lade die Protokolldatei (`publisher-protocol.xml`) aus dem Publishing-Lauf. |
| GET | [`/v0/status`](#get-v0status) | Übersicht über alle Publishing-Läufe. |
| GET | [`/v0/status/<id>`](#get-v0statusid) | Status eines Publishing-Laufs. |
| GET | [`/v0/delete/<id>`](#get-v0deleteid) | Lösche einen Publishing-Lauf. |

Die Fehlerantworten der v0-API haben kein einheitliches Format. Je nach Methode wird ein JSON-Objekt, ein kurzer Text oder nur ein HTTP-Statuscode zurückgegeben.

## `GET /available` {#available}

Ohne Versionsnummer.
Gibt den HTTP-Status 200 mit leerem Inhalt zurück.

## `POST /v0/publish` {#post-v0publish}

Startet einen Publishing-Lauf. Der Request-Body enthält eine JSON-Datei im folgenden Format:

```json
{
  "<dateiname>": "<base64 kodierter Inhalt>",
  "<dateiname>": "<base64 kodierter Inhalt>"
}
```

also z. B.

```json
{
  "layout.xml": "PD94bWwgdmVyc2lv....",
  "data.xml": "PGRhdGE+CiAgICA8Y29udGVudHM+PCFbQ0RBVEFbPHV..."
}
```

Der Body kann auch leer sein, wenn keine Dateien übertragen werden sollen (z. B. wenn Layout und Daten über `extra-dir` bereitgestellt werden).
Von den Dateinamen wird nur der letzte Teil (ohne Verzeichnisangabe) verwendet.

Diese Dateien werden auf dem Server in ein leeres Verzeichnis kopiert und dort wird `sp` aufgerufen.
Die Rückgabe ist in der Form

```json
{"id":"752869708"}
```

mit einem HTTP-Statuscode 201 (Created).

400 Bad Request
: Der Body ist kein gültiges JSON (Text `JSON encoding error`) oder ein Dateiname ist unbrauchbar (Text `Invalid file name "..."`).

500 Internal Server Error
: Interner Fehler, z. B. wenn ein Dateiinhalt nicht gültig base64-kodiert ist.

### Parameter

Folgende URL-Parameter können beim POST-Request angegeben werden:

`jobname`
: Setzt den Namen der PDF-Datei, der beim Herunterladen über `/v0/pdf/<id>` vorgegeben wird (HTTP-Header `Content-Disposition`).
  Ohne Angabe wird der Eintrag `jobname` aus einer mitgeschickten Datei `publisher.cfg` verwendet, sonst `publisher`.

`vars`
: Setzt Variablen für den Publisher-Lauf. Angabe in der Form `var1=wert1,var2=wert2,var3=wert3...`, jedoch URL-kodiert.

`mode`
: Setzt den Modus für den Lauf. Angabe in der Form `mode1,mode2,mode3...`, aber URL-kodiert.

### Beispiel

```bash
curl -X POST --data @auftrag.json \
  "http://127.0.0.1:5266/v0/publish?vars=myvar%3D12345&mode=a4paper%2Cprint"
```

setzt `myvar` auf `12345` und schaltet die Modi `a4paper` und `print` ein.

## `GET /v0/publish/<id>` {#get-v0publishid}

Liefert das Ergebnis eines Laufs, der mit `POST /v0/publish` gestartet wurde, als JSON-Datei. Der Request wartet nicht auf das Ende des Laufs.

```json
{
  "status": "ok",
  "path": "/pfad/zu/publisher.pdf",
  "blob": "<base64 kodiertes PDF>",
  "statusfile": "<base64 kodierte Datei publisher.status>",
  "finished": "2015-03-03T13:12:55+01:00",
  "output": "<nicht kodierte Ausgabe des sp-Laufs>"
}
```

`status`
: `ok` oder `error`.

`path`
: Pfad zur PDF-Datei auf dem Server.

`blob`
: Die PDF-Datei, base64-kodiert. Im Fehlerfall eine kurze Fehlermeldung.

`statusfile`
: Die Datei `publisher.status`, base64-kodiert. Darin steht unter anderem die Anzahl der Fehler.

`finished`
: Zeitpunkt der Fertigstellung im Format RFC 3339.

`output`
: Die Ausgabe des `sp`-Laufs (nicht kodiert).

Wichtig: `status` ist auch dann `ok`, wenn beim Lauf Fehler aufgetreten sind, solange eine PDF-Datei erzeugt wurde. Ob der Lauf fehlerfrei war, steht in der Statusdatei (Feld `statusfile`) oder lässt sich mit [`/v0/status/<id>`](#get-v0statusid) ermitteln.

Falls die ID unbekannt ist, wird der HTTP-Statuscode 400 zurückgegeben:

```json
{"status":"error","path":"","blob":"id unknown","statusfile":"","finished":"","output":""}
```

Falls der Lauf noch nicht abgeschlossen ist, wird der HTTP-Statuscode 404 zurückgegeben:

```json
{"status":"error","path":"","blob":"not finished","statusfile":"","finished":"","output":""}
```

Falls keine PDF-Datei erzeugt wurde, ist `status` gleich `error`, `path` und `blob` sind leer und `output` enthält die Ausgabe des Laufs.

Das Arbeitsverzeichnis des Laufs wird nach diesem Request gelöscht, sobald der Lauf abgeschlossen ist, es sei denn, die URL enthält den Parameter `delete` mit dem Wert `false`.

Zukünftige Versionen können weitere Felder in der JSON-Antwort haben.

## `GET /v0/pdf/<id>` {#get-v0pdfid}

Gibt die PDF-Datei des Laufs mit der ID aus `POST /v0/publish` zurück. Der Request wartet auf die Fertigstellung des Publishing-Prozesses.
Der Dateiname im HTTP-Header `Content-Disposition` ist der `jobname` aus dem POST-Request bzw. der `publisher.cfg`, sonst `publisher.pdf`.

200 OK
: PDF wurde fehlerfrei generiert. Die Datei wird mit `Content-Type: application/pdf` zurückgegeben.

404 Not Found
: ID ungültig.

406 Not Acceptable
: PDF wurde mit Fehlern generiert. Die Datei wird nicht zurückgegeben.

Das Arbeitsverzeichnis wird nach diesem Request gelöscht (auch bei 406), es sei denn, die URL enthält den Parameter `delete` mit dem Wert `false`.

### Beispiel

```bash
curl "http://127.0.0.1:5266/v0/pdf/752869708?delete=false" -o publisher.pdf
```

## `POST /v0/pdf` {#post-v0pdf}

Sendet Daten an den Server und erhält das PDF in demselben Request zurück. Die Kodierung der Daten und die URL-Parameter entsprechen denen von [`POST /v0/publish`](#post-v0publish), die Rückgabewerte denen von [`GET /v0/pdf/<id>`](#get-v0pdfid).

Können die Daten nicht gespeichert werden, kommen dieselben HTTP-Statuscodes wie bei `POST /v0/publish` (400 bzw. 500), die Antwort enthält dann aber immer den Text `Internal error 021`.

## `GET /v0/data/<id>` {#get-v0dataid}

Liefert die Daten-Datei `data.xml`, die vorab auf den Server kopiert wurde. Das Format kann über den URL-Parameter `format` angegeben werden, zum Beispiel `http://127.0.0.1:5266/v0/data/1347678770?format=base64`:

`json` oder `JSON`
: Liefert eine JSON-Datei im Format `{"contents":"<XML Text>"}`

`base64`
: Liefert die XML-Datei base64-kodiert (`PGRhdGE+CiAgICA8....hPgo=`)

(keine Angabe)
: Liefert die XML-Datei unverändert (`<data>...</data>`) mit `Content-Type: application/xml`

Ist die ID unbekannt, wird der HTTP-Statuscode 404 zurückgegeben. Existiert die Datei nicht, wird der HTTP-Statuscode 200 mit dem Text `Internal error` zurückgegeben.

## `GET /v0/layout/<id>` {#get-v0layoutid}

Liefert die Layout-Datei `layout.xml`, die vorab auf den Server kopiert wurde. Der Parameter `format` und die Rückgabe entsprechen denen von [`/v0/data/<id>`](#get-v0dataid).

## `GET /v0/statusfile/<id>` {#get-v0statusfileid}

Liefert die Datei `publisher.status`, die durch den Lauf erzeugt wurde (`<Status>...</Status>`). Der Parameter `format` und die Rückgabe entsprechen denen von [`/v0/data/<id>`](#get-v0dataid).

## `GET /v0/protocol/<id>` {#get-v0protocolid}

Liefert die Datei `publisher-protocol.xml`, die durch den Lauf erzeugt wurde. Der Parameter `format` und die Rückgabe entsprechen denen von [`/v0/data/<id>`](#get-v0dataid).

## `GET /v0/status` {#get-v0status}

Liefert den Status aller Publishing-Läufe, deren Arbeitsverzeichnis noch existiert und eine Datei `layout.xml` enthält.
Die Schlüssel des JSON-Objekts sind die IDs der Läufe:

```json
{
  "1997009134": {
    "errorstatus": "ok",
    "result": "finished",
    "message": "no errors found",
    "finished": "2016-05-23T11:14:14+02:00"
  },
  "1997329145": {
    "errorstatus": "ok",
    "result": "not finished",
    "message": "",
    "finished": ""
  }
}
```

Die einzelnen Felder haben dieselbe Bedeutung wie unter [`/v0/status/<id>`](#get-v0statusid) beschrieben.

## `GET /v0/status/<id>` {#get-v0statusid}

Ermittelt den Status eines Publishing-Laufs, der per POST-Request an `/v0/publish` gestartet wurde.

```json
{
  "errorstatus": "ok",
  "result": "failed",
  "message": "2 errors occurred during publishing run",
  "finished": "2015-12-25T12:03:04+01:00"
}
```

Die zurückgegebene JSON-Datei hat folgende Schlüssel:

`errorstatus`
: Ist die Anfrage gültig? Mögliche Werte sind `ok` und `error`. Bei `error` enthält `message` den Grund für den Fehler, z. B. `id "123" unknown`.

`result`
: `finished`, falls der Lauf fehlerfrei beendet wurde, `failed`, falls dabei Fehler aufgetreten sind, `not finished`, falls der Publishing-Prozess noch läuft, und `error` bei einer unbekannten ID.

`message`
: Enthält eine informelle Nachricht zum Ergebnis, z. B. `no errors found` oder `2 errors occurred during publishing run`.

`finished`
: Enthält den Zeitstempel, zu dem das PDF fertiggestellt wurde. Das Format entspricht RFC 3339, zum Beispiel `2015-12-25T12:03:04+01:00`.

Ist der Lauf abgeschlossen (`finished` oder `failed`), wird der HTTP-Statuscode 200 zurückgegeben.
Läuft der Prozess noch oder ist die ID unbekannt, ist der HTTP-Statuscode 400.

## `GET /v0/delete/<id>` {#get-v0deleteid}

Löscht das Arbeitsverzeichnis mit dieser ID. Gibt 200 zurück, wenn die ID vorhanden ist, 404 falls nicht.

## Umstieg auf die API v1

| v0 | v1 |
| --- | --- |
| `GET /available` | `GET /v1/available` |
| `POST /v0/publish` | `POST /v1/jobs` |
| `GET /v0/publish/<id>` | `GET /v1/jobs/{id}` und `GET /v1/jobs/{id}/pdf` |
| `GET /v0/pdf/<id>` | `GET /v1/jobs/{id}/pdf` (statt `delete=false` jetzt `keep=true`) |
| `POST /v0/pdf` | `POST /v1/pdf` |
| `GET /v0/data/<id>`, `/v0/layout/<id>`, `/v0/statusfile/<id>`, `/v0/protocol/<id>` | `GET /v1/jobs/{id}/files/{filename}` |
| `GET /v0/status` | `GET /v1/jobs` |
| `GET /v0/status/<id>` | `GET /v1/jobs/{id}` |
| `GET /v0/delete/<id>` | `DELETE /v1/jobs/{id}` |

Der Parameter `jobname` wird in v1 nicht beim Start des Laufs, sondern beim Abholen des PDF (`GET /v1/jobs/{id}/pdf`) angegeben.
