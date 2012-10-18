<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0" >
    <xsl:strip-space elements="*"/>
    <xsl:output method="text"/>


  <xsl:key name="en-elements" match="translations/elements/element" use="@key"/>
  <xsl:key name="en-values" match="translations/values/value" use="@key"/>
  <xsl:key name="en-attributes" match="translations/attributes/attribute" use="@key"/>

  <xsl:variable name="languages" select="('de','en')" />

  <xsl:template match="/">
    <xsl:variable name="root" select="." />
    <xsl:text>-- auto generated from genluatranslations.xsl and the source translations.xml&#x0A;</xsl:text>
    <xsl:text>module(...)&#x0A;</xsl:text>
    <xsl:text>return {&#x0A;</xsl:text>
    <xsl:for-each select="$languages">
      <xsl:variable name="current_language" select="." />
      <xsl:value-of select="$current_language" /><xsl:text> = {</xsl:text>
      <xsl:apply-templates select="$root/translations/elements" >
        <xsl:with-param name="current_language" select="." />
      </xsl:apply-templates>
      <xsl:apply-templates select="$root/translations/values" >
        <xsl:with-param name="current_language" select="." />
      </xsl:apply-templates>
      <xsl:text>},</xsl:text>
    </xsl:for-each>
    <xsl:apply-templates select="translations/attributes" />
    <xsl:text>}</xsl:text>
  </xsl:template>
    
    <xsl:template match="translations">
      <xsl:param name="current_language" />
      <xsl:apply-templates  select="elements,values">
      <xsl:with-param name="current_language" select="$current_language" />
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="elements">
    <xsl:param name="current_language" />
        <xsl:text>  </xsl:text><xsl:value-of select="local-name()"/><xsl:text> = {&#x0a;</xsl:text>
        <xsl:apply-templates >
          <xsl:with-param name="current_language" select="$current_language" />
        </xsl:apply-templates>
        <xsl:text>  },&#x0a;</xsl:text>
    </xsl:template>

  <xsl:template match="element">
    <xsl:param name="current_language" />
    <xsl:text>    ["</xsl:text>
    <xsl:value-of select="key('en-elements',@key)/@*[local-name() = $current_language]" />
    <xsl:text>"] = "</xsl:text>
    <xsl:value-of select="@key" />
    <xsl:text>",&#x0a;</xsl:text>
  </xsl:template>
  
  <xsl:template match="attributes">
    <xsl:text>attributes = {&#x0A;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>},&#x0A;</xsl:text>
  </xsl:template>

  <xsl:template match="attribute">
    <xsl:text>    ["</xsl:text><xsl:value-of select="@key" /><xsl:text>"] = {</xsl:text>
    <xsl:variable name="all-attributes" select="@*"/>
    <xsl:for-each select="$languages">
      <xsl:variable name="lang" select="."/>
      <xsl:text></xsl:text><xsl:value-of select="."/><xsl:text> = "</xsl:text>
      <xsl:value-of select="$all-attributes[local-name() = $lang]" /><xsl:text>", </xsl:text>
    </xsl:for-each>
    <xsl:text>},&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="values">
    <xsl:param name="current_language" />
    <xsl:text>values = {&#x0A;</xsl:text>
    <xsl:for-each-group select="value" group-by="@context">
      <xsl:text>["</xsl:text><xsl:value-of select="current-grouping-key()"/><xsl:text>"] = {&#x0A;</xsl:text>
      <xsl:apply-templates select="../value[@context=current-grouping-key()]">
        <xsl:with-param name="current_language" select="$current_language"/>
      </xsl:apply-templates>
      <xsl:text>},&#x0A;</xsl:text>
    </xsl:for-each-group>
    <xsl:text>},&#x0A;</xsl:text>
  </xsl:template>

  <xsl:template match="value">
    <xsl:param name="current_language"/>
    <xsl:text>    ["</xsl:text><xsl:value-of select="@*[local-name()=$current_language]"></xsl:value-of><xsl:text>"] = "</xsl:text>
    <xsl:value-of select="@en"></xsl:value-of>
    <xsl:text>",&#x0a;</xsl:text>
  </xsl:template>

</xsl:stylesheet>