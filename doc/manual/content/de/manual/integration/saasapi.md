---
title: "Publisher Webservice API"
weight: 70
type: docs
---

{{< profeature "Verfügbar im PRO-Paket" >}}

Der speedata Publisher kann auch ohne lokale Installation benutzt werden.
Dafür steht unter https://api.speedata.de eine sogenannte Software-as-a-Service Lösung zur Verfügung, die über eine REST-Schnittstelle benutzt werden kann.

Damit die speedata Publisher API angesteuert werden kann, muss ein gültiges Pro-Paket vorliegen und ein API Schlüssel (token) im Download-Bereich erzeugt werden. Mit diesem Schlüssel kann man dann alle Funktionen ansprechen.

## Authentifizierung

Alle Methoden, deren Pfad mit `/v0` anfangen, müssen mit einem Benutzernamen authentifiziert werden:

```shell
curl -u "sdapi_...:" "https://api.speedata.de/v0/.."
```

Der Doppelpunkt bei `-u` trennt den Benutzernamen vom Passwort und ist nicht Teil des Benutzernamens.

{{< callout >}}
Der Benutzername ist natürlich durch den eigenen Token zu ersetzen, der unter https://download.speedata.de/#account erzeugt werden muss.
{{< /callout >}}

## Übersicht über die REST Methoden

| Methode | URL | Kurzbeschreibung |
| --- | --- | --- |
| GET | [`/available`]({{< relref "saasapi#saasapi-method-available" >}}) | Gib 200 zurück, um zu prüfen, ob der Server läuft. |
| GET | [`/v0/versions`]({{< relref "saasapi#saasapi-method-versions" >}}) | Liste verfügbare Versionen auf. |
| POST | [`/v0/publish`]({{< relref "saasapi#saasapi-method-publish" >}}) | Starte einen Publishing-Vorgang. |
| GET | `/v0/status/<id>` | Erhalte den Status eines Publishing-Laufs. |
| GET | `/v0/wait/<id>` | Warte auf die Fertigstellung des PDFs. |
| GET | `/v0/pdf/<id>` | Lade das PDF. |


### `/available`

Ohne Versionsnummer.
Gibt den HTTP-Status 200 zurück.

### `/v0/versions`

Liste alle verfügbaren Versionen auf. Die Rückgabe ist ein JSON-Array in der Form:

```json
["1.3.12", "1.4.1", "1.5.0-dev"]
```

Die Version kann als Query-Parameter bei /v0/publish benutzt werden.

Unterstützt werden:

* Alle stabilen Versionen (z. B. 5.0.2)
* Alle Entwicklungsversionen seit der letzten stabilen Version (z. B. 5.1.22)

Die Versionsnummern, die an der zweiten Stelle eine ungerade Zahl haben, sind Entwicklungsversionen (z. B. 5.1.22). Alle anderen sind stabile Versionen (z. B. 5.0.2).

Die Voreinstellung ist immer die neueste Entwicklungsversion.

### `/v0/publish`

Übergebe per POST ein JSON-Objekt nach `+https://api.speedata.de/v0/publish+`, um den Publishing-Prozess zu starten.

```json
{
    "files": [
        {
            "filename": "layout.xml",
            "contents": "PExheW91dAog..."
        },
        {
            "filename": "data.xml",
            "contents": "PGRhdGE+CiAg..."
        }
    ]
}
```

Der Dateiinhalt ist mit base64 kodiert.

Die Antwort im Erfolgsfall ist eine Sitzungs-ID, zum Beispiel 340416874, die als JSON-Objekt kodiert ist: `{"id":"340416874"}`. Der Rückgabewert ist 201.

Als Query-Parameter `version` kann eine Versionsnummer (oder der String `latest`) übergeben werden, der die gewünschte speedata Publisher Version angibt. Die Voreinstellung ist immer die neuste Entwicklerversion. Beispiel: `/v0/publish?version=1.2.43`

### `/v0/status/<id>`

Den Status eines PDF-Laufs abrufen. Die Rückgabe ist eine JSON-Datei mit dem folgenden Aufbau:

| Feld | Bedeutung |
| --- | --- |
| finished | Ein Zeitstempel im Format `2019-12-05T13:27:29.450219694+01:00`, sofern der Lauf beendet ist, ansonsten die Zeichenkette `null`. |
| errors | Die Anzahl der Fehler aus dem Publishing-Lauf. |
| errormessages | Ein Array mit Fehlermeldungen, falls vorhanden. Eine Fehlermeldung ist ein Dictionary mit dem Code als Schlüssel und der Meldung als Wert. Siehe das Beispiel. |


```json
{
    "finished": "2019-12-05T13:38:42.855821194+01:00",
    "errors": 1,
    "errormessages": [
        {
            "code": 1,
            "error": "[page 1] Image \"doesnotexist.pdf\" not found!"
        }
    ]
}
```

### `/v0/wait/<id>`

Das Ergebnis ist dasselbe wie in `/v0/status`. Um auf die Fertigstellung des PDFs zu warten, kann man auch `/v0/pdf/<id>` aufrufen.

### `/v0/pdf/<id>`

Führe einen Request auf `+https://api.speedata.de/v0/pdf/<id>+` aus und ersetze die `<id> mit der ID aus `/v0/publish`.

## HTTP Status codes

| Statuscode | Bedeutung |
| --- | --- |
| 200 | Alles gut gelaufen |
| 201 | Der angeforderte Publishing-Lauf wurde gestartet |
| 401 | Nicht autorisiert: der API-Schlüssel ist falsch |
| 404 | API URL existiert nicht |
| 422 | Etwas ist falsch gelaufen |


In den meisten Fehlerfällen wird ein JSON Objekt nach RFC 7807 gesendet mit den folgenden Feldern:

| Feld | Bedeutung |
| --- | --- |
| type | Eine eindeutige URI des Fehlers |
| title | Kurzbeschreibung |
| detail | Eine detaillierte Beschreibung des Problems |
| instance | Der Request-Pfad |
| requestid | Eine eindeutige ID für die Fehlersuche |


Beispiel:

```json
{
    "detail":"You have provided an incorrect authentication token",
    "instance":"/v0/publish",
    "title":"Not authorized",
    "type":"urn:de:speedata:api:v0:unauthorized",
    "requestid": "1234",
}
```

## Bibliothek für die Programmiersprache Go

Die API ist bewusst klein gehalten, damit Anwendungen schnell erstellt werden
können, die die API benutzen. Für die Programmiersprache Go gibt es eine
Bibliothek, die den Umgang mit der API erleichtert.

Die Dokumentation ist auf [Go dev](https://pkg.go.dev/github.com/speedata/publisher-api) zu finden, das Repository liegt auf GitHub unter https://github.com/speedata/publisher-api.

