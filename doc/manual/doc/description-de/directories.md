title: Handbuch Publisher
---
Automatisch erstellte Verzeichnisse
===================================

Der speedata Publisher kann beliebige Verzeichnistypen erstellen. Ob
Inhaltsverzeichnis, Artikelliste oder Stichwortindex – alle Listen
funktionieren nach demselben Prinzip: die notwendigen Daten (z.B.
Seitenzahlen, Artikelnummern) werden in einer eigenen Datenstruktur
gespeichert, auf Festplatte geschrieben und beim nächsten Lauf des
Publishers werden diese Daten eingelesen und stehen sofort zur
Verfügung.

Damit der Publisher mehrfach durchläuft, muss der Parameter `runs` auf
der Kommandozeile bzw. in der Konfigurationsdatei gesetzt werden,
beispielsweise mit `sp --runs=2` (Kommandozeile) bzw. `runs = 2`
(Optionen).

Schritt 1: Sammeln der Informationen
------------------------------------

Die beiden Befehle [Element](../commands-de/element.html) und
[Attribute](../commands-de/attribute.html) dienen zur Strukturierung von
Daten, die während der Verarbeitung gelesen werden. Mit diesen Befehlen
lassen sich neue XML Datensatzdateien erzeugen. Die Datensatzdatei
sollte eine Struktur haben, die sich für die automatische Verarbeitung
mit dem Publisher eignet. Folgende Struktur könnte für eine Artikelliste
sinnvoll sein:

    <Artikelverzeichnis>
      <Artikel nummer="1" seite="10"/>
      <Artikel nummer="2" seite="12"/>
      <Artikel nummer="3" seite="14"/>
    </Artikelverzeichnis>

Um diese Struktur im Layoutregelwerk zu erstellen, muss sie aus den
Befehlen [Element](../commands-de/element.html) und
[Attribute](../commands-de/attribute.html) wie folgt zusammengesetzt
werden:

    <Element name="Artikelverzeichnis">
      <Element name="Artikel">
        <Attribute name="nummer" select="1"/>
        <Attribute name="seite" select="10"/>
      </Element>
      <Element name="Artikel">
        <Attribute name="nummer" select="2"/>
        <Attribute name="seite" select="12"/>
      </Element>
      <Element name="Artikel">
        <Attribute name="nummer" select="3"/>
        <Attribute name="seite" select="14"/>
      </Element>
    </Element>

Anstelle der Befehle [Element](../commands-de/element.html) und
[Attribute](../commands-de/attribute.html) können auch Variablen als
Speicher benutzt werden (siehe Beispiel unten).

Schritt 2: Speichern und Laden der Informationen
------------------------------------------------

Mit dem Befehl
[SaveDataset](../commands-de/savedataset.html) wird die
Struktur auf Festplatte gespeichert und mit
[LoadDataset](../commands-de/loaddataset.html) wird sie wieder
geladen. Existiert die Datei nicht, so wird kein Fehler gemeldet, da es
sich um den ersten Durchlauf handeln könnte, wo die Datei naturgemäß
noch nicht existiert.

Schritt 3: Verarbeiten der Informationen
----------------------------------------

Direkt nach dem Laden wird die XML-Verarbeitung mit dem ersten Element
der gerade geladenen Struktur fortgesetzt, im Beispiel oben würde nach
dem folgenden Befehl im Layoutregelwerk gesucht:

    <Record element="Artikelverzeichnis">
      ...
    </Record>

Das heißt, dass die eigentliche Datenverarbeitung zeitweilig
unterbrochen und mit dem neuen Datensatz aus
[LoadDataset](../commands-de/loaddataset.html) fortgeführt wird.

Beispiel
--------

Das folgende Beispiel reichert die »Planetenliste« um ein
Inhaltsverzeichnis an. Die Verarbeitung beginnt beim Wurzelelement
`planeten` (in der Mitte der Datei). Hier wird die Datensatzdatei `toc`
(für: table of contents) geladen. Im ersten Durchlauf wird die Datei
nicht gefunden, daher wird die Datensatzdatei »planeten« normal weiter
verarbeitet. Während des Durchlaufs wird eine Liste erstellt, die
folgende XML-Struktur hat:

    <Inhaltsverzeichnis>
      <Planetenverzeichnis name="Merkur" seite="2" />
      <Planetenverzeichnis name="Venus" seite="3" />
      <Planetenverzeichnis name="Erde" seite="4" />
      <Planetenverzeichnis name="Mars" seite="5" />
      <Planetenverzeichnis name="Jupiter" seite="6" />
      <Planetenverzeichnis name="Saturn" seite="7" />
      <Planetenverzeichnis name="Uranus" seite="8" />
      <Planetenverzeichnis name="Neptun" seite="9" />
    </Inhaltsverzeichnis>

Im Layoutregelwerk muss diese den folgenden Aufbau haben:

    <Element name="Inhaltsverzeichnis">
      <Element name="Planetenverzeichnis">
        <Attribute name="name" select="'Merkur'"/>
        <Attribute name="seite" select="2"/>
      </Element>
      <Element name="Planetenverzeichnis">
        <Attribute name="name" select="'Venus'"/>
        <Attribute name="seite" select="3"/>
      </Element>
      ...
      <Element name="Planetenverzeichnis">
        <Attribute name="name" select="'Uranus'"/>
        <Attribute name="seite" select="9"/>
      </Element>
    </Element>

Natürlich soll die Information in den Attributen dynamisch erzeugt
werden, dafür werden der XPath-Ausdruck `@name` und die XPath-Funktion
`sd:current-page()` benutzt.

Im zweiten Durchlauf wird die Datei erfolgreich eingelesen und die
Verarbeitung »springt« zum Datensatz `Inhaltsverzeichnis`, da es das
Wurzelelement der neuen Datei ist. Hier wird im Layoutregelwerk das
Inhaltsverzeichnis erstellt.

    <Record element="Inhaltsverzeichnis">
      <SetVariable variable="Inhaltsverzeichnis" select="''"/>
      <ProcessNode select="Planetenverzeichnis"/>
      <PlaceObject column="3">
        <Textblock width="20" fontface="Überschrift">
          <Paragraph><Value>Inhalt</Value></Paragraph>
        </Textblock>
      </PlaceObject>
      <PlaceObject column="3">
        <Textblock width="20">
          <Value select="$Inhaltsverzeichnis"/>
        </Textblock>
      </PlaceObject>
    </Record>
     
    <Record element="Planetenverzeichnis">
      <SetVariable variable="Inhaltsverzeichnis">
        <Value select="$Inhaltsverzeichnis"/>
        <Paragraph>
          <Value select="@name"/>
          <Value>, Seite </Value>
          <Value select="@seite"/>
        </Paragraph>
      </SetVariable>
    </Record>
     
    <!-- Wurzelelement -->
    <Record element="planeten">
      <SetVariable variable="spalte" select="2" />
      <LadeDatensatzdatei name="toc"/>
      <SetVariable variable="Inhalt" select="''"/>
      <NewPage/>
      <ProcessNode select="planet"/>
    </Record>
     
    <Record element="planet">
      <SetVariable variable="Inhalt">
        <Value select="$Inhalt"/>
        <Element name="Planetenverzeichnis">
          <Attribute name="name" select=" @name "/>
          <Attribute name="seite" select=" sd:current-page()"/>
        </Element>
      </SetVariable>
     
      <ProcessNode select="url" />
      ...
      <NewPage />
      <SpeichereDatensatzdatei filename="toc" elementname="Inhaltsverzeichnis" select="$Inhalt"/>
    </Record>
     
    <Record element="url">
      ...
    </Record>
