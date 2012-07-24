<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright 2012 The Perseus Project, Tufts University, Medford MA

This free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This  software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

See <http://www.gnu.org/licenses/>.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:teida="http://data.perseus.org/namespaces/teida"
    exclude-result-prefixes="tei xsl teida">
    
    <xsl:output indent="yes"/>
    <!-- file containing the aligned translation markup -->
    <xsl:param name="teida:translationFile"></xsl:param>
    
     <!-- startHook is called after processing the tei:body element -->
     <xsl:template name="startHook" exclude-result-prefixes="tei xsl teida">
        <div id="tei-tools">
        <!-- add some extra features to source text only -->
        <xsl:if test="tei:text/@xml:lang != 'eng'">
            <!-- add a div to contain the results of the lexicon lookup -->
            <div id="tei-lemmas"><h2>Lexicon Lookup</h2><div class="tei-hint">Double-click on a word to lookup in the lexicon.</div></div>
        </xsl:if>
         <!-- add syntax lookup -->
         <xsl:if test="//tei:w/@ana">
                <div id="tei-analyses">
                    <h2>Syntax:</h2>
                    <xsl:variable name="tbrefs">
                        <xsl:for-each select="//tei:w/@ana">
                            <xsl:for-each select="tokenize(.,' ')">
                                <xsl:variable name="file" select="concat('../../xml/',substring-before(.,'#xpointer'))"/>
                                <tbref>
                                    <xsl:analyze-string select="." regex="^.*?sentence\[@id='(\d+)'\].*$">
                                        <xsl:matching-substring><xsl:value-of select="concat($file,'|',regex-group(1))"/></xsl:matching-substring>
                                    </xsl:analyze-string>    
                                </tbref>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:variable>
                    <ul>
                        <xsl:for-each select="distinct-values($tbrefs/*)">
                            <xsl:variable name="xpath" select="substring-after(.,'|')"/>
                            <xsl:variable name="file" select="substring-before(.,'|')"/>
                            <xsl:variable name="sentence" select="doc($file)//*:sentence[@id=$xpath]"/>
                            <xsl:if test="$sentence">
                                <li class="tbref">
                                    <span class="sentence"><xsl:value-of select="doc($file)//*:sentence[@id=$xpath]/*:word/@form"/></span>
                                    <div class="data" style="display:none;">
                                        <!-- this should really be converted to a valid HTML 5 element with data attributes -->
                                        <sentence>
                                            <xsl:copy-of select="$sentence/../@format"/>
                                            <xsl:copy-of select="$sentence/../@xml:lang"/>
                                            <xsl:copy-of select="$sentence/*"/>
                                        </sentence>
                                    </div>
                                </li>
                            </xsl:if>
                        </xsl:for-each>
                    </ul>
                </div>
            </xsl:if>
        </div>
         <xsl:if test="$teida:translationFile">
             <!-- add a div to contain the translated text. note this includes any element identifies as @type=translation from the 
                 file identified as the translation file. A further refinements might be to pull the translation automatically from 
                 a CTS service. 
             -->
             <div class="tei-aligned-text">
                 <xsl:apply-templates select="doc($teida:translationFile)//*[@type='translation']"/>
             </div>
         </xsl:if>
     </xsl:template>
    
    <!-- hook for end of html body -->
    <xsl:template name="bodyEndHook">
        <!--put the syntax frame at the bottom and use css to position -->
        <xsl:if test="//tei:w/@ana">
            <iframe id="tei-syntax-frame" src="syntaxview.html"/>
        </xsl:if>
    </xsl:template>
    <!-- hook which pulls  css into the HTML head -->
    <xsl:template name="cssHook" exclude-result-prefixes="tei xsl teida">
        <link rel="stylesheet" type="text/css" href="../src/css/tei-lod.css"/>        
    </xsl:template>
    
    <!-- hook which pulls javascript into the HTML head -->
    <xsl:template name="javascriptHook" exclude-result-prefixes="tei xsl teida">
        <!-- jquery library - should really be imported via a require.js? -->
        <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
        
        <!-- javascript library for the tei-digital-age demo -->
        <script type="text/javascript" src="../src/js/tei-lod.js"></script>
        
        <!-- AWLD.JS library -->
        <script type="text/javascript" src="http://isawnyu.github.com/awld-js/lib/requirejs/require.min.js"></script>
        <script type="text/javascript" src="http://isawnyu.github.com/awld-js/awld.js?autoinit"></script>
        
        <!-- jQuery document ready function to initialize the page elements on load -->
        <script type="text/javascript">
        $(
            function() {
                window.teilod.ready();
            }
        );
        </script>
      
    </xsl:template>
    
    <!-- override default id generation for divs -->
    <xsl:template match="tei:div" mode="ident">
        <!-- use random ids to avoid collision between source and translation -->
        <xsl:value-of select="generate-id()"></xsl:value-of>
    </xsl:template>
    
    <!-- w template which processes @corresp and @ana attributes as custom data-X attributes on a containing span -->
    <xsl:template match="tei:w">
        <xsl:variable name="class">
            <xsl:choose>
                <xsl:when test="ancestor-or-self::*[@type='translation']">tei-aligned-word</xsl:when>
                <xsl:otherwise>tei-word</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <span class="{$class}" data-n="{@n}">
            <xsl:call-template name="data-attributes">
                <xsl:with-param name="attributes" select="(@corresp,@ana)"/>
            </xsl:call-template>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <!-- if a tei:name element contains a linkable reference, link it-->
    <xsl:template match="tei:name[matches(@ref,'^http.*')]">
        <a class="name" href="{@ref}"><xsl:apply-templates/></a>        
    </xsl:template>
    
    <!-- convert CTS URNs in @n attributes in citations to links to Perseus -->
    <!-- Ideally this would look up the base uri from a CTS resolver service -->
    <xsl:template match="tei:quote[@n[starts-with(.,'urn:cts')]]">
        <a class="citquote" href="{concat('http://data.perseus.org/citations/',@n)}"><xsl:apply-templates/></a>
    </xsl:template>
    
    <!-- template to process supplied TEI attributes as custom HTML data attributes -->
    <xsl:template name="data-attributes">
        <xsl:param name="attributes"/>
        <xsl:for-each select="$attributes">
            <xsl:variable name="respaths">
                <xsl:choose>    
                    <!-- special handling for corresp references which in the tei-digital-age demo are xpointer links to an aligned
                         translation that is inserted in a div in the output file. We remove the xpointer reference the linked data is
                         now inserted into the output file. The data element will be processed via javascript to provide mouseover
                         highlighting
                    -->
                    <xsl:when test="name(.) = 'corresp'">
                        <xsl:variable name="resources">
                            <xsl:for-each select="tokenize(., ' ')">
                                <xsl:variable name="res" select="replace(.,'^.*\.xml.*@n=.(\d+-\d+).*$','$1')"/>
                                <xsl:if test="matches($res,'^\d+-\d+$')">
                                    <resource><xsl:value-of select="$res"/></resource>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:value-of select="string-join($resources/*,' ')"/>
                    </xsl:when>
                    <xsl:when test="name(.) = 'ana'">
                        <xsl:variable name="resources">
                            <xsl:for-each select="tokenize(., ' ')">
                                <xsl:variable name="res">
                                    <xsl:analyze-string select="." 
                                        regex="^.*?sentence\[@id='(\d+)'\]/word\[@id='(\d+)'\]">
                                        <xsl:matching-substring><xsl:value-of select="regex-group(1)"/></xsl:matching-substring>
                                    </xsl:analyze-string>
                                </xsl:variable>
                                <xsl:if test="matches($res,'^\d+$')">
                                    <resource><xsl:value-of select="$res"/></resource>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:value-of select="string-join(distinct-values($resources/*),' ')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:attribute name="{concat('data-',name(.))}"><xsl:value-of select="$respaths"/></xsl:attribute>       
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="copyrightStatement">
        <!--Creative Commons License-->
        <p>This work is licensed under a
            <a rel="license" href="http://creativecommons.org/licenses/by-sa/3.0/us/">Creative Commons Attribution-Share Alike 3.0 United States License</a>.
        </p>
    </xsl:template>
    
</xsl:stylesheet>