---
linktitle: "Server-Modus (REST API)"
weight: 64
type: docs
---

# Server-Modus (REST API) {{< profeature "Verfügbar im PRO-Paket" >}}

Der Publisher bietet eine Schnittstelle an, mit der über HTTP Aufträge zur Dokumentenerzeugung übergeben werden können. Gestartet wird der Servermodus mit

```
sp server
```

auf der Kommandozeile. Der Servermodus bietet die Möglichkeit

* Daten zum Server zu übertragen und einen Lauf zu starten
* Status des Laufs zu ermitteln (läuft der Prozess noch?)
* fertige PDF-Dateien herunterzuladen
* Protokoll- und andere Dateien aus dem Arbeitsverzeichnis abzurufen

{{< callout type="warning" >}}
Der Server-Modus ist für eine nicht-öffentliche Umgebung gedacht. Es gibt keine Authentifizierungsmethoden und keine Mechanismen, Dokumente zu schützen.
{{< /callout >}}

{{< callout type="info" >}}
Die API Version 0 (`/v0/...`) ist weiterhin verfügbar, wird aber nicht mehr weiterentwickelt.
Neue Integrationen sollten die API Version 1 (`/v1/...`) verwenden.
{{< /callout >}}

Der Server baut die Verbindung auf der IP-Adresse `127.0.0.1` und dem Port `5266` auf.
Die Adresse kann mit den Parametern `address` und `port` in der Konfigurationsdatei bzw. auf der Kommandozeile geändert werden, siehe [den Anhang über die Konfiguration]({{< relref "configuration" >}}).

Beispiel für eine Konfigurationsdatei:

```
[server]
port = 9999
address = 0.0.0.0
extra-dir = /var/projects/fonts:/var/projects/images
filter = convertdata.lua
```

Es folgt ein Überblick über alle API Methoden.
Die aktuelle Versionsnummer der API ist 1, also werden alle Methoden über `http://127.0.0.1:5266/v1/..` angesprochen.

| Methode | URL | Kurzbeschreibung |
| --- | --- | --- |
| GET | [`/v1/available`](#available) | Prüfe, ob der Server läuft. |
| POST | [`/v1/jobs`](#post-v1jobs) | Starte einen Publishing-Lauf. |
| GET | [`/v1/jobs`](#get-v1jobs) | Übersicht über alle Publishing-Läufe. |
| GET | [`/v1/jobs/{id}`](#get-v1jobsid) | Status eines Publishing-Laufs. |
| GET | [`/v1/jobs/{id}/pdf`](#get-v1jobsidpdf) | PDF eines Publishing-Laufs abholen. |
| POST | [`/v1/pdf`](#post-v1pdf) | Daten senden und PDF in einem Request erhalten. |
| GET | [`/v1/jobs/{id}/files/{filename}`](#get-v1jobsidfilesfilename) | Datei aus dem Arbeitsverzeichnis abrufen. |
| DELETE | [`/v1/jobs/{id}`](#delete-v1jobsid) | Publishing-Lauf löschen. |

### Fehlerformat

Alle Fehlerantworten der v1-API verwenden das Format nach [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457) (Problem Details for HTTP APIs) mit dem Content-Type `application/problem+json`:

```json
{
  "type": "about:blank",
  "title": "Job not found",
  "status": 404,
  "detail": "No job with id \"123\" exists",
  "instance": "/v1/jobs/123"
}
```

## `/v1/available`

GET: Gibt den HTTP-Status 200 mit einer JSON-Antwort zurück:

```json
{"status": "ok"}
```

## `POST /v1/jobs`

Startet einen neuen Publishing-Lauf. Der Request-Body kann optional eine JSON-Datei im folgenden Format enthalten:

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

Diese Dateien werden auf dem Server in ein leeres Verzeichnis kopiert und dort wird `sp` aufgerufen.
Die Rückgabe ist in der Form

```json
{"id": "752869708"}
```

mit einem HTTP-Statuscode 201 (Created).

### Parameter

Folgende URL-Parameter können beim POST-Request angegeben werden:

`vars`
: Setzt Variablen für den Publisher-Lauf. Angabe in der Form `var1=wert1,var2=wert2,var3=wert3...`, jedoch URL-kodiert.

`mode`
: Setzt den Modus für den Lauf. Angabe in der Form `mode1,mode2,mode3...`, aber URL-kodiert.

### Beispiel

```bash
curl -X POST "http://127.0.0.1:5266/v1/jobs?vars=myvar%3D12345&mode=a4paper%2Cprint"
```

setzt `myvar` auf `12345` und schaltet die Modi `a4paper` und `print` ein. Die Antwort enthält die Job-ID:

```json
{"id": "752869708"}
```

## `GET /v1/jobs`

Liefert den Status aller Publishing-Läufe zurück.

```json
{
  "jobs": [
    {
      "id": "1997009134",
      "status": "finished",
      "message": "no errors found",
      "finished": "2016-05-23T11:14:14+02:00"
    },
    {
      "id": "1997329145",
      "status": "processing"
    }
  ]
}
```

Mögliche Werte für `status`: `finished`, `failed`, `processing`, `error`.

## `GET /v1/jobs/{id}`

Ermittelt den Status eines einzelnen Publishing-Laufs.

Falls der Lauf noch nicht abgeschlossen ist, wird HTTP-Statuscode **202 (Accepted)** zurückgegeben:

```json
{
  "id": "752869708",
  "status": "processing"
}
```

Falls der Lauf abgeschlossen ist, wird HTTP-Statuscode **200 (OK)** zurückgegeben:

```json
{
  "id": "752869708",
  "status": "finished",
  "message": "no errors found",
  "finished": "2015-12-25T12:03:04+01:00"
}
```

Falls die ID unbekannt ist, wird HTTP-Statuscode **404** mit einer RFC 9457 Fehlerantwort zurückgegeben.

## `GET /v1/jobs/{id}/pdf`

Gibt die erzeugte PDF-Datei zurück. Der Request wartet auf die Fertigstellung des Publishing-Prozesses.

### Parameter

`jobname`
: Setzt den Dateinamen der PDF-Ausgabe im HTTP-Header `Content-Disposition`. Ohne Angabe wird `publisher.pdf` verwendet.

`keep`
: Auf `true` setzen, um das Arbeitsverzeichnis nach dem Download zu behalten. Ohne Angabe wird das Verzeichnis nach dem PDF-Abruf automatisch gelöscht.

### Beispiel

```bash
curl "http://127.0.0.1:5266/v1/jobs/752869708/pdf?jobname=Vertrag2026" -o vertrag.pdf
```

### Rückgabewerte

200 OK
: PDF wurde fehlerfrei generiert. Die Datei wird mit `Content-Type: application/pdf` und einem `Content-Disposition` Header zurückgegeben. Das Arbeitsverzeichnis wird anschließend gelöscht, sofern nicht `keep=true` angegeben wurde.

404 Not Found
: ID ungültig.

406 Not Acceptable
: PDF wurde mit Fehlern generiert.

## `POST /v1/pdf`

Sendet Daten an den Server und erhält das PDF in demselben Request zurück. Die Kodierung der Daten entspricht der von [`POST /v1/jobs`](#post-v1jobs), die Rückgabewerte entsprechen denen von [`GET /v1/jobs/{id}/pdf`](#get-v1jobsidpdf).

## `GET /v1/jobs/{id}/files/{filename}`

Liefert eine beliebige Datei aus dem Arbeitsverzeichnis eines Publishing-Laufs. Nützlich z. B. für die Protokolldatei:

```bash
curl "http://127.0.0.1:5266/v1/jobs/752869708/files/publisher-protocol.xml"
```

200 OK
: Die Datei wird mit einem automatisch erkannten Content-Type zurückgegeben.

404 Not Found
: ID oder Dateiname ungültig.

## `DELETE /v1/jobs/{id}`

Löscht das Arbeitsverzeichnis eines Publishing-Laufs.

204 No Content
: Erfolgreich gelöscht.

404 Not Found
: ID ungültig.

### Beispiel

```bash
curl -X DELETE "http://127.0.0.1:5266/v1/jobs/752869708"
```

## Komplettes Beispiel

Ein typischer Workflow mit der v1-API:

```bash
# 1. Job starten
ID=$(curl -s -X POST "http://127.0.0.1:5266/v1/jobs?vars=mode%3DVERTRAG" | jq -r '.id')
echo "Job gestartet mit ID: $ID"

# 2. Status prüfen (HTTP 202 = läuft noch, 200 = fertig)
curl -s "http://127.0.0.1:5266/v1/jobs/$ID"

# 3. PDF herunterladen (wartet auf Fertigstellung)
#    Das Arbeitsverzeichnis wird danach automatisch gelöscht.
curl -s "http://127.0.0.1:5266/v1/jobs/$ID/pdf?jobname=Vertrag" -o Vertrag.pdf
```

Falls zusätzlich die Protokolldatei benötigt wird, muss das Arbeitsverzeichnis mit `keep=true` erhalten bleiben:

```bash
# 3a. PDF herunterladen, Arbeitsverzeichnis behalten
curl -s "http://127.0.0.1:5266/v1/jobs/$ID/pdf?jobname=Vertrag&keep=true" -o Vertrag.pdf

# 4. Protokolldatei abrufen
curl -s "http://127.0.0.1:5266/v1/jobs/$ID/files/publisher-protocol.xml" -o protokoll.xml

# 5. Arbeitsverzeichnis manuell löschen
curl -s -X DELETE "http://127.0.0.1:5266/v1/jobs/$ID"
```
