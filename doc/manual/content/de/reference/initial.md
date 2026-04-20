---
linktitle: "Initial"
weight: 470
type: docs
---

# `Initial`
_seit Version 2.9.7_

Einige Zeichen erscheinen in einer größeren Schriftart am Absatzanfang.



## Kindelemente

<a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`color` (Text, optional, _seit Version 2.9.0_)
: Setze die Farbe der Initiale. Voreingestellt ist Schwarz.



`fontfamily` (Text, optional)
: Wähle die Fontfamilie. Derzeit wird nur der Schnitt Regular verwendet.



`padding-bottom` (Längenangabe, optional, _seit Version 4.1.25_)
: Fügt Leerraum unten der Initiale ein.



`padding-left` (Längenangabe, optional)
: Fügt Leerraum links der Initiale ein.



`padding-right` (Längenangabe, optional)
: Fügt Leerraum rechts der Initiale ein.



`padding-top` (Längenangabe, optional, _seit Version 4.1.25_)
: Fügt Leerraum oben der Initiale ein.






## Beispiel


```xml
<Textblock>
  <Paragraph>
    <Initial fontfamily="Large" padding-right="2pt">
      <Value select="'E'"/>
    </Initial>
    <Value>s war einmal ein König und eine Königin,
    die hatten keine Kinder, wünschten sich aber
    tagtäglich ein Kind.</Value>
  </Paragraph>
</Textblock>

```

![ref-initial-de.png](/img/ref-initial-de.png)



## Hinweis


Bitte stellen Sie sicher, dass die Schriftart für den Absatz korrekt eingestellt ist (Voreinstellung: text). Auf dieser Einstellung beruht die Höhenberechnung.




