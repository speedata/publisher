---
title: "Erstellung von XML-Strukturen"
weight: 47
type: docs
---


Der speedata Publisher kann XML-Dateien erzeugen, speichern und wieder einlesen.
Damit kann man Inhaltsverzeichnisse, Querverweise und weitere andere Anwendungen realisieren.

Die XML-Struktur wird nicht direkt, sondern indirekt über die beiden Befehle  [`<Element>`]({{< relref "/reference/element" >}}) und [`<Attributes>`]({{< relref "/reference/attribute" >}}) erzeugt.
So kann die folgende XML-Datei

```xml
<Root>
   <Greeting content="Hello, world!" />
</Root>
```

aus dieser Struktur im Layoutregelwerk erzeugt werden:

```xml
<Element name="Root">
  <Element name="Greeting">
    <Attribute name="content" select="'Hello, world!'"/>
  </Element>
</Element>
```

Textinhalte außerhalb von Attributen, wie z. B. mixed content, können mit dem Publisher nicht ausgegeben werden.

Ein ausführliches Beispiel ist in [Verzeichnisse erstellen (XML-Struktur)]({{< relref "directoriesxml" >}}) gezeigt.

