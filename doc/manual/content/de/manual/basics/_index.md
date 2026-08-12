---
title: Grundlagen
weight: 40
type: docs
---

Das Studium dieses Kapitels sollte ausreichen, um Layoutregelwerke selbständig zu erstellen. Gelegentlich werden weiterführende Themen in einem späteren Kapitel vertieft. Beispielsweise werden für Tabellen nur die wichtigsten Formatierungen behandelt, ein eigenes Kapitel ([Tabellen]({{< relref "tables" >}})) beschreibt Tabellen im Detail. In solchen Fällen gibt es natürlich einen Querverweis.

{{< callout >}}
Noch ein Hinweis für das Handbuch. Viele Beispiele zeigen nur die Layout-Datei und nicht die dazugehörigen Daten. Es wird in der Datendatei dann immer die einfache Struktur `<data />` vorausgesetzt. Zu erkennen ist das daran, dass im Layout `<Record element="data">` enthalten ist. Am einfachsten ist es, den Publisher mit `sp --dummy` zu starten, das simuliert diese Datendatei.
{{< /callout >}}

{{< cards >}}
  {{< card link="structuredatafile" title="Datenstruktur" subtitle="Aufbau und Strukturierung der Datendatei" >}}
  {{< card link="outputtingobjects" title="Objekte ausgeben" subtitle="Text, Bilder, Boxen, Barcodes und mehr" >}}
  {{< card link="fileorganization" title="Dateiorganisation" subtitle="Wie der Publisher Dateien findet" >}}
  {{< card link="grid" title="Raster" subtitle="Das Seitenraster und Objektplatzierung" >}}
  {{< card link="pagetypes" title="Seitentypen" subtitle="Verschiedene Seitenvorlagen definieren" >}}
  {{< card link="programming" title="Programmierung" subtitle="Variablen, Bedingungen, Schleifen und Funktionen" >}}
  {{< card link="positioningframe" title="Platzierungsbereiche" subtitle="Bereiche und Rahmen auf der Seite" >}}
{{< /cards >}}
