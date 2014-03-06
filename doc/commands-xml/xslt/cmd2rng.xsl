<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs"
  xmlns:sd="urn:speedata.de:2011/publisher/documentation/functions"
  xmlns:sddoc="urn:speedata.de:2011/publisher/documentation"
  xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
  version="2.0">
  <xsl:output indent="yes"/>
  <xsl:include href="translatehelper.xsl"/>


  <xsl:template match="/">
    <xsl:comment>This file is generated from commands.xml by cmd2rng.xsl. Don't edit it!</xsl:comment>
    <xsl:text>&#x0A;</xsl:text>
    <grammar xmlns="http://relaxng.org/ns/structure/1.0"
      ns="urn:speedata.de:2009/publisher/{$lang}">
      <start>
        <ref name="e_Layout"/>
      </start>
      <xsl:apply-templates select="sddoc:commands/*"/>
    </grammar>
  </xsl:template>

  <xsl:template match="sddoc:command" xpath-default-namespace="urn:speedata.de:2011/publisher/documentation">
    <define name="e_{@name}" xmlns="http://relaxng.org/ns/structure/1.0">
      <element name="{sd:translate-command(@name)}">
        <a:documentation><xsl:apply-templates select="description[@xml:lang = $lang]"/></a:documentation>
        <xsl:choose>
          <!-- An element with no child elements must be declared empty -->
          <xsl:when test="count(childelements//cmd) = 0 and count(childelements//reference) = 0 and count(childelements//element) = 0">
            <xsl:apply-templates select="attribute"/>
            <empty/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="attribute"/>
            <xsl:apply-templates select="childelements/text"/>
            <xsl:apply-templates select="childelements"/>
          </xsl:otherwise>
        </xsl:choose>
      </element>
    </define>
  </xsl:template>

  <xsl:template match="sddoc:element" mode="#all">
    <element xmlns="http://relaxng.org/ns/structure/1.0">
      <xsl:attribute name="name" select="@name"/>
      <xsl:apply-templates select="sddoc:*" mode="#current"/>
    </element>
  </xsl:template>

  <xsl:template match="sddoc:empty" mode="#all">
    <empty xmlns="http://relaxng.org/ns/structure/1.0"/>
  </xsl:template>


  <xsl:template match="sddoc:reference" mode="#all">
    <xsl:variable name="thisname" select="@name"/>
    <xsl:apply-templates select="/sddoc:commands/sddoc:define[@name=$thisname]/*"/>
  </xsl:template>

  <xsl:template match="sddoc:oneOrMore | sddoc:choice | sddoc:zeroOrMore | sddoc:optional | sddoc:interleave" mode="#all">
    <xsl:element name="{local-name()}" namespace="http://relaxng.org/ns/structure/1.0">
      <xsl:apply-templates select="sddoc:*" mode="rng"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="sddoc:text" mode="#all">
    <text xmlns="http://relaxng.org/ns/structure/1.0"/>
  </xsl:template>

  <xsl:template match="sddoc:cmd" mode="rng">
    <ref name="e_{@name}"  xmlns="http://relaxng.org/ns/structure/1.0"/>
  </xsl:template>

  <xsl:template match="sddoc:childelements/sddoc:cmd">
    <xsl:choose>
      <xsl:when test="@optional='no'">
        <ref name="e_{@name}"  xmlns="http://relaxng.org/ns/structure/1.0"/>
      </xsl:when>
      <xsl:otherwise>
        <optional xmlns="http://relaxng.org/ns/structure/1.0"><ref name="e_{@name}"/></optional>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="sddoc:define"/>

  <xsl:template match="sddoc:attribute">
    <xsl:choose>
      <xsl:when test="@optional = 'yes'">
        <optional xmlns="http://relaxng.org/ns/structure/1.0">
          <attribute name="{sd:translate-attribute(@name)}">
            <a:documentation><xsl:apply-templates  select="sddoc:description[@xml:lang = $lang]"/></a:documentation>
            <xsl:call-template name="foo"/>
            <xsl:choose>
              <xsl:when test="@type='yesno'">
                <choice>
                  <value><xsl:value-of select="sd:translate-tvalue('yes','*')"/></value>
                  <value><xsl:value-of select="sd:translate-tvalue('no','*')"/></value>
                  <text/>
                </choice>
              </xsl:when>
            </xsl:choose>
          </attribute>
        </optional>
      </xsl:when>
      <xsl:otherwise>
        <attribute name="{sd:translate-attribute(@name)}" xmlns="http://relaxng.org/ns/structure/1.0">
          <a:documentation><xsl:apply-templates  select="sddoc:description[@xml:lang = $lang]"/></a:documentation>
          <xsl:call-template name="foo"/>
        </attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="sddoc:description">
    <xsl:apply-templates select="sddoc:para" mode="annotation"/>
  </xsl:template>

  <xsl:template match="sddoc:cmd" mode="annotation">
    <xsl:value-of select="sd:translate-command(@name)"/>
  </xsl:template>

  <xsl:template name="foo">
    <xsl:choose>
      <xsl:when test="count(sddoc:choice) > 0">
        <choice xmlns="http://relaxng.org/ns/structure/1.0">
          <xsl:apply-templates select="sddoc:choice"/>
        </choice>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="sddoc:attribute/sddoc:choice">
    <!-- * is the default context -->
    <xsl:variable name="context" select="(@context,'*')[1]"/>
    <value xmlns="http://relaxng.org/ns/structure/1.0"><xsl:value-of select="sd:translate-tvalue(@name,$context)"/></value>
    <a:documentation><xsl:apply-templates select="sddoc:description[@xml:lang = $lang]"/></a:documentation>
  </xsl:template>
</xsl:stylesheet>