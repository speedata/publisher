title: Changelog
---
Liste der Änderungen vor Version 1.0
====================================

Version 0.9 (2010-03-26)
------------------------

-   [ObjektAusgeben](../commands-de/placeobject.html) ist Elternelement
    von rechteckigen Bereichen ([Bild](../commands-de/image.html),
    [Box](../commands-de/box.html),
    [Textblock](../commands-de/textblock.html),
    [Tabelle](../commands-de/table.html))
-   Intern: Umstellung auf Nodelisten-Verarbeitung
-   Tabellen

Version 0.8 (2010-02-28)
------------------------

-   Mehrere Läufe möglich mit
    [Optionen/@läufe](../commands-de/options.html).
-   Layoutregelwerk und Datendatei werden im Projektpfad gesucht
-   Der Namensraum ist nun `urn:speedata.de:2009/publisher/de`
-   Die Konfigurationsdatei `publisher.conf` wird zusätzlich im
    aktuellen Verzeichnis gesucht.
-   Farbe Schwarz ist vordefiniert.
-   Verbesserte Fehlerbehebung bei Farben.
-   Metapost entfernt.

Version 0.7 (2010-01-26)
------------------------

-   Farben: [DefiniereFarbe](../commands-de/definecolor.html): Farben
    können definiert werden. Farbangaben in
    [Textblock](../commands-de/textblock.html) und
    [Absatz](../commands-de/paragraph.html) erlaubt.
-   Hintergrundfarbe bei [Textblock](../commands-de/textblock.html) und
    GruppeAusgeben.
-   Rahmen und Rahmenfarbe bei
    [Textblock](../commands-de/textblock.html) und GruppeAusgeben.
-   [Box](../commands-de/box.html) (farbige Flächen).

Version 0.6 (2010-01-07)
------------------------

-   Neue XPath-Funktion: `aktuelle-seite()`
-   Neues Element: `Nachricht`
-   Automatisch generierte Listen:
    [Element](../commands-de/element.html),
    [Attribut](../commands-de/attribute.html),
    [LadeDatensatzdatei](../commands-de/loaddataset.html),
    [SpeichereDatensatzdatei](../commands-de/savedataset.html)
-   Die Datensatzverarbeitung fängt nun mit dem Wurzelelement an.
    Dadurch besteht die Gelegenheit vor und nach der Ausführung weitere
    Aktionen durchzuführen.

Version 0.5 (2010-01-04)
------------------------

-   Zuweisung erwartet einen XPath-Ausdruck im Attribut `auswahl`
-   Zuweisungen können mehrere Inhalte haben.
-   Neues Schleifenelement: [Solange](../commands-de/while.html)
-   Boolesche Ausdrücke in XPath
-   Unicode in Variablennamen (+ XPath)
-   [Fallunterscheidungen](../commands-de/switch.html)

Version 0.4 (2009-12-14)
------------------------

-   [Gruppen](../commands-de/group.html) können angelegt und ausgegeben
    werden.

Version 0.3
-----------

-   [XPath-Ausdrücke](xpath.html) können in den Attributen `zeile`,
    `spalte` und `breite` bei [Textblock](../commands-de/textblock.html)
    und [Bild](../commands-de/image.html) sowie im Attribut `auswahl` im
    Element [Wert](../commands-de/value.html) angegeben werden.

Version 0.2 (2009-11-10)
------------------------

-   Publisher: Daten-XML und Layout-XML können über die Kommandozeile
    und über die Konfigurationsdatei angegeben werden.
-   Publisher: Konfigurationsdatei heißt nun publisher.conf und liegt im
    Homeverzeichnis. Vorher: .sprc

Version 0.1 (2009-10-28)
------------------------

-   Publisher: Namensraum Layout-xml nun:
    http://www.speedata.de/ns/layout/de/1.0

Siehe auch
==========

[Liste der Änderungen](changelog.html)

