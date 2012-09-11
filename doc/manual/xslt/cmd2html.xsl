<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:doc="urn:speedata.de:2011/publisher/documentation"
  xmlns:sd="urn:speedata.de:2011/publisher/documentation/functions"
  exclude-result-prefixes="#all"
  xpath-default-namespace="urn:speedata.de:2011/publisher/documentation"
  version="2.0">
  <xsl:strip-space elements="*"/>
  <xsl:output method="html" indent="yes" encoding="UTF-8"/>

  <xsl:param name="lang" select="'de'"/>

  <xsl:param name="builddir" select="'../../../build/manual/'"></xsl:param>

  <xsl:key name="en-commands"   match="translations/elements/element"     use="@en" xpath-default-namespace="" />
  <xsl:key name="en-attributes" match="translations/attributes/attribute" use="@en" xpath-default-namespace="" />

  <xsl:variable name="translations" select="document('../../../schema/translations.xml')" />
  <xsl:variable name="values">
    <value type="xpath" de="XPath-Ausdruck" en="XPath expression"/>
    <value type="languages" de="Sprache" en="language"/>
    <value type="number" de="Zahl" en="number"/>
    <value type="yesno" de="ja/nein" en="yes/no"/>
    <value type="text"  de="Text" en="string" />
    <value type="zerotohundred" de="0 bis 100" en="0 up to 100"/>
    <value type="colormodel" de="rgb oder cmyk" en="rgb or cmyk"/>
    <value type="numberorlength" de="Zahl oder Längenangabe" en="number or length" />
    <value type="alignment" de="blocksatz, linksbündig, rechtsbündig, zentriert" en="justified, leftaligned, rightaligned, centered"/>
    <value type="length" de="Längenangabe (mm,cm,pt)" en="Length (mm,in,cm,pt)"/>
    <value type="horizontalvertical" de="horizontal oder vertikal" en="horizontal or vertical"/>
  </xsl:variable>
  
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="commands">
    <xsl:for-each select="command">
      <xsl:result-document href="{concat($builddir,'/commands-',$lang,'/',@name,'.html')}">
        <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html></xsl:text>
        <html>
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
            <link rel="stylesheet" href="../css/normal.css" type="text/css" />
            <title><xsl:value-of select="@name"></xsl:value-of></title>
          </head>
          <body>
            <div id="logo"><a href="../index.html"><img src="../images/publisher_logo.png" alt="Startseite"/></a></div>
              <xsl:apply-templates select="." />
          </body>
        </html>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="command">
    <div id="elementdesc">
      <h1>Elementname: <code class="syntax xml"><xsl:value-of select="sd:translate-command(@name)" /></code></h1>
      <h2>Beschreibung</h2>
      <xsl:for-each select="description[@xml:lang = $lang]/para">
        <p>
          <xsl:apply-templates />
        </p>
      </xsl:for-each>
      <p>Erlaubte Attribute: <xsl:for-each select="attribute">
          <xsl:sort select="sd:translate-attribute(@name)" />
          <span class="tt"><a href="#{@name}"><xsl:value-of select="sd:translate-attribute(@name)"
               /></a></span>
          <xsl:if test=" position() &lt; last()">, </xsl:if>
        </xsl:for-each><br/>
        Kindelemente:
        <xsl:for-each select="childelements/cmd">
          <xsl:sort select="sd:translate-command(@name)"/>
          <a href="{sd:makelink(@name)}"><xsl:value-of select="sd:translate-command(@name)"/></a>
          <xsl:if test="position() &lt; last()">, </xsl:if>
        </xsl:for-each>
        <br/>
        Elternelemente:
        <xsl:for-each select="parentelements/cmd">
          <xsl:sort select="sd:translate-command(@name)"/>
          <a href="{sd:makelink(@name)}"><xsl:value-of select="sd:translate-command(@name)"/></a>
          <xsl:if test="position() &lt; last()">, </xsl:if>
        </xsl:for-each>
      </p>
      <h3>Attribute</h3>
      <dl>
        <xsl:for-each select="attribute">
          <xsl:sort select="sd:translate-attribute(@name)" />
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
      <h1>Befehlsübersicht</h1>
      <ul>
        <xsl:apply-templates select=" parent::node()" mode="commandlist">
          <xsl:with-param name="currentcommand" select="@name" />
        </xsl:apply-templates>
      </ul>
    </div>
    <div style="clear:both; border-bottom: 1px solid #a0a0a0; width: 100%"></div>
    <a href="../index.html">Startseite</a> | <a href="../referenz/e_layout.html">Elementreferenz</a>
  </xsl:template>

  <xsl:template match="remark">
    <h3>Bemerkungen</h3>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="info">
    <h2>Hinweise</h2>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="example">
    <h2>Beispiel</h2>
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="listing">
    <pre><xsl:value-of select="."></xsl:value-of></pre>
  </xsl:template>

  <xsl:template match="seealso">
    <h2>Siehe auch</h2>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="commands" mode="commandlist">
    <xsl:param name="currentcommand"/>
    <xsl:for-each select="command">
      <xsl:sort select="sd:translate-command(@name)"></xsl:sort>
      <li>
      <xsl:choose>
        <xsl:when test="@name = $currentcommand">
          <xsl:attribute name="class" select="'active'"></xsl:attribute>
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
</xsl:stylesheet>