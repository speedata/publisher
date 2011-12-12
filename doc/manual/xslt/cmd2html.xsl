<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:doc="urn:speedata.de:2011/publisher/documentation"
  exclude-result-prefixes="#all"
  xpath-default-namespace="urn:speedata.de:2011/publisher/documentation"
  version="2.0">
  <xsl:strip-space elements="*"/>
  <xsl:output method="html" indent="yes"></xsl:output>
  <xsl:param name="lang" select="'de'"/>
  
  <xsl:param name="builddir" select="'../../../build/manual/'"></xsl:param>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="commands">
    <xsl:for-each select="command">
      <xsl:result-document href="{concat($builddir,'/commands/',@name,'.html')}">
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
      <h1>Elementname: <code class="syntax xml"><xsl:value-of select="@name"/></code></h1>
    <h2>Beschreibung</h2>
    <xsl:for-each select="description[@xml:lang = $lang]/para">
      <p><xsl:value-of select="."></xsl:value-of></p>
    </xsl:for-each>
    <p>Erlaubte Attribute:
      <xsl:for-each select="attribute">
      <span class="tt"><xsl:value-of select="@name"/></span>
        <xsl:if test=" position() &lt; last()">, </xsl:if>
    </xsl:for-each>
    </p>
    <h3>Attribute</h3>
    <dl>
      <xsl:for-each select="attribute">
        <dt><xsl:value-of select="@name"/>
          <xsl:text> (</xsl:text><xsl:choose>
            <xsl:when test="@type='xpath'">
              <xsl:text>XPath-Ausdruck</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>???</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
            <xsl:when test="@optional = 'yes'">
              <xsl:text>, optional</xsl:text>
            </xsl:when>
          </xsl:choose>
          <xsl:text>)</xsl:text></dt>
        <dd><xsl:apply-templates select="."/></dd>
      </xsl:for-each>
    </dl>
    <xsl:apply-templates select="remark[@xml:lang = $lang]"/>
    <xsl:apply-templates select="example[@xml:lang = $lang]"/>
    <xsl:apply-templates select="seealso" />
    </div>
    <div id="elementref">
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
      <li>
      <xsl:choose>
        <xsl:when test="@name = $currentcommand">
          <xsl:attribute name="class" select="'active'"></xsl:attribute>
        </xsl:when>
      </xsl:choose>
        <a href="{concat(@name,'.html')}"><xsl:value-of select="@name"/></a>
      </li>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="para"><p><xsl:apply-templates/></p></xsl:template>
  <xsl:template match="tt">
    <span class="tt"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="cmd">
    <a href="{@name}.html"><xsl:value-of select="@name"></xsl:value-of></a>
  </xsl:template>
</xsl:stylesheet>