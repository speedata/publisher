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
Die älteren Varianten (`luxor` und `fontforge`) sind veraltet (deprecated) und sollen mit Version 6.0 entfernt werden.
Falls ein bestehendes Layout eine der alten Varianten benötigt, kann diese übergangsweise über die [Konfigurationsdatei]({{< relref "configuration" >}}) aktiviert werden.

Bekannte Unterschiede der alten Varianten:

- `fontforge`: Unterstützt virtuelle Fonts, mit denen bestimmte Fontfeatures simuliert werden können.
- `luxor`: Kann mit Dimensionen rechnen (z.B. `"2cm + 12mm"`), was nicht der XPath-Spezifikation entspricht, aber in einigen älteren Layouts verwendet wird.

### Umstieg auf lxpath und harfbuzz

Wer eine der alten Varianten noch nutzt, sollte vor Version 6.0 umstellen:

- `luxor`: Das Layout mit der Voreinstellung `lxpath` laufen lassen und die gemeldeten Fehler beheben. Rechenausdrücke mit Maßeinheiten (z.B. `"2cm + 12mm"`) lassen sich mit der Funktion [`sd:dimexpr()`]({{< relref "layoutfunctions" >}}) nachbilden.
- `fontforge`: Den Schlüssel `fontloader` aus der Konfigurationsdatei bzw. das Attribut `mode="fontforge"` bei `<LoadFontfile>` entfernen; die Schriften werden dann mit `harfbuzz` geladen. Type-1-Schriften (`.pfb`) funktionieren nur mit fontforge und sollten nach OpenType konvertiert werden.

## Anforderungen in der Layoutdatei festlegen

Mit dem Attribut `require` im Befehl [`<Layout>`]({{< relref "/reference/commands/layout" >}}) kann sichergestellt werden, dass eine bestimmte Konfiguration aktiv ist.
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
| `luxor` | Erzwingt den alten XPath-Parser (veraltet). |
| `fontforge` | Erzwingt den alten Fontloader (veraltet). |
