---
title: "Tabelle, Gruppen oder Textfluss?"
weight: 12
type: docs
---

Steht fest, wie die Daten aussehen (siehe [Datenaufbereitung]({{< relref "datapreparation" >}})), folgt die zentrale Darstellungsentscheidung: Auf welchem Weg kommt der Inhalt auf die Seite? Der Publisher kennt drei Grundformen, und die meisten Layoutprobleme entstehen, wenn man mit der falschen anfängt.

## Tabelle

Die Tabelle ordnet Inhalte in Zeilen und Spalten: Alle Datensätze richten sich an denselben Spalten aus, der Umbruch über Seiten geschieht [automatisch und zeilenweise]({{< relref "simpletable" >}}), Kopf und Fuß wiederholen sich. Die Zellen sind rechteckige Kästchen, die nie in sich umbrechen.

Typische Anwendungen: Artikellisten, Preislisten, technische Datentabellen; alles, wo viele gleichförmige Datensätze untereinander stehen. Details im Handbuchkapitel [Tabellen]({{< relref "/manual/tables" >}}).

## Gruppen und absolute Positionierung

Eine [Gruppe]({{< relref "groups" >}}) ist ein virtueller Bereich, der zunächst unsichtbar zusammengebaut wird. Danach kann man ihn mit `sd:group-height()` und `sd:group-width()` messen und entscheiden, wo (und ob) er auf die Seite kommt: das Muster »erst messen, dann platzieren«. Zusammen mit absoluter Positionierung (feste Koordinaten oder Rasterplätze bei `<PlaceObject>`) ist das der Weg für Seiten, deren Design fix ist und in das sich der Inhalt fügen muss.

Typische Anwendungen: Datenblätter mit festem Seitenaufbau, Kataloge aus Modulbausteinen variabler Höhe, bei denen vor jedem Baustein geprüft wird, ob er noch auf die Seite passt.

## Textfluss

Fließtext gehört weder in eine Tabelle noch in eine Gruppe, sondern in `<Output>`/`<Text>`: Absätze fließen über Seiten und Platzierungsbereiche, der Umbruch geschieht an Zeilengrenzen, Bilder können [umflossen werden]({{< relref "wrappingaroundobjects" >}}). Der Einstieg dazu steht im Abschnitt [Objekte ausgeben]({{< relref "outputtingobjects" >}}).

Typische Anwendungen: längere Beschreibungen, redaktionelle Teile, alles Absatzförmige.

## Leitfragen

* **Müssen Inhalte über Datensätze hinweg an Spalten ausgerichtet werden?** Dann Tabelle; mit Gruppen bekommt man Spaltenflucht nur mühsam von Hand hin.
* **Ist das Design fix und jede Position steht fest?** Dann Gruppen und absolute Positionierung; eine Tabelle würde gegen das Design kämpfen.
* **Muss vor dem Platzieren gemessen werden** (»passt der nächste Baustein noch auf diese Seite?«)? Dann Gruppen.
* **Fließt der Inhalt als Text über Seiten** oder soll er Bilder umfließen? Dann `<Output>`/`<Text>`.
* **Ist die Liste lang und die Zeilen gleichförmig?** Dann die Tabelle mit automatischem Umbruch, siehe das [Rezept dazu]({{< relref "simpletable" >}}).

Die Formen schließen sich nicht aus, im Gegenteil: In Tabellenzellen können Bilder und Absätze stehen, Gruppen enthalten oft Tabellen (zum Messen einer Tabelle, bevor sie platziert wird), und ein Textfluss kann zwischen den Absätzen Tabellen führen. Die Entscheidung betrifft die äußerste Form je Inhaltsblock, nicht das ganze Dokument.

<!-- TODO PG: Praxisbeispiele ergänzen – z. B. ein konkreter Fall, wo Tabelle vs. Gruppen falsch gewählt wurde und was das gekostet hat; typische Katalogseite als Mischform. Später mit dem Backlog-Rezept »eine Artikelgruppe, dreimal umgesetzt« verlinken. -->

## Entscheidungstabelle

| Wenn … | dann … |
|---|---|
| Inhalte sollen über Datensätze hinweg an Spalten ausgerichtet sein | Tabelle |
| lange, gleichförmige Liste mit automatischem Seitenumbruch | Tabelle ([Rezept]({{< relref "simpletable" >}})) |
| festes Seitendesign, exakte Positionen | Gruppen und absolute Positionierung |
| vor dem Platzieren messen (»passt das noch?«) | Gruppen ([Handbuch]({{< relref "groups" >}})) |
| Fließtext über mehrere Seiten oder Bereiche | `<Output>`/`<Text>` |
| Text soll Bilder umfließen | `<Output>`/`<Text>` ([Handbuch]({{< relref "wrappingaroundobjects" >}})) |
