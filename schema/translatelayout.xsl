<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:sdf="urn:speedata.de:2011/publisher/documentation/functions"
  xmlns:layoutde="urn:speedata.de:2009/publisher/de"
  xmlns:layouten="urn:speedata.de:2009/publisher/en"
  exclude-result-prefixes="xs"
  version="2.0">
  
  
  <xsl:template match="/layoutde:Layout" xmlns="urn:speedata.de:2009/publisher/en">
    <Layout xsl:exclude-result-prefixes="sdf layoutde layouten"><xsl:apply-templates mode="detoen"/></Layout>
  </xsl:template>
  
  <xsl:template match="/layouten:Layout" xmlns="urn:speedata.de:2009/publisher/de">
    <Layout xsl:exclude-result-prefixes="sdf layoutde layouten"><xsl:apply-templates mode="entode" /></Layout>
  </xsl:template>
  
  <xsl:template match="*" mode="detoen">
    <xsl:element name="{sdf:translate-command-de(local-name())}" namespace="urn:speedata.de:2009/publisher/en">
      <xsl:apply-templates select="@*" mode="#current"></xsl:apply-templates>
      <xsl:apply-templates  mode="#current"></xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <xsl:template match="*" mode="entode">
    <xsl:element name="{sdf:translate-command-en(local-name())}" namespace="urn:speedata.de:2009/publisher/de">
      <xsl:apply-templates select="@*" mode="#current"></xsl:apply-templates>
      <xsl:apply-templates  mode="#current"/>
    </xsl:element>
  </xsl:template>
  

  <xsl:template match="text()" mode="#all">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="comment()" mode="#all">
    <xsl:copy-of select="."/>
  </xsl:template>
  

  <xsl:template match="@*" mode="detoen">
    <xsl:variable name="translatedvalue" select="sdf:translate-value-de(.)"/>
    <xsl:attribute name="{sdf:translate-attribute-de(local-name())}" select="if ($translatedvalue = '') then . else $translatedvalue"/>    
  </xsl:template>
  <xsl:template match="@*" mode="entode">
    <xsl:variable name="translatedvalue" select="sdf:translate-value-en(.)"/>
    <xsl:attribute name="{sdf:translate-attribute-en(local-name())}" select="if ($translatedvalue = '') then . else $translatedvalue"/>    
  </xsl:template>
  
  <!-- **************************** -->
  
  <xsl:key name="de-commands"   match="translations/elements/element"     use="@de" xpath-default-namespace="" />
  <xsl:key name="de-attributes" match="translations/attributes/attribute" use="@de" xpath-default-namespace="" />
  <xsl:key name="de-values"     match="translations/values/value"         use="@de" xpath-default-namespace="" />
  
  <xsl:key name="en-commands"   match="translations/elements/element"     use="@en" xpath-default-namespace="" />
  <xsl:key name="en-attributes" match="translations/attributes/attribute" use="@en" xpath-default-namespace="" />
  <xsl:key name="en-values"     match="translations/values/value"         use="@en" xpath-default-namespace="" />

  <xsl:variable name="translations" select="document('translations.xml')" />
  
  <xsl:function name="sdf:translate-command-de">
    <xsl:param name="name"/>
    <xsl:value-of select="key('de-commands',$name, $translations)/@en"/>
  </xsl:function>

  <xsl:function name="sdf:translate-command-en">
    <xsl:param name="name"/>
    <xsl:value-of select="key('en-commands',$name, $translations)/@de"/>
  </xsl:function>
  
  <xsl:function name="sdf:translate-attribute-de">
    <xsl:param name="name"/>
    <xsl:value-of select="(key('de-attributes',$name, $translations)/@en)[1]"/>
  </xsl:function>

  <xsl:function name="sdf:translate-attribute-en">
    <xsl:param name="name"/>
    <xsl:value-of select="(key('en-attributes',$name, $translations)/@de)[1]"/>
  </xsl:function>

  <xsl:function name="sdf:translate-value-de">
    <xsl:param name="name"/>
    <xsl:value-of select="key('de-values',$name, $translations)/@en"/>
  </xsl:function>
  
  <xsl:function name="sdf:translate-value-en">
    <xsl:param name="name"/>
    <xsl:value-of select="key('en-values',$name, $translations)/@de"/>
  </xsl:function>
  
  
</xsl:stylesheet>