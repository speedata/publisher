---
title: "OxygenXML"
weight: 10
type: docs
---


Der Editor [oXygen XML](https://www.oxygenxml.com) ist ein spezieller XML Editor, der eine hervorragende Unterstützung für die Bearbeitung des Layoutregelwerks bietet.
Um diese Unterstützung zu erhalten, muss dem speedata Layout-Namensraum (`urn:speedata.de:2009/publisher/en`) das Schema zugeordnet werden.

![In den Einstellungen wählt man die Zuordnung der Dokumenttypen (Document Type Association). Anschließend klickt man auf »New«, um eine neue Zuordnung zu erstellen](/img/oxygen-schema-doctypeassociation.png)

![Im ersten Reiter muss man auf das `+` klicken, um eine Zuordnung zu erstellen.](/img/oxygen-schema-doctypeassociation-1.png)

![In diesem Fenster trägt man den Namensraum des Layouts (`urn:speedata.de:2009/publisher/en`) ein.](/img/29-doczuordnung1.png)

![Nun kann man als Schema RELAX NG + Schematron einstellen und das Schema auswählen. In der ZIP-Datei liegt es unter `share/schema/layoutschema-en.rng` bzw. `...-de.rng`, je nach gewünschter Sprache für die Kurzbeschreibung.](/img/29-doczuordnung2.png)

Ab sofort sollte zu jedem Layout im Namensraum

```xml
xmlns="urn:speedata.de:2009/publisher/en"
```

das Schema hinterlegt sein.
Das erkennt man daran, dass nun bei Eingabe einer öffnenden spitzen Klammer (<) eine Auswahl der Befehle erscheint.

![Ist das Schema richtig eingebunden, dann erscheint eine Auswahlliste sobald man einen Befehl eingibt.](/img/29-liste.png)

