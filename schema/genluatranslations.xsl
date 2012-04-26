<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0" >
    <xsl:strip-space elements="*"/>
    <xsl:output method="text"/>


  <xsl:key name="en-elements" match="translations/elements/element" use="@en"/>
  <xsl:key name="de-elements" match="translations/elements/element" use="@de"/>

  <xsl:key name="en-values" match="translations/values/value" use="@en"/>
  <xsl:key name="de-values" match="translations/values/value" use="@de"/>

  <xsl:key name="en-attributes" match="translations/attributes/attribute" use="@en"/>
  <xsl:key name="de-attributes" match="translations/attributes/attribute" use="@de"/>

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
          <xsl:with-param name="type" select="local-name()"/>
          <xsl:with-param name="current_language" select="$current_language" />
        </xsl:apply-templates>
        <xsl:text>  },&#x0a;</xsl:text>
    </xsl:template>

  <xsl:template match="element">
    <xsl:param name="type" />
    <xsl:param name="current_language" />
    <xsl:text>    ["</xsl:text>
    <xsl:value-of select="key(concat('en-',$type),@en)/@*[local-name() = $current_language]" />
    <xsl:text>"] = "</xsl:text>
    <xsl:value-of select="@en" />
    <xsl:text>",&#x0a;</xsl:text>
  </xsl:template>
  
  <xsl:template match="attributes">
    <xsl:text>attributes = {&#x0A;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}&#x0A;</xsl:text>
  </xsl:template>

  <xsl:template match="attribute">
    <xsl:text>    ["</xsl:text><xsl:value-of select="@en" /><xsl:text>"] = {</xsl:text>
    <xsl:for-each select="@*">
      <xsl:text></xsl:text><xsl:value-of select="local-name()"/><xsl:text> = "</xsl:text>
      <xsl:value-of select="." /><xsl:text>", </xsl:text>
    </xsl:for-each>
    <xsl:text>},&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="values">
    <xsl:param name="current_language" />
    <xsl:text>  </xsl:text><xsl:value-of select="local-name()"/><xsl:text> = {&#x0a;</xsl:text>
    <xsl:apply-templates >
      <xsl:with-param name="type" select="local-name()"/>
      <xsl:with-param name="current_language" select="$current_language" />
    </xsl:apply-templates>
    <xsl:text>  },&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="value">
    <xsl:param name="type" />
    <xsl:param name="current_language" />
    <xsl:text>    ["</xsl:text>
    <xsl:value-of select="key(concat('en-',$type),@en)/@*[local-name() = $current_language]" />
    <xsl:text>"] = "</xsl:text>
    <xsl:value-of select="@en" />
    <xsl:text>",&#x0a;</xsl:text>
  </xsl:template>

</xsl:stylesheet>