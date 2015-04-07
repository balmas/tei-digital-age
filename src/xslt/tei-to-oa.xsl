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
    xmlns:teida="http://data.perseus.org/namespaces/teida"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:atom="http://www.w3.org/2005/Atom" 
    xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/"
    xmlns:gsx="http://schemas.google.com/spreadsheets/2006/extended"
    xmlns:cnt="http://www.w3.org/2011/content#"
    xmlns:dcmit="http://purl.org/dc/dcmitype/"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:oa="http://www.w3.org/ns/oa#"
    xmlns:perseus="http://data.perseus.org/"
    xmlns:lawd="http://lawd.info/ontology/"
    xmlns:lode="http://linkedevents.org/ontology/#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:prov="http://www.w3.org/ns/prov#"
    xmlns:uuid="http://www.uuid.org" 
    exclude-result-prefixes="tei teida">
    
    <xsl:include href="uuid.xslt"/>
    
    <xsl:output indent="yes" method="xml"/>
    <xsl:param name="teida:imageFile"></xsl:param>
    <xsl:param name="teida:urn"/>
    <xsl:param name="teida:treebankFile" select="concat($teida:urn,'tb.xml')"/>
    <xsl:variable name="ctsUriPrefix" select="'http://data.perseus.org/texts/'"/>
    <xsl:variable name="citeUriPrefix" select="'http://data.perseus.org/collections/'"/>
    <xsl:variable name="citeCollection" select="'urn:cite:perseus:pdlvortex'"/>
    <xsl:template match="/">
        <!-- add syntax lookup -->
        <xsl:variable name="themes">
            <xsl:if test="//tei:w/@ana">
                <xsl:for-each select="//tei:w[@ana]" >
                    <!-- skip the punctuation and the nils -->
                    <xsl:if test="not(@ana = 'AuxK') and not(@ana='AuxX') and not(@ana='AuxZ') and not(@ana='nil')">
                        <ana>
                            <xsl:copy-of select="@ana"/>
                            <xsl:attribute name="exact"><xsl:copy-of select="text()"/></xsl:attribute>
                            <xsl:attribute name="prefix" select="string-join(preceding-sibling::*/text(), ' ')"/>
                            <xsl:attribute name="suffix" select="string-join(following-sibling::*/text(), ' ')"/>
                        </ana>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
            <xsl:if test="$teida:imageFile">
                <xsl:for-each select="doc($teida:imageFile)//tei:w[@facs]" >
                    <ana>
                        <xsl:attribute name="ana"><xsl:copy-of select="text()"/></xsl:attribute>
                        <xsl:attribute name="resource"><xsl:value-of select="@facs"/></xsl:attribute>
                    </ana>
                </xsl:for-each>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="annotators" select="doc($teida:treebankFile)//annotator"/>
        <rdf:RDF
            xmlns:cnt="http://www.w3.org/2011/content#"
            xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
            xmlns:lawd="http://lawd.info/ontology/"
            xmlns:dcmit="http://purl.org/dc/dcmitype/"
            xmlns:oa="http://www.w3.org/ns/oa#"
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            >
            <xsl:for-each-group select="$themes/*" group-by="@ana">
                <xsl:variable name="tag" select="current-group()[1]/@ana"/>
                <xsl:for-each select="current-group()">                
                    <xsl:variable name="nid" select="@n"/>
                    <xsl:variable name="uuid" select="generate-id(.)"/>
                    <xsl:variable name="citeurn" select="concat($citeUriPrefix,$citeCollection,'.',$uuid,'.1')"/>
                    <oa:Annotation rdf:about="{$citeurn}">
                        <xsl:choose>
                            <xsl:when test="@exact">
                                <oa:hasTarget rdf:resource="{concat($citeurn,'#target')}"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <oa:hasTarget rdf:resource="{@resource}"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                        <oa:motivatedBy rdf:resource="http://www.w3.org/ns/oa#tagging"/>
                        <oa:hasBody>    
                            <oa:Tag rdf:about="{concat($citeurn,'#tag')}">
                                <cnt:chars><xsl:value-of select="$tag"/></cnt:chars>
                                <rdf:type rdf:resource="http://www.w3.org/2011/content#ContentAsText"/>
                            </oa:Tag>
                        </oa:hasBody>
                        <oa:annotatedAt><xsl:value-of select="current-date()"/></oa:annotatedAt>
                       <xsl:for-each select="$annotators[not(short/text())]">
                            <oa:serializedBy>
                                <xsl:element name="prov:SoftwareAgent">
                                    <xsl:attribute name="rdf:about"><xsl:value-of select="uri"/></xsl:attribute>
                                </xsl:element>
                            </oa:serializedBy>
                        </xsl:for-each>
                        <xsl:for-each select="$annotators[name/text() != '']">
                            <oa:annotatedBy>
                                <foaf:Person rdf:about="{uri}">
                                    <foaf:name><xsl:value-of select="name"/></foaf:name>
                                </foaf:Person>
                            </oa:annotatedBy>
                        </xsl:for-each>
                    </oa:Annotation>
                    <xsl:if test="@exact">
                        <rdf:Description rdf:about="{concat($citeurn,'#target')}">
                            <rdf:type rdf:resource="http://www.w3.org/ns/oa#SpecificResource"/>
                            <oa:hasSource rdf:resource="{concat($ctsUriPrefix,$teida:urn)}"/>
                            <oa:hasSelector rdf:resource="{concat($citeurn,'#target-sel')}"/>
                        </rdf:Description>
                        <rdf:Description rdf:about="{concat($citeurn,'#target-sel')}">
                            <rdf:type rdf:resource="http://www.w3.org/ns/oa#TextQuoteSelector"/>
                            <oa:exact><xsl:value-of select="@exact"/></oa:exact>
                            <oa:prefix><xsl:value-of select="@prefix"/></oa:prefix>
                            <oa:suffix><xsl:value-of select="@suffix"/></oa:suffix>
                        </rdf:Description>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each-group>
        </rdf:RDF>
    </xsl:template>
    
</xsl:stylesheet>