<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0" >
    <xsl:strip-space elements="*"/>
    <xsl:output method="text"/>
    
    <xsl:template match="/">
        <xsl:text>-- auto generated from genluatranslations.xsl and the source translations.xml&#x0A;</xsl:text>
        <xsl:text>module(...)&#x0A;</xsl:text>
        <xsl:text>return {&#x0A;</xsl:text>
        <xsl:apply-templates select="translations" />
        <xsl:text>}</xsl:text>
    </xsl:template>
    
    <xsl:template match="translations">
        <xsl:apply-templates  select="elements,attributes,values"/>
    </xsl:template>

    <xsl:template match="elements | attributes |values">
        <xsl:text>  </xsl:text><xsl:value-of select="local-name()"/><xsl:text> = {&#x0a;</xsl:text>
        <xsl:apply-templates />
        <xsl:text>  },&#x0a;</xsl:text>
    </xsl:template>

    
    <xsl:template match="element | attribute | value">
        <xsl:text>    ["</xsl:text>
        <xsl:value-of select="@en" /><xsl:text>"] = { de="</xsl:text><xsl:value-of select="@de"/><xsl:text>"},&#x0a;</xsl:text>
    </xsl:template>
 
</xsl:stylesheet>