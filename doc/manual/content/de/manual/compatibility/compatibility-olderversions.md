---
title: "Kompatibilität mit älteren Versionen"
weight: 230
type: docs
---


Die Entwicklung des speedata Publishers hat ein großes »Mantra«: Bestehende Setups müssen ohne Änderung mit neueren Versionen des speedata Publishers funktionieren. Sie können also immer auf die neueste Version aktualisieren, ohne befürchten zu müssen, dass Sie Ihre Layout-Datei ändern müssen.

Neue Funktionen werden über neue XML-Tags oder Attribute eingeführt.
Bestehende Layoutdateien ignorieren diese einfach und funktionieren weiterhin.

## In Version 6.0 entfernt

Seit Version 5 sind der XPath-Parser `lxpath` und der Fontloader `harfbuzz` die Voreinstellung.
Die älteren Varianten (`luxor` und `fontforge`) wurden mit Version 6.0 entfernt.
Ihre Auswahl (über die Schlüssel `xpath` bzw. `fontloader` in der [Konfigurationsdatei]({{< relref "configuration" >}}), das Attribut `mode="fontforge"` bei `<LoadFontfile>` oder das Attribut `require` bei `<Layout>`) führt zu einer Fehlermeldung.

Ebenfalls mit Version 6.0 entfernt:

- Type-1-Schriften (`.pfb`): sie konnten nur mit dem fontforge-Fontloader geladen werden. Bitte nach OpenType konvertieren.
- Die Kommandozeilenoptionen `--extra-xml` und `--prepend-xml` (Konfigurationsschlüssel `extraxml` und `prependxml`): zum Aufteilen des Layouts auf mehrere Dateien stattdessen XInclude benutzen.

### Umstieg von luxor und fontforge

Falls ein Layout noch eine der alten Varianten benutzt:

- `luxor`: Das Layout mit `lxpath` laufen lassen und die gemeldeten Fehler beheben. Rechenausdrücke mit Maßeinheiten (z.B. `"2cm + 12mm"`) entsprechen nicht der XPath-Spezifikation und lassen sich mit der Funktion [`sd:dimexpr()`]({{< relref "layoutfunctions" >}}) nachbilden.
- `fontforge`: Den Schlüssel `fontloader` aus der Konfigurationsdatei und das Attribut `mode="fontforge"` bei `<LoadFontfile>` entfernen; die Schriften werden dann mit `harfbuzz` geladen. Virtuelle Fonts werden nicht mehr unterstützt. Type-1-Schriften (`.pfb`) sollten nach OpenType konvertiert werden.

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
| `lxpath` | Der XPath-Parser `lxpath` (immer aktiv, wird aus Kompatibilitätsgründen akzeptiert). |
| `harfbuzz` | Der Fontloader `harfbuzz` (immer aktiv, wird aus Kompatibilitätsgründen akzeptiert). |
| `luxor` | Der alte XPath-Parser (in Version 6.0 entfernt, führt zu einer Fehlermeldung). |
| `fontforge` | Der alte Fontloader (in Version 6.0 entfernt, führt zu einer Fehlermeldung). |
