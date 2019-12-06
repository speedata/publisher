<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:xl="http://www.w3.org/1999/xlink"
  xmlns:sd="urn:speedata"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  version="2.0"
  >
  <xsl:param name="outputdir"/>
  <xsl:output method="text"/>
  <xsl:variable name="contentdir" select="concat($outputdir,'/content')"/>
  <xsl:variable name="partialdir" select="concat($outputdir,'/layouts/partials')"/>

  <xsl:template match="/book">
    <xsl:result-document  href="{$partialdir}/tableofcontent.html" method="html">
      <xsl:apply-templates select="preface | chapter | appendix" mode="tocsidebar"/>
    </xsl:result-document>
    <xsl:apply-templates select="preface | chapter | appendix"/>
  </xsl:template>

  <xsl:template match="preface" mode="tocsidebar">
    <li xsl:exclude-result-prefixes="#all">
      <xsl:text>{{ partial `gotoindex.html` . }}</xsl:text>
    </li>
  </xsl:template>

  <xsl:template match="chapter | appendix" mode="tocsidebar">
    <li xsl:exclude-result-prefixes="#all">
      <xsl:copy-of select="sd:ahrefto(@xml:id,title,.)"/>
      <xsl:choose>
        <xsl:when test="@role = 'split' and section">
          <ul xsl:exclude-result-prefixes="#all">
            <xsl:apply-templates select="section" mode="#current"/>
          </ul>
        </xsl:when>
      </xsl:choose>
    </li>
  </xsl:template>

  <xsl:template match="section" mode="tocsidebar">
    <li xsl:exclude-result-prefixes="#all">
      <xsl:copy-of select="sd:ahrefto(@xml:id,title,.)"/>
    </li>
  </xsl:template>


  <xsl:function name="sd:filename-from-id">
    <xsl:param name="idref"/>
    <xsl:value-of select="concat($idref, '.md')"/>
  </xsl:function>


  <!-- breadcrumb = [ ["Startseite","index.md"], ["Grundlagen", "ch-grundlagen.md" ]]  -->
  <xsl:function name="sd:breadcrumb">
    <xsl:param name="focus"/>
    <!--<xsl:text>[ ["Startseite","_index.md"] </xsl:text>-->
    <xsl:text>[  </xsl:text>
    <xsl:for-each select="$focus/ancestor-or-self::node()[local-name() = ('section','chapter', 'appendix')] ">
      <xsl:choose>
        <xsl:when test="position() > 1">
          <xsl:text>,</xsl:text>
        </xsl:when>
      </xsl:choose>
      <xsl:text>["</xsl:text>
      <xsl:value-of select="title"/>
      <xsl:text>","</xsl:text>
      <xsl:value-of select="sd:filename-from-id(@xml:id)"/>
      <xsl:text>"]</xsl:text>
    </xsl:for-each>
    <xsl:text>]</xsl:text>
  </xsl:function>

  <xsl:function name="sd:frontmatter">
    <xsl:param name="addslug" as="xs:boolean"/>
    <xsl:param name="ptitle"/>
    <xsl:param name="context"/>
    <xsl:param name="prevsection"/>
    <xsl:param name="nextsection"/>
    <xsl:text>+++</xsl:text>
    <xsl:text>&#x0a;</xsl:text>
    <xsl:text>title = "</xsl:text>
    <xsl:choose>
      <xsl:when test="$addslug">
        <xsl:value-of select="$ptitle"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>speedata Publisher Handbuch</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>"</xsl:text>
    <xsl:text>&#x0a;</xsl:text>
    <xsl:choose>
      <xsl:when test="$addslug">
        <xsl:text>slug = "</xsl:text>
        <xsl:value-of select="replace($context/../@xml:id,'^(.*-)(.*)', '$2')"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="replace($context/@xml:id,'^(.*-)(.*)', '$2')"/>
        <xsl:text>"</xsl:text>
        <xsl:text>&#x0a;</xsl:text>
        <xsl:text>breadcrumb = </xsl:text>
        <xsl:value-of select="sd:breadcrumb($context)"/>
        <xsl:text>&#x0a;</xsl:text>
         <xsl:text>prevnext = [ [ </xsl:text>
        <xsl:choose>
          <xsl:when test="$prevsection/@xml:id != ''">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="$prevsection/title"/>
            <xsl:text>","</xsl:text>
            <xsl:value-of select="$prevsection/@xml:id"/>
            <xsl:text>.md"</xsl:text>
          </xsl:when>
        </xsl:choose>
        <xsl:text>], [</xsl:text>
        <xsl:choose>
          <xsl:when test="$nextsection/@xml:id != ''">
            <xsl:text>"</xsl:text>
            <xsl:value-of select="$nextsection/title"/>
            <xsl:text>","</xsl:text>
            <xsl:value-of select="$nextsection/@xml:id"/>
            <xsl:text>.md"</xsl:text>
          </xsl:when>
        </xsl:choose>
        <xsl:text>] ]&#x0a;</xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:text>&#x0a;</xsl:text>
    <xsl:text>+++</xsl:text>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:function>

  <xsl:template match="preface">
    <xsl:result-document href="{$contentdir}/_index.md" method="text">
      <xsl:value-of select="sd:frontmatter(false(),'',.,(),())"/>
      <xsl:apply-templates/>
    </xsl:result-document>
  </xsl:template>

  <xsl:template match="chapter | appendix">
    <xsl:result-document href="{$contentdir}/{@xml:id}.md" method="text">
      <xsl:variable name="prevsection" select="(preceding-sibling::*[local-name() = ('appendix','chapter')][position() = 1 and @role = 'split']/section[last()], preceding::*[local-name() = ('appendix','chapter')][1])[1] "/>
      <xsl:variable name="nextsection" select="if (@role = 'split') then (child::section[1], following::chapter[1])[1] else following::*[local-name() = ('appendix','chapter')][1] "/>
      <xsl:value-of select="sd:frontmatter(true(),title,.,$prevsection,$nextsection)"/>

      <xsl:apply-templates/>

    </xsl:result-document>
  </xsl:template>

  <xsl:template match="section">
    <xsl:choose>
      <xsl:when test="..[@role = 'split']">
        <xsl:result-document href="{$contentdir}/{@xml:id}.md" method="text">
          <xsl:variable name="prevsection" select="(preceding-sibling::section[1],ancestor::chapter[1])[1]"/>
          <xsl:variable name="nextsection" select="(following-sibling::section[1],following::chapter[1])[1]"/>
          <xsl:value-of select="sd:frontmatter(true(),title,.,$prevsection,$nextsection)"/>
          <xsl:apply-templates/>
        </xsl:result-document>
        <xsl:apply-templates select="." mode="toc"/>
      </xsl:when>
      <xsl:when test="@role = 'epub'">
        <xsl:text>{{% epub %}}&#x0a;</xsl:text>
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="sd:ahrefto">
    <xsl:param name="pcmd" as="xs:string"/>
    <xsl:param name="ptitle" as="node()"/>
    <xsl:param name="focus"/>

    <xsl:variable name="elt" select="root($focus)//*[@xml:id = $pcmd]"/>
    <xsl:variable name="parent" select="($elt/ancestor-or-self::section[../@role = 'split'],$elt/ancestor-or-self::chapter, $elt/ancestor-or-self::appendix)[1]"/>
    <xsl:element name="a">
      <xsl:attribute name="href">
        <xsl:text>{{ ref . `</xsl:text>
        <xsl:text></xsl:text>
        <xsl:value-of select="sd:filename-from-id($parent/@xml:id)"/>
        <xsl:choose>
          <xsl:when test="not($pcmd = $parent/@xml:id)">
            <xsl:text>#</xsl:text>
            <xsl:value-of select="$pcmd"/>
          </xsl:when>
        </xsl:choose>
        <xsl:text>` }}</xsl:text>
      </xsl:attribute>
      <xsl:value-of select="$ptitle"/>
    </xsl:element>
  </xsl:function>



  <xsl:function name="sd:linkto">
    <xsl:param name="pcmd" as="xs:string"/>
    <xsl:param name="ptitle" as="node()"/>
    <xsl:param name="focus"/>

    <xsl:variable name="elt" select="root($focus)//*[@xml:id = $pcmd]"/>
    <xsl:variable name="parent" select="($elt/ancestor-or-self::section[../@role = 'split'],$elt/ancestor-or-self::chapter, $elt/ancestor-or-self::appendix)[1]"/>
    <xsl:text>[</xsl:text>
    <xsl:value-of select="$ptitle"/>
    <xsl:text>]({{&lt;ref "</xsl:text>
    <xsl:value-of select="sd:filename-from-id($parent/@xml:id)"/>
    <xsl:choose>
      <xsl:when test="not($pcmd = $parent/@xml:id)">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="$pcmd"/>
      </xsl:when>
    </xsl:choose>
    <xsl:text>">}})</xsl:text>
  </xsl:function>

  <xsl:template match="section" mode="toc">
    <xsl:text>* </xsl:text>
    <xsl:value-of select="sd:linkto(@xml:id,title,.)"/>
  </xsl:template>

  <xsl:template match="bridgehead">
    <xsl:choose>
    <xsl:when test="@renderas = ('sect3','sect4')">
        <xsl:text>### </xsl:text>
      </xsl:when>
      <xsl:when test="@renderas = 'sect2'">
        <xsl:text>## </xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:apply-templates></xsl:apply-templates>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>



  <xsl:template match="title">
    <xsl:variable name="parent" select="local-name(..)"/>
    <xsl:choose>
      <xsl:when test="$parent = ('chapter','preface','appendix')">
        <xsl:text># </xsl:text>
      </xsl:when>
      <xsl:when test="$parent = 'section'">
        <xsl:for-each select="1 to count(ancestor::section[not(../@role = 'split')]) + 1 ">#</xsl:for-each>
        <xsl:text> </xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:apply-templates />
    <xsl:choose>
      <xsl:when test="$parent = 'section'">
        <xsl:value-of select="concat(' {#', ../@xml:id, '}')"/>
      </xsl:when>
    </xsl:choose>
    <xsl:text>&#x0a;</xsl:text>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="programlisting">
    <xsl:text>{{&lt; highlight </xsl:text>
    <xsl:value-of select="@language"/>
    <xsl:text> >}}&#x0a;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#x0a;</xsl:text>
    <xsl:text>{{&lt; /highlight >}}</xsl:text>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="screen | literallayout">
    <xsl:text>&#x0a;</xsl:text>
    <xsl:text>````</xsl:text>
    <xsl:text>&#x0a;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#x0a;</xsl:text>
    <xsl:text>````</xsl:text>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:function name="sd:nth-callout">
    <xsl:param name="n" as="xs:integer"/>
    <!--
    <xsl:value-of select="('&#10102;','&#10103;','&#10104;','&#10105;')[$n]"/>
    -->
    <xsl:value-of select="('&#9312;','&#9313;','&#9314;','&#9315;')[$n]"/>

  </xsl:function>

  <!-- callout  -->
  <xsl:template match="co">
    <xsl:value-of select="sd:nth-callout(replace(@xml:id,'^.*-(.*)$','$1') cast as xs:integer)"/>
  </xsl:template>

  <xsl:template match="calloutlist">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="callout">
    <xsl:value-of select="sd:nth-callout(replace(@arearefs,'^.*-(.*)$','$1') cast as xs:integer)"/>
    <xsl:apply-templates></xsl:apply-templates>
  </xsl:template>

  <!-- itemize -->
  <xsl:template match="itemizedlist">
    <xsl:text>&#x0a;</xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="itemizedlist/listitem">
    <xsl:text>* </xsl:text>
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="orderedlist">
    <xsl:text>&#x0a;</xsl:text>
    <xsl:text>{{% ol %}}</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>{{% /ol %}}&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="orderedlist/listitem">
    <xsl:text>{{% li %}}</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>{{% /li %}}</xsl:text>
  </xsl:template>


  <xsl:template match="variablelist">
    <xsl:text><![CDATA[<dl>]]></xsl:text>
    <xsl:apply-templates />
    <xsl:text><![CDATA[</dl>]]>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="term">
    <xsl:text><![CDATA[<dt>{{% markdownify %}}]]></xsl:text>
    <xsl:apply-templates />
    <xsl:text><![CDATA[{{% /markdownify %}}</dt>]]></xsl:text>
  </xsl:template>

  <xsl:template match="varlistentry">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="varlistentry/listitem">
    <xsl:text><![CDATA[<dd><p>{{% markdownify %}}]]></xsl:text>
    <xsl:apply-templates />
    <xsl:text><![CDATA[{{% /markdownify %}}</p></dd>]]></xsl:text>
  </xsl:template>


  <!-- images -->
  <xsl:template match="mediaobject">
    <xsl:text>&#x0a;</xsl:text>
    <xsl:text>&lt;img src="/</xsl:text>
    <xsl:value-of select="imageobject/imagedata/@fileref"/>
    <xsl:text>" width="</xsl:text>
    <xsl:value-of select="imageobject/imagedata/(@width,@contentwidth)[1]"/>
    <xsl:text>"&gt;</xsl:text>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="informalfigure">
    <xsl:apply-templates select="*"></xsl:apply-templates>
  </xsl:template>

  <xsl:template match="figure">
    <xsl:text>{{% figure src="/</xsl:text>
    <xsl:value-of select="mediaobject/imageobject/imagedata/@fileref"/>
    <xsl:text>" id="</xsl:text>
    <xsl:value-of select="@xml:id"/>
    <xsl:text>" alt="</xsl:text>
    <xsl:value-of select="mediaobject/textobject/phrase"/>
    <xsl:text>" width="</xsl:text>
    <xsl:value-of select="mediaobject/imageobject/imagedata/(@width,@contentwidth)[1]"/>
    <xsl:text>" %}}</xsl:text>
    <xsl:apply-templates select="title"/>
    <xsl:text>{{% /figure %}}</xsl:text>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="blockquote">
      <xsl:text>{{% quoteblock attribution="</xsl:text>
    <xsl:value-of select="normalize-space(attribution)"/>
    <xsl:text>"%}}</xsl:text>
      <xsl:apply-templates select="simpara"/>
      <xsl:text>{{% /quoteblock %}}
</xsl:text>
  </xsl:template>

  <!-- Querverweise -->
  <xsl:template match="xref">
    <xsl:variable name="linkend" select="@linkend"/>
    <xsl:value-of select="sd:linkto(@linkend,//*[@xml:id = $linkend]/title ,.)"/>
  </xsl:template>

  <xsl:template match="link">
    <xsl:choose>
      <xsl:when test="../local-name() = 'literal'">
        <xsl:value-of select="@xl:href"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="title">
          <xsl:apply-templates select="* | text()"/>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="not(empty(@xl:href))">
            <xsl:value-of select="concat('[',$title,'](',  @xl:href, ')')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="sd:linkto(@linkend,$title, .)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="indexterm">
    <!-- ignore indexterms for now -->
  </xsl:template>
  <xsl:template match="literal">
    <xsl:text>`</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>`</xsl:text>
  </xsl:template>

  <xsl:template match="tip | warning ">
    <xsl:text>{{% admon %}}</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>{{% /admon %}}
</xsl:text>
  </xsl:template>

  <xsl:template match="simpara | para">
    <xsl:apply-templates></xsl:apply-templates>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="emphasis">
    <xsl:choose>
      <xsl:when test="not( ancestor::node()[local-name() =  'programlisting'])">
        <xsl:choose>
          <xsl:when test="@role = 'strong'">
            <xsl:text>**</xsl:text><xsl:apply-templates/><xsl:text>**</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>_</xsl:text><xsl:apply-templates/><xsl:text>_</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="text()">
    <xsl:variable name="a" select="replace(.,'&#x200B;','')"/>
    <xsl:variable name="b" select="replace($a,'…','.​..')"/>
    <xsl:variable name="c" select="replace($b,'&#8211;','-')"/>
    <xsl:value-of select="$c"/>
  </xsl:template>

  <xsl:template match="subscript">
    &lt;sub><xsl:apply-templates/>&lt;/sub>
  </xsl:template>

  <xsl:template match="formalpara">
      <xsl:text>{{% formalpara title="</xsl:text>
    <xsl:variable name="titleNormalized">
      <xsl:apply-templates select="title"/>
    </xsl:variable>
    <xsl:value-of select="normalize-space($titleNormalized)"/>
      <xsl:text>" %}}</xsl:text>
      <xsl:apply-templates select="para"/>
      <xsl:text>{{% /formalpara %}}</xsl:text>
      <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="anchor">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="informaltable">
    <xsl:apply-templates select="tgroup/thead/row" />
    <xsl:value-of select="for $i in 1 to xs:integer(tgroup/@cols)  - 1  return '-------------|'"/>
    <xsl:text>-----&#x0a;</xsl:text>
    <xsl:apply-templates select="tgroup/tbody/row" />
  </xsl:template>

  <xsl:template match="row">
    <xsl:variable name="foo" as="item()+">
      <xsl:apply-templates select="entry"></xsl:apply-templates>
    </xsl:variable>
    <xsl:value-of select="string-join($foo,'|')"/>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="entry">
    <xsl:variable name="bar">
      <xsl:apply-templates></xsl:apply-templates>
    </xsl:variable>
    <xsl:value-of select="normalize-space($bar)"/>
  </xsl:template>


  <xsl:template match="*">
  <xsl:message select="local-name()"/>
  </xsl:template>
</xsl:stylesheet>