<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:doc="urn:speedata.de:2011/publisher/documentation"
  xmlns:sd="urn:speedata.de:2011/publisher/documentation/functions"
  exclude-result-prefixes="#all"
  xpath-default-namespace="urn:speedata.de:2011/publisher/documentation"
  version="2.0">
  <xsl:output method="html" indent="yes" encoding="UTF-8"/>

  <xsl:param name="lang" select="'en'"/>
  <xsl:variable name="all-languages" select="('en','de')"/>
  <xsl:variable name="other-languages" select="$all-languages[. ne $lang ]" />

  <xsl:param name="builddir" select="'/tmp/manual/'"></xsl:param>

  <xsl:key name="en-texts"      match="text" use="@key" xpath-default-namespace=""/>
  <xsl:key name="en-commands"   match="translations/elements/element"     use="@en" xpath-default-namespace="" />
  <xsl:key name="en-attributes" match="translations/attributes/attribute" use="@en" xpath-default-namespace="" />

  <xsl:variable name="refs-translations">
    <text key="directories" en="How to generate a table of contents and other directories" de="Wie werden Verzeichnisse erstellt?" />
    <text key="fonts" en="How to use fonts" de="Einbinden von Schriftarten" />
    <text key="cutmarks" en="Cutmarks and bleed" de="Schnittmarken und Beschnittzugabe" />
  </xsl:variable>

  <xsl:variable name="text-translations">
    <text key="Allowed attributes" en="Allowed attributes" de="Erlaubte Attribute" />
    <text key="Child elements" en="Child elements"  de="Kindelemente" />
    <text key="Description" en="Description"     de="Beschreibung"/>
    <text key="Example" en="Example" de="Beispiel"></text>
    <text key="Parent elements" en="Parent elements" de="Elternelemente" />
    <text key="Attributes" en="Attributes" de="Attribute" />
    <text key="See also" en="See also" de="Siehe auch"/>
    <text key="Info" en="Info" de="Hinweis" />
    <text key="Commands" en="Commands" de="Befehlsübersicht" />
    <text key="Startpage" en="Startpage" de="Startseite" />
    <text key="Command reference" en="Command reference" de="Befehlsreferenz" />
    <text key="Other languages" en="Other languages" de="Andere Sprachen" />
    <text key="Remarks" en="Remarks" de="Bemerkungen" />
    <text key="de" en="German" de="Deutsch" />
    <text key="en" en="English" de="Englisch" />
  </xsl:variable>

  <xsl:variable name="translations" select="document('../../../schema/translations.xml')" />
  <xsl:variable name="values">
    <value type="align" de="“right”,“left”,“center”" en="“right”,“left”,“center”" />
    <value type="alignment" de="blocksatz, linksbündig, rechtsbündig, zentriert" en="justified, leftaligned, rightaligned, centered"/>
    <value type="all_first" de="alle / erste" en="all / first" />
    <value type="all_last" de="alle / letzte" en="all / last"/>
    <value type="colormodel" de="rgb oder cmyk" en="rgb or cmyk"/>
    <value type="fullwithout" de="ohne, vollständig" en="full, without" />
    <value type="horizontalvertical" de="horizontal oder vertikal" en="horizontal or vertical"/>
    <value type="languages" de="Sprache" en="language"/>
    <value type="leftright" de="'links' oder 'rechts'" en="'left' or 'right'" />
    <value type="length" de="Längenangabe (mm,cm,pt)" en="Length (mm,in,cm,pt)"/>
    <value type="maxno" de="'max', 'nein'" en="'max', 'no'" />
    <value type="number" de="Zahl" en="number"/>
    <value type="numberlengthorstar" de="Zahl, Maßangabe oder *-Angaben" en="Number, length or *-numbers" />
    <value type="numberorlength" de="Zahl oder Längenangabe" en="number or length" />
    <value type="solidwithout" de="›durchgezogen‹, ›ohne‹" en="'solid' or 'without'" />
    <value type="text"  de="Text" en="string" />
    <value type="topmiddlebottom" de="'top', 'middle' oder 'bottom'" en="'top', 'middle' or 'bottom'" />
    <value type="valign" de="“top”,“middle”,“bottom”" en="“top”,“middle”,“bottom”" />
    <value type="xpath" de="XPath-Ausdruck" en="XPath expression"/>
    <value type="yesno" de="ja/nein" en="yes/no"/>
    <value type="yesnoauto" de="›ja‹, ›nein‹ oder ›auto‹" en="'yes', 'no' or 'auto'"/>
    <value type="zerotohundred" de="0 bis 100" en="0 up to 100"/>
  </xsl:variable>
  
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="commands">
    <xsl:for-each select="command">
        <xsl:result-document href="{concat($builddir,'/commands-',$lang,'/',lower-case(@name),'.html')}">
          <xsl:variable name="htmlpage" select="concat('commands-',$lang,'/',lower-case(@name),'.html')"/>
          <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html></xsl:text>
        <html>
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
            <link rel="stylesheet" href="../css/normal.css" type="text/css" />
            <script src="../javascript/jquery.min.js" type="text/javascript"></script>
            <script src="../javascript/jquery.syntax.min.js" type="text/javascript"></script>
            <script type="text/javascript">
               // This function is executed when the page has finished loading.
             jQuery(function($) {
             // This function highlights (by default) pre and code tags which are annotated correctly.
             $.syntax();
             });
            </script>
            <title><xsl:value-of select="@name"/></title>
          </head>
          <body>
            <div id="logo">
            <xsl:choose>
              <xsl:when test="$lang = 'de'">
                <a href="../index-de.html"><img src="../images/publisher_logo.png" alt="Startseite"/></a>    
              </xsl:when>
              <xsl:otherwise>
                <a href="../index.html"><img src="../images/publisher_logo.png" alt="Start page"/></a>    
              </xsl:otherwise>
            </xsl:choose>
            </div>
              <xsl:apply-templates select="." >
                <xsl:with-param name="pagename" select="$htmlpage"/>
              </xsl:apply-templates>
          </body>
        </html>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="command">
    <xsl:param name="pagename"/>
    <xsl:message select="concat('&quot;',sd:translate-command(@name),'&quot;,&quot;Function&quot;,&quot;',$pagename,'&quot;')"/>
    <div id="elementdesc">
      <h1>Elementname: <code class="syntax xml"><xsl:value-of select="sd:translate-command(@name)" /></code></h1>
      <h2><xsl:value-of select="sd:translate-text('Description')"></xsl:value-of></h2>
      <xsl:for-each select="description[@xml:lang = $lang]/para">
        <p>
          <xsl:apply-templates />
        </p>
      </xsl:for-each>
      <p><xsl:value-of select="sd:translate-text('Allowed attributes')"></xsl:value-of><xsl:text>: </xsl:text> <xsl:for-each select="attribute">
          <xsl:sort select="sd:translate-attribute(@name)" />
          <span class="tt"><a href="#{@name}"><xsl:value-of select="sd:translate-attribute(@name)"
               /></a></span>
          <xsl:if test=" position() &lt; last()">, </xsl:if>
        </xsl:for-each><br/>
        <xsl:value-of select="sd:translate-text('Child elements')"/><xsl:text>: </xsl:text>
        <xsl:for-each select="childelements/cmd">
          <xsl:sort select="sd:translate-command(@name)"/>
          <a href="{sd:makelink(@name)}"><xsl:value-of select="sd:translate-command(@name)"/></a>
          <xsl:if test="position() &lt; last()">, </xsl:if>
        </xsl:for-each>
        <br/>
        <xsl:value-of select="sd:translate-text('Parent elements')"/><xsl:text>: </xsl:text>
        <xsl:for-each select="parentelements/cmd">
          <xsl:sort select="sd:translate-command(@name)"/>
          <a href="{sd:makelink(@name)}"><xsl:value-of select="sd:translate-command(@name)"/></a>
          <xsl:if test="position() &lt; last()">, </xsl:if>
        </xsl:for-each>
      </p>
      <h3><xsl:value-of select="sd:translate-text('Attributes')"/></h3>
      <dl>
        <xsl:for-each select="attribute">
          <xsl:sort select="sd:translate-attribute(@name)" />
          <xsl:message select="concat('&quot;',sd:translate-attribute(@name),'&quot;,&quot;Parameter&quot;,&quot;',$pagename,'#',@name,'&quot;')"/>
          <dt>
            <a name="{@name}" />
            <span class="tt">
              <xsl:value-of select="sd:translate-attribute(@name)" />
            </span>
            <xsl:text> (</xsl:text>
            <xsl:value-of select="sd:translate-value(@type)" />
            <xsl:choose>
              <xsl:when test="@optional = 'yes'">
                <xsl:text>, optional</xsl:text>
              </xsl:when>
            </xsl:choose>
            <xsl:text>)</xsl:text>
          </dt>
          <dd>
            <xsl:apply-templates select="description[@xml:lang = $lang]" />
          </dd>
        </xsl:for-each>
      </dl>
      <xsl:apply-templates select="remark[@xml:lang = $lang]" />
      <xsl:apply-templates select="example[@xml:lang = $lang]" />
      <xsl:apply-templates select="info[@xml:lang = $lang]" />
      <xsl:apply-templates select="seealso" />
    </div>
    <div id="elementref">
      <h1><xsl:value-of select="sd:translate-text('Commands')"/></h1>
      <ul>
        <xsl:apply-templates select=" parent::node()" mode="commandlist">
          <xsl:with-param name="currentcommand" select="@name" />
        </xsl:apply-templates>
      </ul>
    </div>
    <xsl:variable name="commandname" select="@name"/>
    <div style="clear:both; border-bottom: 1px solid #a0a0a0; width: 100%"></div>
    <xsl:choose>
      <xsl:when test="$lang='de'">
        <a href="../index-de.html">Startseite</a>
      </xsl:when>
      <xsl:otherwise>
        <a href="../index.html">Start page</a>
      </xsl:otherwise>
    </xsl:choose>
     |
    <a href="../commands-{$lang}/layout.html"><xsl:value-of select="sd:translate-text('Command reference')"/></a> |
      <xsl:value-of select="sd:translate-text('Other languages')"/><xsl:text>: </xsl:text>
    <xsl:for-each select="$other-languages">
      <a href="../commands-{.}/{sd:makelink($commandname)}"><xsl:value-of select="sd:translate-text(.)"></xsl:value-of></a>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="remark">
    <h3><xsl:value-of select="sd:translate-text('Remarks')"/></h3>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="info">
    <h2><xsl:value-of select="sd:translate-text('Info')"/></h2>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="example">
    <h2><xsl:value-of select="sd:translate-text('Example')"/></h2>
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="listing">
    <pre class="syntax xml"><xsl:value-of select="."/></pre>
  </xsl:template>

  <xsl:template match="seealso">
    <h2><xsl:value-of select="sd:translate-text('See also')"/></h2>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="commands" mode="commandlist">
    <xsl:param name="currentcommand"/>
    <xsl:for-each select="command">
      <xsl:sort select="sd:translate-command(@name)"/>
      <li>
      <xsl:choose>
        <xsl:when test="@name = $currentcommand">
          <xsl:attribute name="class" select="'active'"/>
        </xsl:when>
      </xsl:choose>
        <a href="{sd:makelink(@name)}"><xsl:value-of select="sd:translate-command(@name)"/></a>
      </li>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="para"><p><xsl:apply-templates/></p></xsl:template>
  <xsl:template match="tt">
    <span class="tt"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="cmd">
    <a href="{sd:makelink(@name)}"><xsl:value-of select="sd:translate-command(@name)"/></a>
  </xsl:template>

  <xsl:template match="ref">
    <a href="../description-{$lang}/{@name}.html"><xsl:value-of select="sd:translate-ref(@name)"/></a>
  </xsl:template>

  <xsl:function name="sd:makelink">
    <xsl:param name="name"/>
    <xsl:value-of select="concat(encode-for-uri(lower-case($name)),'.html')"/>
  </xsl:function>

  <xsl:function name="sd:translate-attribute">
    <xsl:param name="name"/>
    <xsl:value-of select="key('en-attributes',$name, $translations)/@*[local-name() = $lang]"/>
  </xsl:function>

  <xsl:function name="sd:translate-command">
    <xsl:param name="name"/>
    <xsl:value-of select="key('en-commands',$name, $translations)/@*[local-name() = $lang]"/>
  </xsl:function>

  <xsl:function name="sd:translate-value">
    <xsl:param name="type"/>
    <xsl:value-of select="$values/*[@type = $type]/@*[local-name() = $lang]"/>
  </xsl:function>

  <xsl:function name="sd:translate-text">
    <xsl:param name="name"/>
    <xsl:value-of select="key('en-texts',$name,$text-translations)/@*[local-name() = $lang]"></xsl:value-of>
  </xsl:function>

  <xsl:function name="sd:translate-ref">
    <xsl:param name="name"/>
    <xsl:value-of select="key('en-texts',$name,$refs-translations)/@*[local-name() = $lang]"></xsl:value-of>
  </xsl:function>

</xsl:stylesheet>