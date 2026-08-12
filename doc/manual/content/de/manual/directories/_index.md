---
title: "Verzeichnisse & Listen"
weight: 75
type: docs
---

Erstellen von Verzeichnissen, Registern, Lesezeichen und anderen Navigationshilfen.

Für Inhaltsverzeichnisse und ähnliche Listen gibt es drei Verfahren, die sich in Aufwand und Flexibilität unterscheiden:

| Verfahren | Funktionsweise | Durchläufe | Geeignet, wenn … |
|---|---|---|---|
| [Marken]({{< relref "directoriesmarker" >}}) | `<Mark>` markiert Stellen im Text, `sd:pagenumber()` liefert die Seitenzahl; das Speichern übernimmt der Publisher | 2 | nur Seitenzahlen zu bekannten Namen gebraucht werden |
| [XML-Datensatz]({{< relref "directoriesxml" >}}) | Einträge werden selbst gesammelt, mit `<SaveDataset>` gespeichert und im nächsten Durchlauf verarbeitet | 2 bis 3 | das Verzeichnis eigene Strukturen oder Zusatzinformationen braucht (z. B. Artikellisten) |
| [Ein Durchlauf]({{< relref "tocinonerun" >}}) | Seiten werden mit `<InsertPages>` reserviert und am Ende mit `<SavePages>` erzeugt | 1 | die Länge des Verzeichnisses vorab bekannt ist |

{{< cards >}}
  {{< card link="directoriesmarker" title="Marken" subtitle="Seitenmarken für Kolumnentitel und Verzeichnisse" >}}
  {{< card link="directoriesxml" title="Listen erstellen" subtitle="XML-Strukturen für Verzeichnisse aufbauen" >}}
  {{< card link="tocinonerun" title="Inhaltsverzeichnis" subtitle="Inhaltsverzeichnis in einem Durchlauf" >}}
  {{< card link="indexcreation" title="Sortieren und Gruppieren" subtitle="Daten sortieren, Stichwortverzeichnisse mit Makeindex" >}}
  {{< card link="bookmarks" title="Lesezeichen" subtitle="PDF-Lesezeichen erzeugen" >}}
{{< /cards >}}
