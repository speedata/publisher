---
title: "Anleitungen"
weight: 15
type: docs
---

Während das [Handbuch]({{< relref "/manual" >}}) die Konzepte erklärt und die [Referenz]({{< relref "/reference" >}}) zum Nachschlagen dient, führen die Anleitungen zum fertigen Ergebnis: Jedes Rezept löst eine konkrete Aufgabe aus der Praxis, mit lauffähigem Layout und Daten zum Nachbauen.

Die Rezepte enthalten dabei nicht nur Schrittfolgen, sondern auch das Entscheidungswissen dahinter. Jedes Rezept folgt demselben Aufbau:

* **Aufgabe**: was entstehen soll, mit einer Abbildung des Ziels.
* **Entscheidung**: welche Wege es gibt und woran man den richtigen erkennt.
* **Lösung**: der Weg zum Ergebnis, Schritt für Schritt.
* **Grenzen**: wann dieser Weg nicht mehr trägt und was dann.

Alle Rezepte verwenden denselben fiktiven Datenbestand: die Artikeldaten von »Confixa«, einem erfundenen Hersteller von Verbindungstechnik (Schrauben, Dübel, Anker). Die Daten werden im ersten Rezept eingeführt und wachsen mit den Aufgaben.

## Entscheidungshilfen

Zwei Fragen stellen sich in jedem Projekt, noch bevor das erste Rezept zum Einsatz kommt:

{{< cards >}}
  {{< card link="datapreparation" title="Datenaufbereitung" subtitle="Vorweg transformieren oder im Layout verarbeiten?" >}}
  {{< card link="tableorgroups" title="Tabelle, Gruppen oder Textfluss?" subtitle="Die zentrale Darstellungsentscheidung" >}}
{{< /cards >}}

## Tabellen

{{< cards >}}
  {{< card link="simpletable" title="Einfache Tabelle mit automatischem Umbruch" subtitle="Artikelliste mit wiederholtem Tabellenkopf über mehrere Seiten" >}}
  {{< card link="columnwidths" title="Spaltenbreiten steuern" subtitle="Feste Breiten, Sternangaben und Mischformen" >}}
  {{< card link="continuationhead" title="Fortsetzungskopf und Fortsetzungshinweis" subtitle="Kopf und Fuß je Seite variieren" >}}
  {{< card link="manualtablebreak" title="Komplexe Tabellen manuell umbrechen" subtitle="Portionieren und Messen für Fortsetzungsseiten mit eigener Logik" >}}
{{< /cards >}}

## Seitengerüst

{{< cards >}}
  {{< card link="datasheet" title="Grundgerüst eines Datenblatts" subtitle="Seitentyp mit Kopf, Fuß und Satzspiegel, millimetergenau" >}}
{{< /cards >}}

## Verzeichnisse

{{< cards >}}
  {{< card link="tableofcontents" title="Inhaltsverzeichnis" subtitle="Seitenzahlen sammeln und im nächsten Durchlauf ausgeben" >}}
  {{< card link="keywordindex" title="Stichwortverzeichnis" subtitle="Sortieren und Gruppieren mit Makeindex, Seitenzahlen zusammenfassen" >}}
{{< /cards >}}

Weitere Rezepte folgen.
