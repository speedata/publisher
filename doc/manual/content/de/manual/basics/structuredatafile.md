---
title: "Struktur der Datendatei"
weight: 31
type: docs
---


<blockquote class="quote">
Sie können jedes Datenformat benutzen, solange es XML ist.
<cite>– Frei nach Henry Ford</cite>
</blockquote>

## Datenquelle: XML – wohlgeformt und strukturiert

Die erste Voraussetzung ist, dass die Datenquelle im XML-Format (Extensible Markup Language) vorliegt.
Andere Formate werden mit dem Publisher nicht verarbeitet (mithilfe des [Lua Filters]({{< relref "preprocessing" >}}) können auch CSV- und Excel-Dateien  verarbeitet werden).
In der Praxis spielt das keine Rolle, weil alle (strukturierten) Daten in das XML-Format  konvertiert werden können.

Häufig wird gefragt, wie denn das Daten-XML aufgebaut sein muss.
Die Antwort darauf ist einfach: es gibt keine Vorgaben, außer dass das XML den üblichen Regeln entsprechen muss (Wohlgeformtheit).
Diese Regeln dafür stehen im [Glossar]({{< relref "glossary" >}}).

Daneben gibt es sinnvolle Strukturierungsempfehlungen:

1. Die Daten sollen dann im XML-Baum vorkommen, wenn sie benötigt werden.
Datenverarbeitung im Publisher kostet Zeit und Speicher, so dass die
Informationen dort vorhanden sein sollten, wo sie benötigt werden. Es gibt
natürlich Ausnahmen. Beispielsweise können globale Einstellungen (Farben, zu
übersetzende Texte und so weiter) am Anfang der Datei definiert werden.

2. Unterschiedliche Darstellungen (Varianten) müssen anhand der Daten ablesbar
sein. Wenn z. B. ein Seitenwechsel bei einer neuen Artikelgruppe (im
Produktkatalog) passieren soll, muss in den Daten ein Wechsel der
Artikelgruppe erkennbar sein.

3. Die Daten sollten möglichst strukturiert sein.
Ein Produktkatalog könnte z. B. Artikelnummer der Form 123-12345 enthalten.
Wenn dabei die ersten drei Ziffern die Artikelgruppe darstellen, könnte dies gegebenenfalls mit Regulären Ausdrücken erkannt werden.
Einfacher ist es, wenn die Artikelgruppe bereits in der Datenstruktur angelegt ist, so dass es keiner Erkennung bedarf.

Ein einfaches Beispiel für die Anordnung:

```xml
<productdata>
  <globalsettings>
    ...
  </globalsettings>
  <articlegroup name="interior lights" number="123">
    <article number="123-12345">
      <property1>...</property1>
      <property2>...</property2>
    </article>
    <article number="123-12346">
      <property1>...</property1>
      <property2>...</property2>
    </article>
  </articlegroup>
  <articlegroup name="exterior lights" number="124">
    <article number="124-23456">
      <property1>...</property1>
      <property2>...</property2>
    </article>
    <article number="124-54321">
      <property1>...</property1>
      <property2>...</property2>
    </article>
  </articlegroup>
</productdata>
```

Redundanz schadet hier nicht, im Gegenteil.
Da im Beispiel die Artikelgruppe eine eindeutige Ziffernfolge (123 bzw. 124) hat, würde bei den Artikeln die letzten fünf Ziffern ausreichen.
Man kann ja die Zahl aus `articlegroup/@number`, `-` und `article/@number` selbst zusammenbauen.
Um sich den Schritt zu sparen, speichert man am Artikel einfach die vollständige Nummer.

Um es zusammenzufassen: Wenn Sie die Möglichkeit haben, auf die Strukturierung der Daten Einfluss zu nehmen: speichern Sie lieber zu viele Informationen, als zu wenige.
Experimentieren Sie mit der Reihenfolge der Daten, manchmal erleichtert einem die richtige Struktur die Layouterstellung enorm.

## Wie greift man vom Layout auf die Daten zu?

Die Verarbeitung der Datendatei ist Aufgabe des Layouts: `<Record>` definiert Verarbeitungsregeln für die Datenelemente, `<ProcessNode>` und `<ForAll>` steigen in die Kindelemente hinab, und mit XPath-Ausdrücken wie `@nr` oder `description` greift man auf Attribute und Kindelemente des aktuellen Elements zu.
Das Zusammenspiel beschreibt Schritt für Schritt das Kapitel [Programmierung]({{< relref "programming" >}}), die Ausdrücke selbst erklärt die [XPath-Referenz]({{< relref "/reference/xpath/xpath" >}}).
