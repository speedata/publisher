---
title: speedata Publisher Dokumentation
type: docs
---

Vollautomatisch PDF-Dateien aus XML-Daten erzeugen – mit programmierbaren Layouts, typographischer Qualität und voller Kontrolle über jedes Detail.

Der Publisher liest zwei XML-Dateien – die Daten und die Layoutregeln – und erzeugt daraus ein PDF.
Sobald er [installiert]({{< relref "manual/setup" >}}) ist, entsteht das erste PDF mit drei Befehlen:

```shell
sp new helloworld   # Beispielprojekt mit Daten- und Layoutdatei anlegen
cd helloworld
sp                  # PDF erzeugen – das Ergebnis heißt publisher.pdf
```

Wie die beiden Dateien zusammenspielen, zeigt Schritt für Schritt das Kapitel [Hallo Welt!]({{< relref "manual/helloworld" >}}).

## Einstieg

{{< cards >}}
  {{< card link="manual/introduction" title="Einführung" subtitle="Was der Publisher kann und wofür er eingesetzt wird" >}}
  {{< card link="manual/helloworld" title="Hallo Welt!" subtitle="In drei Befehlen zum ersten PDF" >}}
  {{< card link="manual/setup" title="Installation & Setup" subtitle="Installation, XML-Editor und Schema-Validierung" >}}
{{< /cards >}}

## Themen

{{< cards >}}
  {{< card link="manual/basics" title="Grundlagen" subtitle="Raster, Seitentypen, Positionierung und Datenverarbeitung" >}}
  {{< card link="manual/text" title="Text & Schriften" subtitle="Textformatierung, Schrifteinbindung und Silbentrennung" >}}
  {{< card link="manual/imagesandgraphics" title="Bilder & Grafiken" subtitle="Bilder einbinden, skalieren und positionieren" >}}
  {{< card link="manual/tables" title="Tabellen" subtitle="Flexible Tabellen mit dem HTML-ähnlichen Modell" >}}
  {{< card link="manual/pagelayout" title="Seitenlayout" subtitle="Gruppen, virtuelle Seiten und Beschnittmarken" >}}
  {{< card link="manual/colors" title="Farben" subtitle="Farben definieren und verwenden" >}}
{{< /cards >}}

## Fortgeschritten

{{< cards >}}
  {{< card link="manual/webformats" title="Webformate" subtitle="HTML, CSS und Markdown im Publisher verwenden" >}}
  {{< card link="manual/directories" title="Verzeichnisse" subtitle="Inhaltsverzeichnis, Index, Lesezeichen und Marker" >}}
  {{< card link="manual/integration" title="Integration" subtitle="Lua-Filter, Servermodus, SaaS-API und Barrierefreiheit" >}}
  {{< card link="manual/quality" title="Qualität & Fehlersuche" subtitle="Troubleshooting, Performance und Qualitätssicherung" >}}
{{< /cards >}}

## Anleitungen

{{< cards >}}
  {{< card link="howto" title="Anleitungen" subtitle="Aufgabenorientierte Rezepte mit Entscheidungswissen" >}}
  {{< card link="howto/datapreparation" title="Datenaufbereitung" subtitle="Vorweg transformieren oder im Layout verarbeiten?" >}}
  {{< card link="howto/tableorgroups" title="Tabelle, Gruppen oder Textfluss?" subtitle="Die zentrale Darstellungsentscheidung" >}}
  {{< card link="howto/simpletable" title="Tabelle mit automatischem Umbruch" subtitle="Artikelliste mit wiederholtem Tabellenkopf" >}}
  {{< card link="howto/columnwidths" title="Spaltenbreiten steuern" subtitle="Feste Breiten, Sternangaben und Mischformen" >}}
  {{< card link="howto/continuationhead" title="Fortsetzungskopf und -hinweis" subtitle="Kopf und Fuß je Seite variieren" >}}
  {{< card link="howto/manualtablebreak" title="Tabellen manuell umbrechen" subtitle="Portionieren und Messen für eigene Umbruchlogik" >}}
  {{< card link="howto/datasheet" title="Grundgerüst eines Datenblatts" subtitle="Seitentyp mit Kopf, Fuß und Satzspiegel" >}}
  {{< card link="howto/tableofcontents" title="Inhaltsverzeichnis" subtitle="Seitenzahlen sammeln, im nächsten Durchlauf ausgeben" >}}
  {{< card link="howto/keywordindex" title="Stichwortverzeichnis" subtitle="Sortieren und Gruppieren mit Makeindex" >}}
{{< /cards >}}

## Referenz

{{< cards >}}
  {{< card link="reference/commands" title="Befehlsreferenz" subtitle="Alle Befehle und Attribute im Überblick" >}}
  {{< card link="reference/xpath" title="XPath & Layoutfunktionen" subtitle="XPath-Ausdrücke und sd:-Funktionen" >}}
  {{< card link="reference/commandline" title="Kommandozeile" subtitle="Alle Optionen von sp im Detail" >}}
  {{< card link="reference/configuration" title="Konfiguration" subtitle="Konfigurationsdatei und Umgebungsvariablen" >}}
  {{< card link="reference/glossary" title="Glossar" subtitle="Begriffe und Definitionen" >}}
  {{< card link="reference/appendix" title="Anhang" subtitle="Voreinstellungen, Dateinamen, interne Variablen" >}}
{{< /cards >}}
