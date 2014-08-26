<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:doc="urn:speedata.de:2011/publisher/documentation"
    version="2.0" xpath-default-namespace="urn:speedata.de:2011/publisher/documentation" >
    <xsl:strip-space elements="*"/>
    <xsl:output method="text"/>


  <xsl:key name="en-values" match="translations/values/value" use="@key"/>
  <xsl:key name="en-attributes" match="translations/attributes/attribute" use="@key"/>

  <xsl:variable name="languages" select="('de','en')" />

  <xsl:template match="/">
    <xsl:variable name="root" select="doc:commands"/>
    <xsl:text>-- auto generated from genluatranslations.xsl and the source commands.xml&#x0A;</xsl:text>
    <xsl:text>module(...)&#x0A;</xsl:text>
    <xsl:text>return {&#x0A;</xsl:text>
    <xsl:for-each select="$languages">
      <xsl:variable name="current_language" select="." />
      <xsl:value-of select="$current_language" /><xsl:text> = {  elements = {&#x0A;</xsl:text>
      <xsl:for-each select="$root/command">
        <xsl:value-of select="concat('    [&quot;',@*[local-name() = $current_language],'&quot;] = &quot;',@en,'&quot;,&#x0A;')"></xsl:value-of>
      </xsl:for-each>
      <xsl:text>  },&#x0A;</xsl:text>
      <xsl:apply-templates select="$root/translations/values" >
        <xsl:with-param name="current_language" select="." />
      </xsl:apply-templates>
      <xsl:text>},</xsl:text>
    </xsl:for-each>
    <xsl:text>attributes = {&#x0A;</xsl:text>
    <xsl:for-each select="distinct-values(/commands/command/attribute/@en)">
      <xsl:sort select="."/>
      <xsl:variable name="envalue" select="."/>
      <xsl:value-of select="concat('    [&quot;',string(.),'&quot;] = {de = &quot;',($root/command/attribute[@en = $envalue]/@de)[1],'&quot;, en = &quot;',string(.),'&quot;, },&#x0A;')"></xsl:value-of>
    </xsl:for-each>
    <xsl:text>},&#x0A;</xsl:text>
    <xsl:text>}</xsl:text>
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