<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://relaxng.org/ns/structure/1.0"
    xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0">
    <xsl:output omit-xml-declaration="yes" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="pFrom" select="'de'"/>
    <xsl:param name="pTo"   select="'en'"/>
    
    <xsl:key name="en-elements" match="translations/elements/entry" use="@en"/>
    <xsl:key name="de-elements" match="translations/elements/entry" use="@de"/>
    
    <xsl:key name="en-values" match="translations/values/value" use="@en"/>
    <xsl:key name="de-values" match="translations/values/value" use="@de"/>

    <xsl:key name="en-attributes" match="translations/attributes/attribute" use="@en"/>
    <xsl:key name="de-attributes" match="translations/attributes/attribute" use="@de"/>

    <xsl:key name="doc" match="translations/doc/documentation" use="@docid" />

    <xsl:variable name="translations" select="document('translations.xml')"/>
    

    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="grammar" xpath-default-namespace="http://relaxng.org/ns/structure/1.0">
        <xsl:element name="grammar">
            <xsl:namespace name="a" select="'http://relaxng.org/ns/compatibility/annotations/1.0'"></xsl:namespace>
            <xsl:copy-of select="@*" />
            <xsl:attribute name="ns" select="concat('urn:speedata.de:2009/publisher/',$pTo)" />
            <xsl:apply-templates />
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="@name[local-name(..)='element']">
        <xsl:variable name="replace" select="key(concat($pFrom,'-elements'), current(), $translations)/@*[local-name() = $pTo]" />
        <xsl:choose>
            <xsl:when test="empty($replace)">
                <xsl:message select="concat('No translation found for ',current())"></xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="name" select="$replace" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="value" xpath-default-namespace="http://relaxng.org/ns/structure/1.0">
        <xsl:variable name="replace" select="key(concat($pFrom,'-values'), current(), $translations)/@*[local-name() = $pTo]" />
        <xsl:choose>
            <xsl:when test="empty($replace)">
                <xsl:message select="concat('No translation found for ',current())"></xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <value>
                    <xsl:value-of select="$replace"></xsl:value-of>
                </value>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@name[local-name(..)='attribute']">
        <xsl:variable name="replace" select="key(concat($pFrom,'-attributes'), current(), $translations)/@*[local-name() = $pTo]" />
        <xsl:choose>
            <xsl:when test="empty($replace)">
                <xsl:message select="concat('No translation found for ',current())"></xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="name" select="$replace" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="a:documentation">
        <xsl:element name="a:documentation">
            <xsl:attribute name="docid" select="@docid" />
            <xsl:value-of select="key('doc',@docid,$translations)/node()[local-name()=$pTo]" />
        </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>
