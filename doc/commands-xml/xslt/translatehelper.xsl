<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:sd="urn:speedata.de:2011/publisher/documentation/functions"
  xmlns:doc="urn:speedata.de:2011/publisher/documentation"
  xpath-default-namespace="urn:speedata.de:2011/publisher/documentation"
  exclude-result-prefixes="xs"
  version="2.0">

  <xsl:key name="en-commands"   match="translations/elements/element"     use="@key" />
  <xsl:key name="en-attributes" match="translations/attributes/attribute" use="@key" />
  <xsl:key name="en-values"     match="translations/values/value"         use="@key" />

  <xsl:variable name="translations" select="document('../commands.xml')" />
  <xsl:param name="lang" select="'de'"/>

  <xsl:function name="sd:translate-command">
    <xsl:param name="name"/>
    <xsl:value-of select="key('en-commands',$name, $translations)/@*[local-name() = $lang]"/>
  </xsl:function>
  <xsl:function name="sd:translate-attribute">
    <xsl:param name="name"/>
    <xsl:value-of select="key('en-attributes',$name, $translations)/@*[local-name() = $lang]"/>
  </xsl:function>
  <xsl:function name="sd:translate-tvalue">
    <xsl:param name="name"/>
    <xsl:param name="context"/>
    <xsl:value-of select="key('en-values',$name, $translations)[@context = $context]/@*[local-name() = $lang]"/>
  </xsl:function>


</xsl:stylesheet>