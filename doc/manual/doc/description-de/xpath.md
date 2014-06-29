title: Handbuch Publisher
---
XPath Ausdrücke
===============

Der Publisher akzeptiert in den den entsprechend markierten Attributen
(zumeist `auswahl` und `bedingung`) XPath Ausdrücke. In allen anderen
Attributen kann durch die geschweiften Klammern (`{` und `}`) ein XPath
Ausdruck erzwungen werden. In diesem Beispiel werden im Attribut
`breite` und im Element `Wert` die Werte dynamisch erzeugt, d.h. für die
Angabe der Breite wird auf den Inhalt der Variablen `breite`
zurückgegriffen, der Inhalt des Absatzes ist der Inhalt (Textwert) des
gerade aktuellen Datenknotens.

    <Textblock breite="{$breite}" schriftart="text" textformat="Text mit Einrückung">
      <Absatz>
        <Wert auswahl="."/>
      </Absatz>
    </Textblock>

Folgende XPath-Ausdrücke erkennt das System:
--------------------------------------------

-   Zahl: gibt den Wert direkt zurück. Beispiel: `"5"`
-   Text: gibt den Wert direkt zurück. Beispiel: `'Text'`
-   Rechenoperationen (`*`, `div`, `idiv`, `+`, `-`, `mod`). Beispiel:
    `( 6 + 4.5 ) * 2`
-   Zugriff auf Variablen. Beispiel: `$spalte + 2`
-   Zugriff auf den aktuellen Knoten (Punkt-Operator). Beispiel: `. + 2`
-   Zugriff auf Unterelemente. Beispiel: `produktdaten`, `node()`, `*`
-   Zugriff auf Attribute im aktuellen Knoten. Beispiel `@a`
-   Boolesche Ausdrücke: `<`, `>`, `<=`, `>=`, `=`, `!=`. Vorsicht, das
    Zeichen `<` muss in XML als `&lt;` geschrieben werden, das Zeichen
    `>` kann als `&gt;` geschrieben werden. Beispiel: `$zahl > 6`. Kann
    in Bedingungen benutzt werden.

Folgende XPath-Funktionen stehen bereit:
----------------------------------------

Es gibt zwei Klassen von XPath Funktionen: standardkonforme und speedata
Publisher spezifische Funktionen. Die spezifischen Funktionen sind im
Namensraum `urn:speedata:2009/publisher/functions/de` (im Folgenden mit
`sd:` gekennzeichnet). Die standard-Funktionen sollten sich wie XPath
2.0 verhalten.


Funktion | Beschreibung
---------|-------------
sd:aktuelle-rahmennummer(\<name\>)|  Gibt die Nummer des aktuellen Rahmens im Platzierungsbereich zurück.
sd:aktuelle-seite()|  Gibt die Seitennummer zurück.
sd:aktuelle-zeile()|  Gibt die aktuelle Zeile zurück.
sd:aktuelle-spalte()|  Gibt die aktuelle Spalte zurück.
sd:alternierend(\<typ\>, \<text\>,\<text\>,.. )|  Bei jedem Aufruf wird das nächste Argument zurück gegeben. Wert des Typs ist beliebig, muss aber eindeutig sein. Beispiel: `sd:alternierend("tbl", "Weiß","Grau")` könnte für die Hintergrundfarbe von Tabellen benutzt werden.
sd:alternierend-zurücksetzen(\<typ\>)|  Setzt den Zustand für `sd:alternierend()` für den angegebenen Typ zurück.
sd:anzahl-gespeicherte-seiten(\<Name\>)|  Gibt die Anzahl der gespeicherten Seiten, die mit \<SeitenSpeichern\> zwischengspeichert wurden.
sd:anzahl-datensätze(\<Sequenz\>)|  Gibt die Anzahl der Datensätze der Sequenz zurück.
sd:anzahl-seiten(\<Dateiname oder URI-Schema\>)|  Ermittelt die Anzahl der Seiten der angegebenen (PDF-)Datei.
sd:anzahl-spalten()|  Gibt die Anzahl der Spalten im aktuellen Raster.
sd:anzahl-zeilen()|  Gibt die Anzahl der Zeilen im aktuellen Raster.
sd:bildbreite(\<Dateiname oder URI-Schema\>)|  Breite des Bildes in Rasterzellen. Vorsicht: sollte das Bild nicht gefunden werden, wird die Breite des Platzhalters für nicht gefundene Bilder zurückgegeben. Daher muss vorher überprüft werden, ob das Bild existiert.
sd:bildhöhe(\<Dateiname oder URI-Schema\>)|  Höhe des Bildes in Rasterzellen. Vorsicht: sollte das Bild nicht gefunden werden, wird die Höhe des Platzhalters für nicht gefundene Bilder zurückgegeben. Daher muss vorher überprüft werden, ob das Bild existiert.
sd:datei-vorhanden(\<Dateiname oder URI-Schema\>)|  Wahr, wenn der Dateiname im Suchpfad existiert, ansonsten false.
sd:formatiere-zahl(Zahl oder String, Tausenderzeichen, Kommazeichen)|  Formatiert die übergebene Zahl und fügt Tausender-Trennzeichen hinzu und ändert den Kommatrenner. Beispiel: `sd:formatiere-zahl(12345.67, '.',',')` ergibt die Zeichenkette `1.2345,67`.
sd:formatiere-string(Zahl oder String,Formartierungsangaben)|  Gibt eine Zeichenkette zurück, die die gegebene Zahl mit den im zweiten Argument gegebenen Formatierungsanweisungen darstellt. Die Formatierungsanweisungen entsprechen der aus der Programmiersprache C bekannten `printf()`-Funktion.
sd:gerade(\<zahl\>)|  Wahr, wenn die angegebene Zahl gerade ist. Beispiel: `sd:gerade(sd:aktuelle-seite())`
sd:html-dekodieren(\<Node\>)|  Wandelt Texte wie `&lt;i&gt;Kursiv&lt;/i&gt;` in entsprechendes HTML-Markup.
sd:ungerade(\<zahl\>)|  Wahr, wenn die angegebene Zahl ungerade ist.
sd:gruppenbreite(\<string\>)|  Gibt die Breite in Rasterzellen für die Gruppe im ersten Argument an. Beispiel: `sd:gruppenbreite('Beispielgruppe')`
sd:gruppenhöhe(\<string\>)|  Gibt die Höhe in Rasterzellen für die Gruppe im ersten Argument an. Beispiel: `sd:gruppenbreite('Beispielgruppe')`
sd:seitennummer(\<Marke\>)|  Liefert die Seitenzahl der Seite auf der die angegebene Marke ausgegeben wurde. Siehe den Befehl [Marke](../commands-de/mark.html)
sd:seitenzahlen-zusammenfassen(\<Seitenzahlen\>,\<Trenner für Bereiche\>,\<Trenner für Leerraum\>) | Fasst Seitenzahlenbereiche zusammen. Beispielsweise aus `"1, 3, 4, 5"` wird `1, 3–5`. Voreinstellung für den Trenner für Bereiche ist ein Halbgeviertstrich (–), Voreinstellung für den Trenner für Leerraum ist ', ' (Komma, Leerzeichen). Diese Funktion sortiert die Zahlen und löscht doppelte Einträge. Bei leerem Trenner für Bereiche werden Zahlen nicht zusammengeführt, sondern einzeln mit dem Trenner für Leerraum verbunden.
sd:sha1(\<Wert\>,\<Wert\>, …)|  Erzeugt die SHA-1 Summe der Hintereinanderkettung der Werte als Hex-Zeichenkette. Beispiel: `sd:sha1('Hallo ', 'Welt')` ergibt die Zeichenkette `28cbbc72d6a52617a7abbfff6756d04bbad0106a`.
sd:variable(\<Name\>)|  ist dasselbe wie \$Name, nur mit der Möglichkeit den Namen auch dynamisch (z.B. mit `concat()`) zu erzeugen.
sd:variable-vorhanden(\<\<Name\>)|  Prüft, ob eine Variable vorhanden ist.
sd:blindtext() | Gibt den Blindtext "Lorem ipsum..." mit über 50 Wörtern zurück.
sd:loremipsum() | Alias für `sd:blindtext()`

Funktion | Beschreibung
---------|-------------
concat( \<Wert\>,\<Wert\>, … )|  Erzeugt einen neuen Text aus der Verkettung der einzelnen Werte.
count()|  Zählt alle Kindelemente mit dem angegebenen Namen. Beispiel: `count(eintrag)` zählt, wie viele Kindelemente mit den Namen `eintrag` existieren.
ceiling()|  Gibt den aufgerundeten Wert einer Zahl zurück.
empty(\<Attribut\>)|  Prüft, ob ein Attribut (nicht) vorhanden ist.
false()|  Gibt „Falsch“ zurück.
floor()|  Gibt den abgerundeten Wert einer Zahl zurück.
last()|  Gibt die Anzahl der Datensätze der gleichnamigen Geschwister-Elemente zurück. **Achtung: noch nicht XPath-konform.**
not()|  Negiert den Wahrheitswert des Arguments. Beispiel: `not(true())` ergibt `false()`.
position()|  Ermittelt die Position des aktuellen Datensatzes.
string(\<Sequenz\>)|  Gibt den Textwert der Sequenz zurück, d.h. den Inhalt der Elemente.
string-join(\<Sequenz\>, Separator)|  Gibt den Textwert der Sequenz zurück, wobei alle Elemente durch den Separator getrennt werden.
true()|  Gibt „Wahr“ zurück.
normalize-space(\<text\>) | Gibt den Text ohne führende und nachstehende Leerzeichen zurück. Alle Zeilenvorschübe werden durch Leerzeichen ersetzt. Mehrfach hintereinander auftretende Leerzeichen/Zeilenvorschübe werden durch ein einzelnes Leerzeichen ersetzt.

Todo Dokumentieren:
-------------------

- `abs()`
- `ceiling()`
- `max()`
- `min()`
- `node()`
- `string()`
- `upper-case()`

