<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:align="http://alpheios.net/namespaces/aligned-text"
    exclude-result-prefixes="xs align"
    version="2.0">
    <xsl:output method="xml" indent="yes"/>
    <xsl:param name="e_lang"></xsl:param>
    <xsl:param name="e_title"></xsl:param>
    <xsl:param name="e_urn"></xsl:param>
    <xsl:param name="e_addpunc" select="true()"/>
    <xsl:variable name="lnum" select="//align:language[@xml:lang=$e_lang]/@lnum"/>
    <xsl:template match="/">
        <xsl:variable name="urns" select="distinct-values(//align:sentence/@document_id)"/>
        <xsl:variable name="docurn">
            <xsl:choose>
                <xsl:when test="count($urns) = 1"><xsl:value-of select="$urns[1]"></xsl:value-of></xsl:when>
                <xsl:otherwise><xsl:value-of select="$e_urn"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <TEI>
            <teiHeader>
                <fileDesc>
                    <titleStmt>
                        <title><xsl:value-of select="$e_title"/></title>
                    </titleStmt>
                    <publicationStmt>
                        <authority>Perseus Project</authority>
                        <idno type="urn:cts"><xsl:value-of select="$e_urn"/></idno>
                        <availability>
                            <p>This work is licensed under a
                                <ref type="license" target="http://creativecommons.org/licenses/by-sa/3.0/">Creative 
                                    Commons Attribution-ShareAlike 3.0 License</ref>.</p>
                        </availability>
                    </publicationStmt>
                    <sourceDesc> 
                        <p>Derived from translation alignment</p>
                    </sourceDesc>
                </fileDesc>
                <profileDesc>
                    <langUsage>
                        <language ident="eng">English</language>
                        <language ident="grc">Ancient Greek</language>
                        <language ident="lat">Latin</language>
                        <language ident="fre">French</language>
                        <language ident="deu">German</language>
                        <language ident="grc-Latn">Ancient Greek in Latin script</language>
                        <language ident="la-Grek">Latin in Greek script</language>
                        <language ident="cop">Coptic</language>
                    </langUsage>
                </profileDesc>
                <revisionDesc>
                    <change when="{current-dateTime()}" who="Perseids Project">Automated creation from translation alignment</change>
                </revisionDesc>
            </teiHeader>
            <text>
                <body>
                    <div xml:lang="{$e_lang}" type="translation" n="{$docurn}">
      	                 <ab><xsl:apply-templates select="//align:sentence"></xsl:apply-templates></ab>
                    </div>
                </body>
            </text>
        </TEI>
        
    </xsl:template>
    
    <xsl:template match="align:sentence">
        <xsl:if test="@document_id != preceding-sibling::align:sentence/@document_id">
            <milestone n="{@document_id}" unit="passage"/>
        </xsl:if>    
        <seg n="{@id}" xml:space="preserve">
            <xsl:apply-templates select="align:wds[@lnum=$lnum]"></xsl:apply-templates><xsl:if test="$e_addpunc">.</xsl:if>
        </seg>
    </xsl:template>
    
    <xsl:template match="align:wds">
        <xsl:apply-templates select="align:w"/>
    </xsl:template>
    
    <xsl:template match="align:w">
        <xsl:apply-templates select="align:text"/>
        <xsl:if test="following-sibling::align:w"><xsl:text> </xsl:text></xsl:if>
    </xsl:template>
    
    <xsl:template match="align:text">
        <xsl:value-of select="."/>
    </xsl:template>
    
</xsl:stylesheet>