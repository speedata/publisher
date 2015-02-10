title: Erste Schritte mit dem speedata Publisher
---


Erste Schritte mit dem speedata Publisher
=========================================

{{ img . "schema1.png" }}

Der speedata Publisher ist ein sogenanntes Database Publishing System. Das
beduetet, dass aus einer Datenquelle heraus publiziert wird. Bei dieser
Software ist die Ausgabe grundsätzlich PDF. Das Anordnung der Daten im PDF wird über
eine XML-Datei gesteuert, der Layout-Datei. Die Datenquelle muss ebenfalls als XML-Datei
vorliegen. Somit ist für andere Datenformate (Excel, Datenbanken, ...) ein
zusätzlicher Schritt notwendig, um sie nach XML zu konvertieren.

Anhand des klassichen »Hello world« Beispiels soll eine einfache PDF-Datei erzeugt werden.

Daten-Datei
-----------

Die Datendatei hat einen beliebigen Aufbau. Es sind keine Anforderungen an die
Datendatei gestellt, die über die üblichen XML-Regeln gehen ([Wohlgeformtheit](https://de.wikipedia.org/wiki/Extensible_Markup_Language#Wohlgeformtheit)). Im Bespiel hat sie die Form

    <root greeting="Hello world"/>

und wird in der Datei `data.xml` in einem leeren Verzeichnis gespeichert.

Layout-Datei
------------

In der Layout-Datei (Dateiname `layout.xml`) stehen die Anweisungen, wie die Daten formatiert werden sollen. Das Wurzelelement ist das Element mit dem Namen `Layout` im Namensraum `urn:speedata.de:2009/publisher/de`. In diesem Namensraum werden deutschsprachige Elementnamen erwartet (z.B. [ObjektAusgeben](../commands-de/placeobject.html)), im Namensraum `.../en` englischsprachige Namen (z.B. [PlaceObject](../commands-en/placeobject.html)). Der Funktionsumfang der beiden Varianten ist identisch. Eine minimale (und sinnfreie) Layout-Datei ist:

    <Layout xmlns="urn:speedata.de:2009/publisher/de" />

Die Layout-Datei besteht aus einem deklarativen Teil (z.B. Seitenvorlagen, Farben und Schriftarten definieren) und einem ausführenden Teil (Kindelemente in den Daten durchgehen und Inhalte auslesen). Diese beiden Teile können auch vermischt werden.

Die Datenverarbeitung beginnt grundsätzlich mit dem Befehl `Datensatz`:


    <Datensatz element="(Name des Wurzelelements)">
       ... Anweisungen für das Wurzelelement ...
    </Datensatz>

Die Anweisung, um ein Objekt auszugeben, heißt (tata!) `ObjektAusgeben`. Es erwartet als Kindelement den Typ des Objekts ([Bild](../commands-de/image.html), [Box](../commands-de/box.html), [Linie](../commands-de/rule.html), [Rahmen](../commands-de/frame.html), [Strichcode](../commands-de/barcode.html), [Tabelle](../commands-de/table.html), [Textblock](../commands-de/textblock.html), [Transformation](../commands-de/transformation.html)). Textblock (ein Text mit einer festen breite - als Voreinstellung wird die Seitenbreite genommen) hingegen erwartet als Kindelemente einen oder mehrere Absätze. Inhalte werden in `<Wert> ... </Wert>` Elemente geklammert. Anstatt den Text explizit anzugeben bei [Wert](../commands-de/value.html), erlaubt das Kommando auch eine Teilmenge an [XPath-Ausdrücken](xpath.html) um z.B. mit der `@`-Notation auf Attributwerte zuzugreifen.

Damit ist das vollständige (minimale) »Hello World« Beispiel einfach:

    <Layout
      xmlns="urn:speedata.de:2009/publisher/de"
      xmlns:sd="urn:speedata:2009/publisher/functions/de">


      <Datensatz element="root">
        <ObjektAusgeben>
          <Textblock>
            <Absatz>
              <Wert auswahl="@greeting"/>
            </Absatz>
          </Textblock>
        </ObjektAusgeben>
      </Datensatz>
    </Layout>


Weitere Beispiele sind im Verzeichnis [manual/examples-de](../examples-de/index.html) in der Distribution zu finden.


Aufruf des Publishers
---------------------

Sind die beiden Dateien im selben Verzeichnis gespeichert, so kann die PDF-Datei mit dem Befehlsaufruf

    sp

erzgeugt werden. Das Ergebnis ist in der Datei `publisher.pdf` zu finden.


{{ img . "helloworldframe.png" }}

Die Namen der Daten- oder Layout-Dateien können über die Kommandozeile angegeben werden:

    sp --data <Datendatei.xml> --layout <Layoutdatei.xml>

oder fest für das aktuelle Verzeichnis mit der Datei `publisher.cfg` gesetzt werden:

    data=<Datendatei.xml>
    layout=<Layoutdatei.xml>

Weiterführende Informationen unter [Aufruf des Publishers im Terminalfenster](publisherusage.html) and [Kommandozeile](commandline.html).
