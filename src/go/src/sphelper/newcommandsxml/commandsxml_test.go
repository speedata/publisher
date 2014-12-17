package newcommandsxml

import (
	"strings"
	"testing"
)

const (
	SRC string = `<commands xmlns="urn:speedata.de:2011/publisher/documentation">
	  <define name="Switchcontents">
		<optional><cmd name="Barcode"/></optional>
    </define>
	<command en="Case" de="Fall">
    <description xml:lang="en">
      <para>Descripton of Case, link to <cmd name="Switch"/>. <tt>typewriter</tt>.</para>
    </description>
    <description xml:lang="de">
      <para>Beschreibung von Fall, Link auf <cmd name="Switch"/>.</para>
    </description>
    <childelements>
      <oneOrMore>
        <reference name="Switchcontents"/>
      </oneOrMore>
    </childelements>
    <attribute en="test" de="bedingung" type="xpath" optional="no">
      <description xml:lang="en">
        <para>Description of test (en)</para>
      </description>
      <description xml:lang="de">
        <para>Description of <tt>test</tt> (de).</para>
      </description>
    </attribute>
    <example xml:lang="en">
      <para>See the example at <cmd name="Switch"/>.</para>
    </example>
    <example xml:lang="de">
      <para>Siehe das Beispiel bei <cmd name="Switch"/>.</para>
    </example>
    <seealso>
      <cmd name="Switch"/>
    </seealso>
  </command>
  <command en="Switch" de="Fallunterscheidung">
    <description xml:lang="en">
      <para>Description switch</para>
    </description>
    <description xml:lang="de">
      <para>Beschreibung switch.</para>
    </description>
    <childelements>
      <oneOrMore>
        <cmd name="Case"/>
      </oneOrMore>
    </childelements>
    <example xml:lang="en">
      <listing><![CDATA[<dummyexample lang="en" />]]></listing>
    </example>
    <example xml:lang="de">
      <listing><![CDATA[<dummyexample lang="de" />]]></listing>
    </example>
    <info xml:lang="en">
      <para>info en</para>
    </info>
    <info xml:lang="de">
      <para>info de</para>
    </info>
    <seealso>
      <cmd name="Case"/>
    </seealso>
  </command>
    <command en="Barcode" de="Strichcode">
    <description xml:lang="en">
      <para>Print a 1d or 2d barcode. To be used in <cmd name="PlaceObject"/>.</para>
    </description>
    <description xml:lang="de">
    <para>Erzeugt einen 1D oder 2D Strichcode (barcode), der in <cmd name="PlaceObject"/> ausgegeben werden kann.</para>
  </description>
    <childelements/>
    <attribute en="select" de="auswahl" type="xpath" optional="no">
      <description xml:lang="en">
        <para>The data to be encoded in the barcode.</para>
      </description>
      <description xml:lang="de">
        <para>Wert, der als Strichcode kodiert werden soll.</para>
      </description>
    </attribute>
    <attribute en="fontface" de="schriftart" type="text" optional="yes">
      <description xml:lang="en">
        <para>Name of the fontface of the text that can be placed beneath the barcode. Not used in all codes.</para>
      </description>
      <description xml:lang="de">
        <para>Name der Schriftart des Textes, der ggf. unterhalb des Strichcodes ausgegeben wird. Nicht in allen Codes verwendet.</para>
      </description>
    </attribute>
    <attribute en="type" de="typ" optional="no">
      <description xml:lang="en">
        <para>Type of the barcode. One of <tt>EAN13</tt>, <tt>Code128</tt> or <tt>QRCode</tt>.</para>
      </description>
      <description xml:lang="de">
        <para>Typ des Strichcodes. Kann <tt>EAN13</tt>, <tt>Code128</tt> oder <tt>QRCode</tt> sein.</para>
      </description>
      <choice en="QRCode" de="QRCode">
        <description xml:lang="en">
          <para>Create an »optimal« QR code in terms of error correction and size.</para>
        </description>
        <description xml:lang="de">
          <para>Erzeugt einen QR code, der für den Inhalt die kleinstmögliche Größe und den besten Fehlerkorrekturwert hat.</para>
        </description>
      </choice>
      <choice en="Code128" de="Code128">
        <description xml:lang="en">
          <para>Generate a code 128 barcode for numbers and text.</para>
        </description>
        <description xml:lang="de">
          <para>Erzeugt einen Code 128 Barcode für Ziffern und Text (ohne Umlaute)</para>
        </description>
      </choice>
      <choice en="EAN13" de="EAN13">
        <description xml:lang="en">
          <para>Create an EAN13 barcode for 13 digits.</para>
        </description>
        <description xml:lang="de">
          <para>Erzeugt einen EAN13 Barcode mit genau 13 Ziffern.</para>
        </description>
      </choice>
    </attribute>
    <attribute en="width" de="breite" type="numberorlength" optional="yes">
      <description xml:lang="en">
        <para>Width of the barcode</para>
      </description>
      <description xml:lang="de">
        <para>Breite des Strichcodes</para>
      </description>
    </attribute>
    <attribute en="height" de="höhe" type="numberorlength" optional="yes">
      <description xml:lang="en">
        <para>Height of the barcode.</para>
      </description>
      <description xml:lang="de">
        <para>Höhe des Strichcodes.</para>
      </description>
    </attribute>
    <attribute en="showtext" de="zeigetext" optional="yes">
      <description xml:lang="en">
        <para>Should the text be written under the barcode?</para>
      </description>
      <description xml:lang="de">
        <para>Bestimmt, ob unterhalb des Barcodes der Text erscheint.</para>
      </description>
      <choice en="yes" de="ja">
        <description xml:lang="en">
          <para>Write text beneath the barcode.</para>
        </description>
        <description xml:lang="de">
          <para>Text unterhalb des Barcodes schreiben.</para>
        </description>
      </choice>
      <choice en="no" de="nein">
        <description xml:lang="en">
          <para>Don't display text.</para>
        </description>
        <description xml:lang="de">
          <para>Keinen Text anzeigen.</para>
        </description>
      </choice>
    </attribute>
    <attribute en="overshoot" de="übersteigen" optional="yes" type="number">
      <description xml:lang="en">
        <para>The factor denoting the extra length of the outer and middle bar. Only useful with EAN13.</para>
      </description>
      <description xml:lang="de">
        <para>Der Faktor, um den die äußeren und der innere Balken die normalen Balken übersteigt. Nur anwendbar bei EAN13.</para>
      </description>
    </attribute>
    <example xml:lang="en">
      <listing><![CDATA[<PlaceObject>
  <Barcode select="'speedata Publisher'" type="Code 128" showtext="nein"/>
</PlaceObject>]]></listing>
      <listing><![CDATA[<PlaceObject>
  <Barcode select="4242002518169" type="EAN13"/>
</PlaceObject>]]></listing>
    </example>
    <example xml:lang="de">
      <listing><![CDATA[<ObjektAusgeben>
  <Strichcode auswahl="'speedata Publisher'" typ="Code 128" zeigetext="nein"/>
</ObjektAusgeben>]]></listing>
      <listing><![CDATA[<ObjektAusgeben>
  <Strichcode auswahl="4242002518169" typ="EAN13"/>
</ObjektAusgeben>]]></listing>
    </example>
    <seealso><cmd name="PlaceObject"/></seealso>
  </command>

</commands>`
)

func TestAll(t *testing.T) {
	r := strings.NewReader(SRC)
	c, err := ReadCommandsFile(r)
	if err != nil {
		t.Error(err)
	}
	cmd := c.CommandsDe["Fall"]
	{
		exp := "case.html"
		if r := cmd.Htmllink(); r != exp {
			t.Errorf("Expected %q but got %q", exp, r)
		}
	}
	{
		exp := "Fall"
		if r := cmd.Name("de"); r != exp {
			t.Errorf("Expected '%s', but got %s", exp, r)
		}
	}
	{
		exp := "Case"
		if r := cmd.Name("en"); r != exp {
			t.Errorf("Expected '%s', but got %s", exp, r)
		}
	}
	{
		exp := `<p>Descripton of Case, link to <a href="switch.html">Switch</a>. <tt>typewriter</tt>.</p>`
		if r := cmd.DescriptionHTML("en"); string(r) != exp {
			t.Errorf("Expected %q but got %q", exp, r)
		}
	}
	{
		exp := `Descripton of Case, link to Switch. typewriter.`
		if r := cmd.DescriptionText("en"); string(r) != exp {
			t.Errorf("Expected %q but got %q", exp, r)
		}
	}
	aa := cmd.Attributes("de")
	{
		exp := 1
		if r := len(aa); r != exp {
			t.Fatalf("Expected len = %d, but got %d", exp, r)
		}
	}
	att := aa[0]
	{
		exp := "bedingung"
		if r := att.NameDe; r != exp {
			t.Errorf("Expected %q, but got %q", exp, r)
		}
	}
	{
		exp := "<p>Description of test (en)</p>"
		if r := att.DescriptionHTML("en"); string(r) != exp {
			t.Errorf("Expected %q but got %q", exp, r)
		}
	}
	{
		exp := "<p>Description of <tt>test</tt> (de).</p>"
		if r := att.DescriptionHTML("de"); string(r) != exp {
			t.Errorf("Expected %q but got %q", exp, r)
		}
	}
	{
		cmd := c.CommandsEn["Switch"]
		cmds := cmd.Childelements("en")
		{
			exp := 1
			if r := len(cmds); r != exp {
				for _, v := range cmds {
					t.Log(v.NameEn)
				}
				t.Fatalf("Expected len = %d, but got %d", exp, r)
			}
		}
		{
			exp := "Case"
			if r := cmds[0].Name("en"); r != exp {
				t.Errorf("Expected '%s', but got %s", exp, r)
			}

		}
	}
	{
		cmd := c.CommandsEn["Case"]
		cmds := cmd.Childelements("en")
		{
			exp := 1
			if r := len(cmds); r != exp {
				for _, v := range cmds {
					t.Log(v.NameEn)
				}
				t.Fatalf("Expected len = %d, but got %d", exp, r)
			}
		}
		{
			exp := "Barcode"
			if r := cmds[0].Name("en"); r != exp {
				t.Errorf("Expected '%s', but got %s", exp, r)
			}

		}
	}

	cmd = c.CommandsEn["Switch"]
	{
		exp := `<pre class="syntax xml">&lt;dummyexample lang=&#34;en&#34; /&gt;</pre>`
		if r := cmd.Example("en"); string(r) != exp {
			t.Errorf("Expected %q but got %q", exp, r)
		}
	}
	{
		exp1 := []string{"barcode.html", "case.html", "switch.html"}
		exp2 := []string{"Barcode", "Case", "Switch"}
		for i, cmd := range c.CommandsSortedEn {
			if r := cmd.Htmllink(); r != exp1[i] {
				t.Errorf("Expected %q, but got %q", exp1[i], r)
			}
			if r := cmd.NameEn; r != exp2[i] {
				t.Errorf("Expected %q, but got %q", exp2[i], r)
			}
		}
	}
	{
		exp1 := []string{"case.html", "switch.html", "barcode.html"}
		exp2 := []string{"Fall", "Fallunterscheidung", "Strichcode"}
		for i, cmd := range c.CommandsSortedDe {
			if r := cmd.Htmllink(); r != exp1[i] {
				t.Errorf("Expected %q, but got %q", exp1[i], r)
			}
			if r := cmd.NameDe; r != exp2[i] {
				t.Errorf("Expected %q, but got %q", exp2[i], r)
			}
		}
	}
	cmd = c.CommandsEn["Barcode"]
	{
		exp1 := 7
		aa := cmd.Attributes("en")
		if r := len(aa); r != exp1 {
			t.Fatalf("Expected len = %d, but got %d", exp1, r)
		}
		exp5 := "<p>Type of the barcode. One of <tt>EAN13</tt>, <tt>Code128</tt> or <tt>QRCode</tt>.</p>\n<table class=\"attributechoice\">\n<tr><td><p>\nQRCode:\n</p></td><td>\n<p>Create an »optimal« QR code in terms of error correction and size.</p>\n</td></tr>\n<tr><td><p>\nCode128:\n</p></td><td>\n<p>Generate a code 128 barcode for numbers and text.</p>\n</td></tr>\n<tr><td><p>\nEAN13:\n</p></td><td>\n<p>Create an EAN13 barcode for 13 digits.</p>\n</td></tr>\n</table>"
		if r := aa[5].DescriptionHTML("en"); string(r) != exp5 {
			t.Errorf("Expected %q but got %q", exp5, r)
		}

		for _, attr := range aa {
			if attr.NameEn == "type" {
				exp2 := 3
				if r := len(attr.Choice); r != exp2 {
					t.Fatalf("Expected len = %d, but got %d", exp2, r)
				}
				exp3 := "QRCode"
				if r := attr.Choice[0].NameEn; string(r) != exp3 {
					t.Errorf("Expected %q but got %q", exp3, r)
				}
				exp4 := "<p>Create an »optimal« QR code in terms of error correction and size.</p>"
				if r := attr.Choice[0].DescriptionEn.HTML(); string(r) != exp4 {
					t.Errorf("Expected %q but got %q", exp4, r)
				}

			}
		}
		exp6 := 1
		exp7 := "Case"
		p := cmd.Parents("en")
		if r := len(p); r != exp6 {
			t.Fatalf("Expected len = %d, but got %d", exp6, r)
		}
		if r := p[0].NameEn; string(r) != exp7 {
			t.Errorf("Expected %q but got %q", exp7, r)
		}
	}
}
