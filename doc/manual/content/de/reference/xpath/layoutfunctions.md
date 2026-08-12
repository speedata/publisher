---
title: "Layoutfunktionen"
weight: 162
type: docs
---

Die Layoutfunktionen des Publishers sind im Namensraum `urn:speedata:2009/publisher/functions/de` definiert (im Folgenden mit `sd:` gekennzeichnet).
Neben diesen gibt es [XPath-Standardfunktionen]({{< relref "xpathfunctions" >}}) und [selbstdefinierte Funktionen]({{< relref "/reference/commands/function" >}}).

Optionale Parameter werden durch eckige Klammern markiert. Die Auslassungspunkte `...` bedeuten, dass der letzte Wert beliebig oft wiederholt werden kann.


## Seite und Raster

`sd:current-page()`
: Gibt die Seitennummer zurück.

`sd:current-column([<Bereich>])`
: Gibt die aktuelle Spalte zurück. Wenn `Bereich` angegeben, gibt die Spalte des gegebenen Platzierungsbereichs zurück.

`sd:current-row([<Bereich>])`
: Gibt die aktuelle Zeile zurück. Wenn `Bereich` angegeben, gibt die Zeile des gegebenen Platzierungsbereichs zurück.

`sd:current-framenumber(<Bereich>)`
: Gibt die Nummer des aktuellen Rahmens im Platzierungsbereich zurück.

`sd:number-of-columns([<Bereich>])`
: Gibt die Anzahl der Spalten auf der Seite bzw. im angegebenen Bereich.

`sd:number-of-rows([<Bereich>])`
: Gibt die Anzahl der Zeilen auf der Seite bzw. im angegebenen Bereich.

`sd:allocated(x,y,[<Bereichsname>],[<Rahmennummer>])`
: Gibt wahr zurück, wenn die Zelle belegt ist.

`sd:first-free-row(<Bereich>)`
: Gibt die erste freie Zeile des Bereichs zurück (experimentell).

`sd:pagewidth(<Einheit>)`
: Gibt die Breite der Seite in der angegebenen Einheit zurück (als Zahl ohne Einheit). Beispiel: `sd:pagewidth("mm")` gibt `210` für eine A4-Seite zurück. Diese Funktion initialisiert eine Seite.

`sd:pageheight(<Einheit>)`
: Wie `sd:pagewidth()`, nur für die Höhe.

`sd:length(<was>[,<Einheit>])`
: Gibt die Länge von _was_ in der angegebenen Einheit zurück (ohne Einheit). Beispiel: `sd:length('_bleed','mm')` gibt `3` zurück, falls der Anschnitt auf 3mm gesetzt ist. _was_ kann `_bleed`, `_pagewidth` oder `_pageheight` sein. Einheit ist voreingestellt auf `mm`.


## Bilder

`sd:imagewidth(<Dateiname>,[Seitenzahl],[pdfbox],[<Einheit>])`
: Breite des Bildes in Rasterzellen. Wenn eine Einheit angegeben wird, ist die Bildbreite ein Vielfaches dieser Einheit. Vorsicht: sollte das Bild nicht gefunden werden, wird die Breite des Platzhalters zurückgegeben. Die Parameter können die Seitenzahl und die PDF-Box enthalten, siehe [Bilder]({{% relref "imagesandgraphics" %}}).

`sd:imageheight(<Dateiname>,[Seitenzahl],[pdfbox],[<Einheit>])`
: Höhe des Bildes in Rasterzellen. Siehe `sd:imagewidth()` für Details.

`sd:aspectratio(<Dateiname>,[Seitenzahl],[pdfbox])`
: Gibt das Verhältnis Breite/Höhe zurück (< 1 für Hochkant, > 1 für Querformat).

`sd:number-of-pages(<Dateiname>)`
: Ermittelt die Anzahl der Seiten der angegebenen (PDF-)Datei.

`sd:file-exists(<Dateiname>)`
: Gibt `true()` zurück, wenn die Datei im Suchpfad existiert.


## Gruppen

`sd:group-width(<Name>[,<Einheit>])`
: Gibt die Breite der Gruppe in Rasterzellen an. Mit optionaler Einheit wird die Breite als Vielfaches dieser Einheit zurückgegeben. Beispiel: `sd:group-width('Beispielgruppe','mm')`.

`sd:group-height(<Name>[,<Einheit>])`
: Gibt die Höhe der Gruppe an. Siehe `sd:group-width()` für Details.


## Text und Formatierung

`sd:format-number(<Zahl>, <Tausenderzeichen>, <Kommazeichen>)`
: Formatiert die Zahl mit Tausender-Trennzeichen und Kommatrenner. Beispiel: `sd:format-number(12345.67, '.',',')` ergibt `12.345,67`.

`sd:format-string(<Objekt>,...,<Formatierungsangaben>)`
: Formatiert Objekte nach `printf()`-Syntax.

`sd:dummytext([<Anzahl>])`
: Gibt den Blindtext "Lorem ipsum..." zurück. Mit dem optionalen Parameter wird der Text wiederholt.

`sd:loremipsum()`
: Alias für `sd:dummytext()`.

`sd:markdown(<Text>)`
: Interpretiert den Text als Markdown. Siehe [Markdown]({{% relref "markdown" %}}).

`sd:decode-html(<Node>)`
: Wandelt Texte wie `&lt;i&gt;Kursiv&lt;/i&gt;` in HTML-Markup.

`sd:symbol(<Wert>[,<Wert>,...])`
: Gibt Zeichen aus dem aktuellen Font anhand der Glyph-IDs zurück. Beispiel: `sd:symbol(123, 444)`.

`sd:romannumeral(<Zahl>)`
: Konvertiert die Zahl in eine römische Zahl.


## Variablen und Zustand

`sd:variable(<Name>[, ...])`
: Wie `$Name`, aber mit der Möglichkeit den Namen dynamisch zu erzeugen. Falls `$i` den Wert 3 enthält, liest `sd:variable('foo',$i)` die Variable `$foo3`.

`sd:variable-exists(<Name>)`
: Prüft, ob eine Variable definiert wurde.

`sd:attr(<Name>[, ...])`
: Wie `@Name`, aber mit der Möglichkeit den Namen dynamisch zu erzeugen.

`sd:alternating(<Typ>, <Text>[,<Text>,...])`
: Bei jedem Aufruf wird das nächste Argument zurückgegeben. Beispiel: `sd:alternating("tbl", "Weiß","Grau")` für abwechselnde Tabellenfarben.

`sd:keep-alternating(<Typ>)`
: Benutzt den aktuellen Wert von `sd:alternating()`, ohne ihn zu verändern.

`sd:reset-alternating(<Typ>)`
: Setzt den Zustand für `sd:alternating()` zurück.

`sd:even(<Zahl>)`
: Gibt `true()` zurück, wenn die Zahl gerade ist.

`sd:odd(<Zahl>)`
: Gibt `true()` zurück, wenn die Zahl ungerade ist.

`sd:mode(<String>[,<String>,...])`
: Gibt `true()` zurück, wenn einer der angegebenen Modi gesetzt ist. Siehe [Steuerung des Layouts]({{< relref "controllayout" >}}).

`sd:randomitem(<Wert>[,<Wert>,...])`
: Gibt einen der Werte zufällig zurück.


## Seitenmarker und Verzeichnisse

`sd:pagenumber(<Marke>)`
: Liefert die Seitenzahl der Seite, auf der die Marke ausgegeben wurde. Siehe [Mark]({{% relref "/reference/commands/mark" %}}).

`sd:visible-pagenumber([<Zahl>])`
: Liefert die benutzerdefinierte Seitenzahl für die angegebene echte Seitenzahl. Ohne Argument wird die aktuelle Seite benutzt.

`sd:firstmark(<Seitenzahl>)`
: Der erste Marker der angegebenen Seite. Nützlich z.B. für Kolumnentitel in Wörterbüchern.

`sd:lastmark(<Seitenzahl>)`
: Der letzte Marker der angegebenen Seite.

`sd:merge-pagenumbers(<Seitenzahlen>,[<Bereichstrenner>],[<Leeraumtrenner>],[Hyperlinks])`
: Fasst Seitenzahlen zusammen. Aus `"1, 3, 4, 5"` wird `1, 3–5`. Sortiert und entfernt Duplikate. Bei `Hyperlinks = true()` werden die Seitenzahlen anklickbar.

`sd:count-saved-pages(<Name>)`
: Gibt die Anzahl der mit `<SavePages>` gespeicherten Seiten zurück.


## Einheiten und Berechnung

`sd:tounit(<Zieleinheit>,<Wert>[,<Nachkommastellen>])`
: Konvertiert einen Wert in eine andere Einheit. Beispiel: `sd:tounit('pt','1pc')` ergibt 12.

`sd:dimexpr(<Einheit>,<Ausdruck>)`
: Wertet einen Rechenausdruck mit Maßeinheiten aus. Beispiel: `sd:dimexpr('cm',' (40mm + 2cm) / 2 ')` ergibt 3.0.


## Dateien und Binärdaten

`sd:decode-base64(<Zeichenkette>)`
: Konvertiert eine Base64-kodierte Zeichenkette in binären Inhalt.

`sd:filecontents(<Binärinhalt>)`
: Speichert den Inhalt in eine temporäre Datei und gibt den Dateinamen zurück.


## Hash-Funktionen

`sd:md5(<Wert>[,<Wert>,...])`
: Erzeugt die MD5-Summe als Hex-Zeichenkette. Beispiel: `sd:md5('Hallo ', 'Welt')` ergibt `5c372a32c9ae748a4c040ebadc51a829`.

`sd:sha1(<Wert>[,<Wert>,...])`
: Erzeugt die SHA-1-Summe als Hex-Zeichenkette.

`sd:sha256(<Wert>[,<Wert>,...])`
: Erzeugt die SHA-256-Summe als Hex-Zeichenkette.

`sd:sha512(<Wert>[,<Wert>,...])`
: Erzeugt die SHA-512-Summe als Hex-Zeichenkette.
