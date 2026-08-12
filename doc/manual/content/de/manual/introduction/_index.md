---
title: "Einführung"
weight: 10
type: docs
---

Der speedata Publisher erzeugt vollautomatisch PDF-Dateien aus XML-Daten.
Die Layoutanweisungen liegen getrennt von den Daten vor und sind in einer speziell dafür entwickelten Programmiersprache formuliert.

![Aus XML-Daten und Layoutregeln erzeugt der Publisher ein PDF](/img/xmltopdf.svg)

## Typische Anwendungen

* Produktkataloge
* Preislisten und Datenblätter
* Reiseführer und Verzeichnisse
* Rechnungen und Geschäftsdokumente

Überall dort, wo Dokumente reproduzierbar, schnell und in hoher Qualität aus strukturierten Daten erzeugt werden sollen.

## Was den Publisher besonders macht

**Programmierbare Layouts:** Anders als bei Template-basierten Systemen können Layoutentscheidungen während der PDF-Erzeugung getroffen werden. Abfragen wie »Passt dieses Bild noch auf die Seite?« oder »Wie breit ist der verbleibende Platz?« sind jederzeit möglich.

**Keine GUI, volle Kontrolle:** Der Publisher ist ein Kommandozeilen-Werkzeug ohne graphische Oberfläche. Alle Anweisungen werden vor dem Lauf festgelegt. Das macht den Prozess reproduzierbar und automatisierbar – ideal für die Einbindung in bestehende Workflows und CI/CD-Pipelines.

**Typographische Qualität:** Der Publisher nutzt die gleiche Satztechnologie wie TeX/LaTeX (LuaTeX) und erreicht damit eine Ausgabequalität, die sonst nur interaktiven DTP-Programmen wie InDesign vorbehalten ist.

## Loslegen

```shell
$ sp new helloworld
$ cd helloworld
$ sp
```

Drei Befehle, und Sie haben Ihr erstes PDF. Eine ausführliche Erklärung finden Sie im Kapitel [Hallo Welt!]({{< relref "helloworld" >}}), Installation und Konfiguration unter [Erste Schritte]({{< relref "setup" >}}).

## Beispiele

Im [speedata Showcase](https://www.speedata.de/de/#showcase) finden Sie Beispiele für reale Dokumente.
Auf GitHub gibt es ein [Beispiel-Repository](https://github.com/speedata/examples) mit vollständigen, lauffähigen Projekten zum Ausprobieren.

![Beispiele aus dem Repository](/img/beispiele.png)
