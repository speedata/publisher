---
title: "speedata Publisher Pro"
weight: 110
type: docs
---


Der speedata Publisher ist in zwei Paketen erhältlich: Standard und Pro. Das Pro-Paket enthält Features, die für professionelle Anwendungen hilfreich sind:

* Support per E-Mail
* [Servermodus]({{< relref "servermode" >}}) (REST-API für lokale Netzwerke)
* [Publisher über Hotfolder starten]({{< relref "hotfolder" >}}) (für den vollautomatischen Start des Publishers)
* [QR-Codes und Barcodes]({{< relref "/reference/barcode" >}})
* Einbinden von ZUGFeRD Rechnungen
* Einbinden von Ressourcen über HTTP(s), z.B. für Mediendatenbanken
* [Beschnittzugabe]({{< relref "cutmarks" >}}) (bleed)

Ebenso im Pro-Paket enthalten ist der Zugriff auf den [speedata Webservice]({{< relref "saasapi" >}}), der die Benutzung des Publishers ohne lokale Installation ermöglicht.

Ein Vergleich von speedata Standard und Pro ist [auf der Produktseite](https://www.speedata.de/de/produkt/preise/) zu finden.

## Wie bekomme ich das Pro Paket?

1. Unter https://download.speedata.de/register kann man einen Account im Downloadbereich erstellen
2. Nach erfolgreicher Registrierung muss man das passende Paket auswählen (monatliche / jährliche Zahlweise)

Um das Pro-Paket herunterzuladen, gibt es zwei Möglichkeiten (ein gültiges Abonnement des Pro-Pakets vorausgesetzt):

1. Ist man im Downloadbereich angemeldet, dann kann man über die Download-Links die ZIP-Dateien oder die Installationspakete herunterladen.

2. Per Kommandozeile (z.B. wget oder curl) kann man die Pakete herunterladen. Dafür muss im Login Bereich ein Token erzeugt werden und als Authentifizierung mit übergeben werden:
    ```shell
    curl -u sdapi_....:  \
      -O https://download.speedata.de/dl/speedata-publisherpro-linux-amd64-latest.zip
    ```
    oder per wget:
    ```shell
    wget --auth-no-challenge  --user sdapi_...  \
       --password ""  https://download.speedata.de/dl/speedata-publisherpro-linux-amd64-latest.zip
    ```

Die Standardpakete können wie gehabt ohne Login oder Token heruntergeladen werden.

## Überprüfen der Version

Auf der Kommandozeile kann man mit

```shell
sp --version
```

überprüfen, ob die Pro-Version installiert ist. Die Ausgabe ist dann beispielsweise

```
Version: 4.11.8 (Pro)
```

