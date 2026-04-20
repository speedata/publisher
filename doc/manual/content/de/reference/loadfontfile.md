---
linktitle: "LoadFontfile"
weight: 530
type: docs
---

# `LoadFontfile`


Der Befehl LoadFontfile weist einer physikalischen Schriftdatei einen internen Namen zu. Wird ein Zeichen in der Schriftart nicht gefunden, erzeugt das Programm eine Fehlermeldung, die mit [`Options`]({{% relref "options" %}}) ausgeschaltet werden kann. Alternativ dazu können auch Ersatzschriftarten (mit [`Fallback`]({{% relref "fallback" %}})) angegeben werden, die nach den fehlenden Zeichen abgesucht werden. 



## Kindelemente

<a href="../fallback"><code>Fallback</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`features` (Text, optional, _seit Version 3.9.29_)
: Eine kommaseparierte Liste von OpenType features, z.B. `+liga,-kern`



`filename` (Text)
: Der Dateiname mit Endung, ohne Pfad.



`marginprotrusion` (0 bis 100, optional)
: Angabe in Prozent, um wie viel die Zeichen -, . und , über den Rand herausragen. Voreinstellung ist 0. Der Wert wird mit 0,001em der aktuellen Schrift multipliziert, eine Einstellung von 200 erlaubt also, dass diese Zeichen 0,2em über den Rand hinausragen.



`mode` (optional, _seit Version 3.9.29_)
: Setzt den Fonthandler. Voreinstellung ist `harfbuzz`.


  - `fontforge`: Der alte und gut funktionierende Fonthandler. Funktioniert gut mit westlichen Schreibsystemen, nicht aber mit rechts-nach-links oder anderen komplizierten Schreibsystemen.
  - `harfbuzz`: Der neue Fonthandler der Arabisch und andere komplexen Schreibsysteme verarbeiten kann.

`name` (Text)
: Der interne Name, unter dem die Schriftart im Element [`DefineFontfamily`]({{% relref "definefontfamily" %}}) angesprochen wird.



`oldstylefigures` (optional)
: Schalter, ob auf Mediävalziffern umgeschaltet wird (OpenType Feature »onum«).


  - `yes`: Mediävalziffern benutzen.
  - `no`: Normale Ziffern benutzen.

`shrink` (Zahl, optional, _seit Version 4.19.17_)
: Setze den maximalen Stauchfaktor der Schriftart. Voreinstellung ist ausgeschaltet. Wert geteilt durch 10 = Prozent. Beispiel: 20 bedeutet eine maximale Stauchung von 2%.



`smallcaps` (optional)
: Schalter, ob die Schriftart als Kapitälchen dargestellt werden soll.


  - `yes`: Kapitälchen benutzen.
  - `no`: Nicht auf Kapitälchen umschalten (Voreinstellung).

`space` (0 bis 100, optional)
: Natürliche Breite des Leerraums zwischen zwei Wörtern. Dieser darf um 30% gestreckt und um 10% gestaucht werden. Die Voreinstellung ist 25. Der Wert ist die Prozentangabe der Schriftgröße.



`step` (Zahl, optional, _seit Version 4.19.17_)
: Setze die Schritte für stauchen und dehnen. Wert geteilt durch 10 = Prozent. Beispiel: 20 erhöht/verringert die Schriftgröße bei Bedarf um 2%. Voreinstellung: 10



`stretch` (Zahl, optional, _seit Version 4.19.17_)
: Setze den maximalen Dehnungsfaktor der Schriftart. Voreinstellung ist ausgeschaltet. Wert geteilt durch 10 = Prozent. Beispiel: 20 bedeutet eine maximale Dehnung von 2%.






## Beispiel


```xml
<LoadFontfile name="Helvetica" filename="texgyreheros-regular.otf" />
<LoadFontfile name="Helvetica Fett" filename="texgyreheros-bold.otf" />
<LoadFontfile name="Helvetica Kursiv" filename="texgyreheros-italic.otf" />
<LoadFontfile name="Helvetica Fett Kursiv" filename="texgyreheros-bolditalic.otf" />
```



## Hinweis


Die Schriftdateien werden aus dem lokalen Suchpfad geladen. Unter Windows wird der Pfad `%WINDIR%\Fonts` (normalerweise `C:\Windows\Fonts`) und auf Mac OS X die Pfade `/Library/Fonts` und `/System/Library/Fonts` können als Ergänzung des lokalen Suchpfads dienen. Das kann mit der Option `fontpath` in der Konfigurationsdatei gesetzt werden.




