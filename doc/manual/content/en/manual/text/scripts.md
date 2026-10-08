---
title: "Writing systems"
weight: 45
type: docs
---

The speedata Publisher typesets text in many writing systems.
The built-in text shaping (HarfBuzz) computes the forms of the characters automatically, for example the joined letters of Arabic or the syllables of Indic scripts.
This section describes what else applies to the individual writing systems: the writing direction, line breaking, the language setting and the known limitations.

For all writing systems:

1. The font must contain the characters. If some characters are missing, you can add [replacement fonts]({{< relref "fonts#missing-characters-and-replacement-fonts" >}}).
2. The language should be correct if it is in the [list of languages]({{< relref "/reference/commands/options" >}}). With fonts that cover several languages, it selects the matching forms of the characters. If the language is not in the list, use `Other`; then the text shaping detects the writing system itself.

## Arabic, Hebrew and other right-to-left scripts

If a paragraph contains Arabic or Hebrew characters, the Publisher determines the writing direction automatically (“bidi algorithm”):

* The paragraph runs in the direction of its first letter. So an Arabic paragraph is right-to-left, even without `direction`.
* Latin words and numbers in right-to-left text run from left to right.
* Brackets are mirrored.

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

![Right-to-left paragraph with numbers and Latin words](/img/scripts-rtl.png)

With `direction="rtl"` or `direction="ltr"` on the paragraph you set the direction instead of taking it from the first letter.
This is useful if a paragraph starts with a word of the “wrong” direction, for example an Arabic sentence that starts with a product name.
`bidi="no"` switches the direction analysis off; then Latin words and numbers in right-to-left text are reversed, though.

For ragged text, use the alignment `start` and `end` in the text format instead of `leftaligned` and `rightaligned`.
`start` and `end` follow the direction of the paragraph, see [`<DefineTextformat>`]({{< relref "/reference/commands/definetextformat" >}}).

The languages `Arabic`, `Persian`, `Urdu` and `Hebrew` select the regional forms with fonts that support them, for example the Urdu digits:

```xml
<Paragraph language="Persian"><Value>فارسی ۴۵۶۷</Value></Paragraph>
<Paragraph language="Urdu"><Value>اردو ۴۵۶۷</Value></Paragraph>
```

![Persian (top) and Urdu digits (bottom) in the same font](/img/scripts-urdu-digits.png)

Known limitations:

* If the formatting changes inside an Arabic word (for example one bold letter), the letters lose their connection at this position.
* Justification distributes the space to the word spaces. Stretching the connecting line (kashida) is not supported.
* In HTML contents, the attribute `dir` and the CSS property `direction` are not evaluated.

## Chinese, Japanese and Korean

Chinese and Japanese text is broken between all characters, without setting a language, and also if the paragraph starts with a Latin word.
The usual rules for the start and the end of a line apply:

* Closing brackets and punctuation such as `》`, `」`, `，` and `。` do not start a line.
* Opening brackets such as `《` and `「` do not end a line.
* Small kana (`ャ`, `ッ` …) and the prolonged sound mark `ー` do not start a line.
* `……` and `——` are not split.

In justified text the extra space is distributed evenly between the characters.
Korean text is broken at the spaces, as usual in Korean.

```xml
<Paragraph language="Chinese">
  <Value>Speedata出版软件可以从数据生成文件。他读了很多遍《红楼梦》，每一遍都有新的体会……</Value>
</Paragraph>
<Paragraph language="Japanese">
  <Value>東京のコンピューターショップでキャッシュカードを使ってチョコレートを買った。</Value>
</Paragraph>
```

![Chinese (left) and Japanese (right), justified](/img/scripts-cjk.png)

The same characters partly have different forms in China, Taiwan, Japan and Korea.
Fonts such as Noto Sans CJK or Source Han Sans contain all forms; the language selects the matching one.
The languages are `Chinese` (simplified characters), `Chinese (Traditional)` (traditional characters), `Japanese` and `Korean`.

```xml
<Paragraph language="Chinese"><Value>zh 直骨角</Value></Paragraph>
<Paragraph language="Chinese (Traditional)"><Value>zh_TW 直骨角</Value></Paragraph>
<Paragraph language="Japanese"><Value>ja 直骨角</Value></Paragraph>
<Paragraph language="Korean"><Value>ko 直骨角</Value></Paragraph>
```

![The same characters in one font, in the Chinese, Taiwanese, Japanese and Korean form depending on the language](/img/scripts-cjk-forms.png)

Known limitations:

* Consecutive punctuation such as `。」` is not compressed. In narrow columns with a lot of punctuation, lines can be stretched a lot.
* Small kana at the start of a line are always prohibited; the loose rule that allows them cannot be selected.
* Vertical text, ruby (reading aids such as pinyin or furigana) and emphasis dots are not supported.

## Thai, Lao, Khmer and Burmese

In these scripts there are no spaces between the words.
Where a word ends can only be found with a dictionary, and the Publisher has none.
So the word boundaries must be in the data, as zero width spaces (U+200B).
Without them, the text can only be broken at the real spaces and long sentences run out of the text block.

```xml
<Paragraph>
  <Value>พระเจ้า&#x200B;กล่าว&#x200B;ว่า&#x200B;ให้&#x200B;มี&#x200B;ความ&#x200B;สว่าง…</Value>
</Paragraph>
```

![Top without word boundaries, bottom with U+200B at the word boundaries](/img/scripts-thai.png)

The best place to insert the word boundaries is the data preparation, with a library that has a dictionary for the language, for example ICU (BreakIterator, available for many programming languages) or PyThaiNLP for Python.
Inserting U+200B at fixed intervals is not a good idea: then lines are broken inside syllables.
If a U+200B is directly before a tone mark or vowel sign, the Publisher ignores it, so that the mark does not stand alone at the start of a line.

The word joiner U+2060 prevents a line break at a certain position, see [Controlling line breaks with special characters]({{< relref "hyphenationlanguage#controlling-line-breaks-with-special-characters" >}}).

## Indic scripts

The text shaping builds the syllables of Indic scripts (Devanagari, Bengali, Tamil …) automatically, including the half forms and ligatures that are controlled with ZWJ (U+200D) and ZWNJ (U+200C).
Lines are broken at the spaces.
There is currently no hyphenation for Indic scripts, not even with the languages `Hindi`, `Gujarati`, `Kannada`, `Malayalam` and `Sanskrit`.
As language, use the matching one from the list or `Other`:

```xml
<Paragraph language="Other">
  <Value>আমি</Value>
</Paragraph>
```

![Bengali with the language setting `Other`](/img/hb-bengali-correct.png)
