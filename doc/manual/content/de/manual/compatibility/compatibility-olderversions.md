---
title: "Kompatibilität mit älteren Versionen"
weight: 230
type: docs
aliases:
  - /de/compatibilityolderversions/
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

## Verhaltensänderungen in Version 6.0

Manche Korrekturen ändern den Umbruch oder die Platzierung bestehender Dokumente.
Sie werden erst mit Version 6.0 zum Standard.
Bis dahin behält ein Layout ohne weitere Einstellung das bisherige Verhalten, und das neue Verhalten lässt sich schon vorher einschalten.

| Verhalten | Einstellung bei `<Compatibility>` | Standard ab |
| --- | --- | --- |
| Wortzwischenräume im Flattersatz (Ausrichtung `leftaligned`, `rightaligned`, `centered`, `start` und `end`) behalten ihre natürliche Breite. Bis Version 5.9 dürfen sie etwas gestaucht werden, damit noch ein Wort in die Zeile passt. | `raggednaturalspaces` | 6.0 |

### Alle Verhaltensweisen einer Version: `defaults`

Das Attribut `defaults` bei [`<Layout>`]({{< relref "/reference/commands/layout" >}}) wählt den Verhaltensstand einer Publisher-Version aus, im Format major.minor oder mit dem Schlüsselwort `latest` für die aktuelle Version:

```xml
<Layout
    xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en"
    defaults="6.0">
```

- `defaults="6.0"` (oder `latest`) schaltet alle Verhaltensweisen aus der Tabelle oben schon jetzt ein.
- `defaults="5.9"` behält das bisherige Verhalten bei, auch nach dem Wechsel auf Version 6.0. Das ist für Layouts gedacht, deren Ausgabe sich nicht ändern darf.
- Ohne das Attribut gilt der eingebaute Stand des Publishers: 5.9 bis zu den Versionen 5.9.x, 6.0 ab Version 6.0.

Es zählt nur das Wurzelelement der Haupt-Layoutdatei.

### Einzelne Verhaltensweisen: `<Compatibility>`

Der Befehl [`<Compatibility>`]({{< relref "/reference/commands/compatibility" >}}) schaltet eine einzelne Verhaltensweise um, unabhängig von `defaults`.
Er hat Vorrang vor `defaults`:

```xml
<Layout
    xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en"
    defaults="6.0">

  <!-- alles wie in Version 6.0, aber die alten Wortzwischenräume im Flattersatz -->
  <Compatibility raggednaturalspaces="no"/>
```

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
