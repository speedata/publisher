---
title: "Schriftsysteme"
weight: 45
type: docs
---

Der speedata Publisher setzt Text in vielen Schriftsystemen.
Die Zeichenformen (zum Beispiel die verbundenen Buchstaben im Arabischen oder die Silbenzeichen indischer Schriften) berechnet die eingebaute Textformung HarfBuzz automatisch.
Dieser Abschnitt beschreibt, was darüber hinaus für die einzelnen Schriftsysteme gilt: Schreibrichtung, Zeilenumbruch, Spracheinstellung und die bekannten Grenzen.

Für alle Schriftsysteme gilt:

1. Die Schriftart muss die Zeichen enthalten. Fehlen einzelne Zeichen, kann man [Ersatzschriftarten]({{< relref "fonts#fehlende-zeichen-und-ersatzschriftarten" >}}) angeben.
2. Die Sprache sollte stimmen, wenn es sie in der [Liste der Sprachen]({{< relref "/reference/commands/options" >}}) gibt. Sie wählt bei Schriften, die mehrere Sprachen abdecken, die passenden Zeichenformen. Gibt es die Sprache nicht, nimmt man `Other`; dann erkennt die Textformung das Schriftsystem selbst.

## Arabisch, Hebräisch und andere rechtsläufige Schriften

Enthält ein Absatz arabische oder hebräische Zeichen, bestimmt der Publisher die Schreibrichtung automatisch (»Bidi-Algorithmus«):

* Der Absatz läuft in die Richtung seines ersten Buchstabens. Ein arabischer Absatz ist also rechtsläufig, auch ohne Angabe von `direction`.
* Lateinische Wörter und Zahlen im rechtsläufigen Text laufen von links nach rechts.
* Klammern werden gespiegelt.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en">
  <LoadFontfile name="Amiri" filename="amiri-regular.ttf" />
  <DefineFontfamily fontsize="10" leading="14" name="text">
    <Regular fontface="Amiri" />
  </DefineFontfamily>
  <Record element="data">
    <PlaceObject>
      <Textblock width="6cm">
        <Paragraph>
          <Value select="."/>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

```xml
<data>السعر 25.50 EUR للقطعة (الحد الأدنى 3 قطع). يستخدم speedata Publisher لإنشاء كتالوجات المنتجات.</data>
```

![Rechtsläufiger Absatz mit Zahlen und lateinischen Wörtern](/img/scripts-rtl.png)

Mit `direction="rtl"` oder `direction="ltr"` am Absatz legt man die Richtung fest, statt sie vom ersten Buchstaben abhängig zu machen.
Das ist nützlich, wenn ein Absatz mit einem Wort der »falschen« Richtung beginnt, zum Beispiel ein arabischer Satz, der mit einem Produktnamen anfängt.
Mit `bidi="no"` schaltet man die Richtungsanalyse aus; dann werden lateinische Wörter und Zahlen in rechtsläufigem Text allerdings umgedreht.

Bei Flattersatz sollte man im Textformat die Ausrichtung `start` und `end` benutzen statt `leftaligned` und `rightaligned`.
`start` und `end` richten sich nach der Richtung des Absatzes, siehe [`<DefineTextformat>`]({{< relref "/reference/commands/definetextformat" >}}).

Die Sprachen `Arabic`, `Persian`, `Urdu` und `Hebrew` wählen bei Schriften, die das unterstützen, die regionalen Formen, zum Beispiel die Urdu-Ziffern:

```xml
<Paragraph language="Persian"><Value>فارسی ۴۵۶۷</Value></Paragraph>
<Paragraph language="Urdu"><Value>اردو ۴۵۶۷</Value></Paragraph>
```

![Persische (oben) und Urdu-Ziffern (unten) in derselben Schrift](/img/scripts-urdu-digits.png)

Bekannte Grenzen:

* Wechselt die Formatierung mitten in einem arabischen Wort (zum Beispiel ein fetter Buchstabe), verlieren die Buchstaben an dieser Stelle ihre Verbindung.
* Der Blocksatz verteilt den Raum auf die Wortabstände. Eine Dehnung der Verbindungslinie (Kashida) gibt es nicht.
* Bei HTML-Inhalten werden das Attribut `dir` und die CSS-Eigenschaft `direction` nicht ausgewertet.

## Chinesisch, Japanisch und Koreanisch

Chinesischer und japanischer Text wird zwischen allen Schriftzeichen umbrochen, auch ohne Angabe einer Sprache und auch dann, wenn der Absatz mit einem lateinischen Wort beginnt.
Dabei gelten die üblichen Regeln für Zeilenanfang und Zeilenende:

* Schließende Klammern und Satzzeichen wie `》`, `」`, `，` und `。` stehen nicht am Zeilenanfang.
* Öffnende Klammern wie `《` und `「` stehen nicht am Zeilenende.
* Kleine Kana (`ャ`, `ッ` …) und der Dehnungsstrich `ー` stehen nicht am Zeilenanfang.
* `……` und `——` werden nicht getrennt.

Im Blocksatz wird der zusätzliche Raum gleichmäßig zwischen den Zeichen verteilt.
Koreanischer Text wird an den Leerzeichen umbrochen, wie im Koreanischen üblich.

```xml
<Paragraph language="Chinese">
  <Value>Speedata出版软件可以从数据生成文件。他读了很多遍《红楼梦》，每一遍都有新的体会……</Value>
</Paragraph>
<Paragraph language="Japanese">
  <Value>東京のコンピューターショップでキャッシュカードを使ってチョコレートを買った。</Value>
</Paragraph>
```

![Chinesisch (links) und Japanisch (rechts) im Blocksatz](/img/scripts-cjk.png)

Dieselben Zeichen haben in China, Taiwan, Japan und Korea teilweise unterschiedliche Formen.
Schriften wie Noto Sans CJK oder Source Han Sans enthalten alle Formen; die Sprache wählt die passende aus.
Dafür gibt es die Sprachen `Chinese` (Kurzzeichen), `Chinese (Traditional)` (Langzeichen), `Japanese` und `Korean`.

```xml
<Paragraph language="Chinese"><Value>zh 直骨角</Value></Paragraph>
<Paragraph language="Chinese (Traditional)"><Value>zh_TW 直骨角</Value></Paragraph>
<Paragraph language="Japanese"><Value>ja 直骨角</Value></Paragraph>
<Paragraph language="Korean"><Value>ko 直骨角</Value></Paragraph>
```

![Dieselben Zeichen in einer Schrift, je nach Sprache in chinesischer, taiwanischer, japanischer und koreanischer Form](/img/scripts-cjk-forms.png)

Bekannte Grenzen:

* Aufeinanderfolgende Satzzeichen wie `。」` werden nicht gestaucht. In schmalen Spalten mit viel Interpunktion können Zeilen dadurch stark gedehnt werden.
* Kleine Kana am Zeilenanfang sind immer verboten; die lockere Regel, die sie erlaubt, lässt sich nicht einstellen.
* Senkrechter Satz, Ruby (Lesehilfen wie Pinyin oder Furigana) und Betonungspunkte werden nicht unterstützt.

## Thai, Lao, Khmer und Birmanisch

In diesen Schriften stehen keine Leerzeichen zwischen den Wörtern.
Wo ein Wort endet, lässt sich nur mit einem Wörterbuch bestimmen; der Publisher hat keins.
Die Wortgrenzen müssen deshalb in den Daten stehen, als Leerzeichen mit Nullbreite (U+200B).
Fehlen sie, kann der Text nur an den echten Leerzeichen umbrochen werden und läuft bei langen Sätzen aus dem Textblock.

```xml
<Paragraph>
  <Value>พระเจ้า&#x200B;กล่าว&#x200B;ว่า&#x200B;ให้&#x200B;มี&#x200B;ความ&#x200B;สว่าง…</Value>
</Paragraph>
```

![Oben ohne Wortgrenzen, unten mit U+200B an den Wortgrenzen](/img/scripts-thai.png)

Die Wortgrenzen setzt man am besten bei der Datenaufbereitung mit einer Bibliothek, die ein Wörterbuch für die Sprache mitbringt, zum Beispiel ICU (BreakIterator, in vielen Programmiersprachen verfügbar) oder PyThaiNLP für Python.
U+200B in festen Abständen einzufügen ist keine gute Idee: Dann wird mitten in Silben umbrochen.
Steht ein U+200B direkt vor einem Ton- oder Vokalzeichen, ignoriert der Publisher es, damit das Zeichen nicht allein am Zeilenanfang steht.

Mit dem Wortverbinder U+2060 verhindert man einen Umbruch an einer bestimmten Stelle, siehe [Zeilenumbruch mit Sonderzeichen steuern]({{< relref "hyphenationlanguage#zeilenumbruch-mit-sonderzeichen-steuern" >}}).

## Indische Schriften

Die Silbenbildung indischer Schriften (Devanagari, Bengali, Tamil …) übernimmt die Textformung automatisch, einschließlich der Halbformen und Ligaturen, die man mit ZWJ (U+200D) und ZWNJ (U+200C) steuert.
Umbrochen wird an den Leerzeichen; ein Danda (`।`, `॥`) steht dabei nicht am Zeilenanfang, auch wenn davor ein Leerzeichen steht.
Eine Silbentrennung gibt es für indische Schriften derzeit nicht, auch nicht mit den Sprachen `Hindi`, `Gujarati`, `Kannada`, `Malayalam` und `Sanskrit`.

Die Sprache wählt bei Schriften, die das unterstützen, die regionalen Formen.
So haben einige Zeichen im Marathi und im Nepali eigene Formen:

```xml
<Paragraph language="Hindi"><Value>अ झ ल श १ ५ ८ ९</Value></Paragraph>
<Paragraph language="Marathi"><Value>अ झ ल श १ ५ ८ ९</Value></Paragraph>
<Paragraph language="Nepali"><Value>अ झ ल श १ ५ ८ ९</Value></Paragraph>
```

![Hindi, Marathi und Nepali in derselben Schrift (Noto Sans Devanagari)](/img/scripts-devanagari-forms.png)

Neben `Hindi`, `Marathi` und `Nepali` gibt es die Sprachen `Assamese`, `Bengali`, `Gujarati`, `Kannada`, `Malayalam`, `Odia`, `Punjabi`, `Sanskrit`, `Tamil` und `Telugu`.
Für andere Sprachen nimmt man `Other`.

```xml
<Paragraph language="Bengali">
  <Value>আমি</Value>
</Paragraph>
```

![Bengali](/img/hb-bengali-correct.png)
