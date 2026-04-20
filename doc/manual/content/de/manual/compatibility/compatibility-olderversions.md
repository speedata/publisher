---
title: "Kompatibilität mit älteren Versionen"
weight: 230
type: docs
---


Die Entwicklung des speedata Publishers hat ein großes »Mantra«: Bestehende Setups müssen ohne Änderung mit neueren Versionen des speedata Publishers funktionieren. Sie können also immer auf die neueste Version aktualisieren, ohne befürchten zu müssen, dass Sie Ihre Layout-Datei ändern müssen.

Neue Funktionen werden über neue XML-Tags oder Attribute eingeführt.
Bestehende Layoutdateien ignorieren diese einfach und funktionieren weiterhin.

## Legacy-Optionen

Seit Version 5 sind der XPath-Parser `lxpath` und der Fontloader `harfbuzz` die Voreinstellung.
Die älteren Varianten (`luxor` und `fontforge`) sind weiterhin verfügbar, werden aber nicht mehr empfohlen.
Falls ein bestehendes Layout eine der alten Varianten benötigt, kann diese über die [Konfigurationsdatei]({{< relref "configuration" >}}) aktiviert werden.

Bekannte Unterschiede der alten Varianten:

- `fontforge`: Unterstützt virtuelle Fonts, mit denen bestimmte Fontfeatures simuliert werden können.
- `luxor`: Kann mit Dimensionen rechnen (z.B. `"2cm + 12mm"`), was nicht der XPath-Spezifikation entspricht, aber in einigen älteren Layouts verwendet wird.

## Anforderungen in der Layoutdatei festlegen

Mit dem Attribut `require` im Befehl [`<Layout>`]({{< relref "/reference/layout" >}}) kann sichergestellt werden, dass eine bestimmte Konfiguration aktiv ist.
Das ist nützlich, wenn Layoutdateien zwischen verschiedenen Installationen ausgetauscht werden:

```xml
<Layout
    xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en"
    require="lxpath,harfbuzz">
```

Die verfügbaren Optionen sind:

| Schlüsselwort | Beschreibung |
| --- | --- |
| `lxpath` | Stellt sicher, dass der XPath-Parser `lxpath` benutzt wird (Standard seit v5). |
| `harfbuzz` | Stellt sicher, dass der Fontloader `harfbuzz` benutzt wird (Standard seit v5). |
| `luxor` | Erzwingt den alten XPath-Parser. |
| `fontforge` | Erzwingt den alten Fontloader. |
