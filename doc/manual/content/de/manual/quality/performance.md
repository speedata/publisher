---
title: "Performance-Überlegungen"
weight: 68
type: docs
---


Bei der Verarbeitung großer Dokumente oder Dokumente mit vielen Formatierungsoperationen kann die Performance ein wichtiger Faktor sein. Dieses Kapitel beschreibt verschiedene Strategien zur Optimierung der Satzgeschwindigkeit des speedata Publishers.

## HTML-Parsing

Einer der wichtigsten Performance-Faktoren ist das HTML-Parsing in Absätzen. Standardmäßig parst der Publisher HTML-Tags wie `<b>`, `<i>`, `<span>` usw. in allen Textinhalten. Dieses Parsing erfolgt für jeden Absatz und kann aufwändig sein, insbesondere in Dokumenten mit vielen kleinen Textblöcken.

### Deaktivieren des HTML-Parsings

Wenn Ihr Dokument keine HTML-Formatierungs-Tags verwendet, können Sie die Performance erheblich verbessern, indem Sie das HTML-Parsing deaktivieren:

#### Globale Einstellung

Um das HTML-Parsing für das gesamte Dokument zu deaktivieren, verwenden Sie den Befehl `<Options>`:

```xml
<Options html="off"/>
```

Dies kann die Satzzeit in Dokumenten mit vielen Absätzen um bis zu 40% reduzieren.

#### Lokale Einstellung

Sie können das HTML-Parsing auch für einzelne Absätze steuern:

```xml
<Paragraph html="off">
  <Value>Text ohne HTML-Formatierung</Value>
</Paragraph>
```

#### HTML-Parsing-Modi

Das Attribut `html` unterstützt drei Werte:

`all`
: HTML in allen Absätzen parsen (Standardverhalten).

`inner`
: HTML nur in Kindelementen des aktuellen Datenelements parsen.

`off`
: HTML-Parsing komplett deaktivieren. Dies bietet die beste Performance, aber HTML-Tags wie `<b>` oder `<i>` werden nicht interpretiert.

#### Kommandozeilenoption

Sie können den HTML-Parsing-Modus auch über die Kommandozeile setzen:

```shell
sp --option html=off
```

Dies ist besonders nützlich für Batch-Verarbeitung oder zum Testen von Performance-Optimierungen.

### Wann html="off" verwenden

Erwägen Sie die Deaktivierung des HTML-Parsings, wenn:

* Ihre Daten keine HTML-Formatierungs-Tags enthalten
* Die Textformatierung vollständig über Textformate erfolgt
* Sie große Dokumente mit vielen Absätzen verarbeiten
* Performance kritisch ist und Sie keine Inline-HTML-Formatierung benötigen

### Wann HTML-Parsing aktiviert lassen

Behalten Sie das HTML-Parsing bei, wenn:

* Ihre Daten HTML-Tags wie `<b>`, `<i>`, `<span>` usw. enthalten
* Sie Inline-Formatierung innerhalb von Absätzen benötigen
* Sie CSS-Styles mit HTML-Elementen verwenden
* Die Dokumentenerstellungszeit nicht kritisch ist

