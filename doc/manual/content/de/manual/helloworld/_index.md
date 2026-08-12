---
title: "Hallo Welt!"
weight: 20
type: docs
---


Der Klassiker: »Hallo Welt!«.
Oder: wie sieht ein einfaches Dokument aus?

Die Eingabe für den Publisher besteht immer aus zwei Dateien: einer **Datendatei** (`data.xml`) mit den Inhalten und einer **Layoutdatei** (`layout.xml`) mit den Regeln, wie diese Inhalte im PDF erscheinen sollen.
Beide müssen im XML-Format vorliegen.
Am besten erstellt man sie mit einem XML-Editor oder dem kostenfreien Editor [Visual Studio Code](https://code.visualstudio.com/).

{{< callout >}}
Wer das »Hallo Welt« Beispiel sofort ausprobieren möchte: `sp new helloworld` erstellt ein Verzeichnis mit den beiden Dateien. Mit `cd helloworld` und `sp` wird daraus ein PDF.
{{< /callout >}}

![Hello World Beispiel auf der Kommandozeile](/img/helloworld.gif)

## Die beiden Dateien

Die Datendatei (`data.xml`) enthält die Daten – hier nur ein kurzer Text:

```xml
<data>Hello world!</data>
```

Die Layoutdatei (`layout.xml`) beschreibt, was mit den Daten passieren soll:

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value select="."/>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

## PDF erzeugen

Beide Dateien in einem leeren Verzeichnis speichern, auf der Kommandozeile in dieses Verzeichnis wechseln und den Publisher starten:

```shell
$ sp
```

Das `$`-Zeichen steht für den Prompt und wird nicht mit eingegeben.
Das Ergebnis ist eine PDF-Datei `publisher.pdf` mit einer Seite: der Text »Hello world!« oben links.

{{< callout >}}
Für Windows-Benutzer: wenn der Publisher das PDF nicht erzeugen kann, liegt das manchmal daran, dass dieselbe Datei noch in einem anderen Programm geöffnet ist (Adobe Reader, Windows Explorer).
{{< /callout >}}


## Das Beispiel erläutert

Die Datendatei kann beliebig strukturiert sein, solange der Inhalt wohlgeformtes XML ist (siehe [Glossar]({{< relref "glossary" >}})).
In diesem Fall gibt es nur ein Element `<data>` mit dem Textinhalt `Hello world!`.

Die Layoutdatei Schritt für Schritt:

```xml
<Layout                                              <!--1-->
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">                            <!--2-->
    <PlaceObject>                                     <!--3-->
      <Textblock>
        <Paragraph>
          <Value select="."/>                         <!--4-->
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```
1. Das Wurzelelement `Layout` mit den beiden Namensräumen. Den zweiten Namensraum (`sd:`) braucht man hier noch nicht, aber er sollte immer angegeben werden – er wird für die eingebauten Funktionen benötigt.
2. `Record` definiert, was passieren soll, wenn der Publisher das Element `<data>` in der Datendatei findet. Da `<data>` das Wurzelelement ist, wird dieser Record automatisch beim Start aufgerufen.
3. `PlaceObject` ist der Befehl, um etwas in das PDF auszugeben – Text, Bilder, Tabellen, Boxen usw.
4. `select="."` ist ein XPath-Ausdruck: der Punkt `.` bedeutet »das aktuelle Datenelement«. Hier ist das aktuelle Element `<data>`, und dessen Textinhalt ist `Hello world!`. Genau dieser Text erscheint im PDF.

## Wie geht es weiter?

Im Kapitel [Programmierung]({{< relref "programming" >}}) wird ausführlich erklärt, wie Layout und Daten zusammenspielen – insbesondere das Zusammenspiel von `Record` und `ProcessNode`, mit dem auch verschachtelte Datenstrukturen verarbeitet werden können.
