<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:oac='http://www.openannotation.org/ns/'
    exclude-result-prefixes="tei xsl">
    
    <xsl:template name="bodyHook" exclude-result-prefixes="tei xsl oac">
        <xsl:if test="//tei:w[@corresp]">
            <xsl:for-each select="distinct-values(//tei:w[@corresp]/substring-before(@corresp,'#xpointer'))">
                <iframe class="aligned-text" src="{replace(.,'\.xml$','.html')}"/>    
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="javascriptHook" exclude-result-prefixes="tei xsl oac">
        <script type="text/javascript" src="tei-lod.js"></script>    
        <script type="text/javascript" src="http://isawnyu.github.com/awld-js/lib/requirejs/require.min.js"></script>
        <script type="text/javascript" src="http://isawnyu.github.com/awld-js/awld.js?autoinit"></script>
      
    </xsl:template>
    
    <xsl:template match="tei:w[@corresp or @ana]">
        <xsl:call-template name="wrapword">
            <xsl:with-param name="attributes" select="(@corresp,@ana)"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="tei:name[@ref]">
        <a class="name" href="{@ref}"><xsl:apply-templates/></a>        
    </xsl:template>
    
    <xsl:template name="wrapword">
        <xsl:param name="attributes"/>
        <xsl:choose>
            <xsl:when test="count($attributes) > 1">
                <span rev="oac:hasBody" resource="{replace($attributes[1],'\.xml','.html')}" datatype="{name($attributes[1])}">
                    <xsl:call-template name="wrapword">
                        <xsl:with-param name="attributes" select="$attributes[position() > 1]"/>
                    </xsl:call-template>   
                </span>
            </xsl:when>
            <xsl:when test="count($attributes) = 1">
                <span rev="oac:hasBody" resource="{replace($attributes[1],'\.xml','.html')}" datatype="{name($attributes[1])}">
                    <xsl:apply-templates/>
                </span>    
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>