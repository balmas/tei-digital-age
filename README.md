# NEH Institute Working With Text In a Digital Age

Digital Edition Demonstration and Sample Code 

Tufts University, July 2012

## Overview

The goal of this demo/sample code is to provide a platform which institute participants can use to complete an exercise to create a miniature digital edition.  We will use
these editions as concrete examples for discussion of decisions and issues to consider when creating digital editions from TEI XML, annotations and other related resources.

Some specific items for consideration and discussion through this exercise :

* Creating identifiers for your texts.
* Establishing markup guidelines. 
* Metadata best practices.
* Use of inline annotations versus standoff markup.
* OAC (Open Annotation Collaboration)
* Leveraging annotation tools.
* Applying Linked Data concepts.
* Distribution formats: optimzing for display vs for enabling data reuse.

## Data

We have selected two sample texts for the exercise, one Greek and one Latin. The Greek is a fragment of Hegesippus from the Greek Anthology and the Latin is a poem of Sidonius.  

The data for the samples can be found in the src/data directory of the repository and contain the following for each text:

* links to catalog records for the text
* links to digital copies of the text and translation
* the work identifier
* the OCR of the bibliographic information
* the OCR of the source text (original and corrected)
* the OCR of the English translation (original and corrected)


## Tools

### Creation
* oXygen for creating and editing the TEI and running transformations 
* the Alpheios Alignment and Treebank editors to prepare alignment and syntactic annotations in standoff markup. 
* the Stylebear XSLT maker was used to customize the standard TEI to XHTML transformations provided by tei-c.org 

### Display
* ISAW's awld.js library for display of linked data resources 
* Tufts Morphology Service + Alpheios Lexicon service for lemma lookup
* Alpheios Treebank Viewer for Syntax

## Markup Guidelines

We are using the [TEI-Analytics](http://segonku.unl.edu/teianalytics/TEIAnalytics.html) subset of TEI P5. This schema is in the src/schemas directory.  

The scripts which prepare the digital edition require the following specific applications of this standard:

* TEI element must contain an 'xml:lang' attribute for the main language of the text. Use 3 character language codes (grc, lat or eng)
* Named entities should be identified using the &lt;name/&gt; element, using the 'ref' attribute to point to a URI for the named entity.
  * If you specify a URI reference for a named entity which is among those supported by awld.js the display will automatically include that resource.
* Citations should be identified using a quote tag inside a cit tag.  
  * If you specify a valid CTS URN from the Perseus repository as the value of the 'n' attribute on your quote tag, the display will automatically include that resource.

## Preparing the Digital Edition

1. Download and extract [the zip file](https://github.com/balmas/tei-digital-age/zipball/master) to a local directory, preserving folders; or clone [the project github repository](https://github.com/balmas/tei-digital-age) using Git.
2. Select one of the two sample texts to work with, either the Hegesippus or the Sidonius. Each has a transcription and a translation you will be working with. 

##  Transcribe
* Templates for the transcription TEI XML have been created for you in xml directory. 
  * tlg1396.tlg001.teida-grc1.xml (Hegesippus Text - Greek Transcription)
  * stoa0261.stoa001_3.teida-lat1.xml (Sidonius Text - Latin Transcription)
  * tlg1396.tlg001.teida-eng1.xml (Hegesippus Text - English Translation)
  * stoa0261.stoa001_3.teida-eng1.xml (Sidonius Text - English Translation)
  
* The file header metadata and basic document structure for the text are already populated. You need to add the markup of the text so that the file validates according to the schema.  Some things to consider identifying in the markup are:
 * poetic lines (if applicable)
 * named entities
 * meter
 * quotations and citations

(Note: the source data from which the templates were created can be found in the src/data directory.)

## Annotate

### Align Translation

* Use the Alpheios Alignment Editor to align the translations.
  * http://repos1.alpheios.net/exist2/rest/db/xq/align-getlist.xq?doc=tlg1396.tlg001.align (Hegesippus)
  * http://repos1.alpheios.net/exist2/rest/db/xq/align-getlist.xq?doc=stoa0261.stoa001.align (Sidonius)
* After aligning the translation, click the Export XML button to download your alignment.  Do this for as many of the sentences as you want to annotate, and then combine 
the downloaded XML files into a single file in the xml directory of the demo environment by inserting the &lt;sentence&gt; elements from the downloaded alignments into the template file for that text in the xml directory 
as child elements of the &lt;aligned-text&gt; root element (after the 2 &lt;language&gt; elements). The template files are:
  * tlg1396.tlg001.teida-grc1.teida-eng1.xml (Hegesippus Text)
  * stoa0261.stoa001_3.teida-lat1.teida-eng1.xml (Sidonius Text)

### Annotate Syntax

* Use the Alpheios Treebank Editor to annotate the syntax.
  * http://repos1.alpheios.net/exist2/rest/db/xq/treebank-getlist.xq?doc=tlg1396.tlg001 (Hegesippus)
  * http://repos1.alpheios.net/exist2/rest/db/xq/treebank-getlist.xq?doc=stoa0261.stoa001 (Sidonius)
  * NOTE: for purposes of the demo, just experiment with the treebank editor but do not save your annotations.  We will use 
    the pre-prepared annotations for the integration demo which are already in the xml folder:
   * tlg1396.tlg001.teida-grc1.tb.xml (Hegesippus Text)
   * stoa0261.stoa001_3.teida-lat1.tb.xml (Sidonius Text)

## Merge Standoff Markup with TEI to create Digital Editions

A set of pre-prepared transformation scenarios can be used to transform the TEI transcription, translation, alignment and syntax annotations. These will work 
on the pre-prepared demo XML files in the xml-demo directory, or ones you prepare and put in the xml directory as described above.
* Import the transformations from the scenarios.xml file
  * Options, Import Global Options and select scenarios.xml
* Open the transcription xml
  * xml is in the xml folder (or for the pre-prepared demo xml, it's in xml-demo)
  * Greek source is tlg1396.tlg001.teida-grc1.xml
  * Latin source is stoa0261.stoa001_3.teida-lat1.xml
* run alignannotations-greekDemo or alignannotations-latinDemo XQuery transformation
  * Document, Transformation, Configure Transformation Scenario
  * Select XML Transformation With XQuery transformation type
  * Select alignannotations-greekDemo (or alignannotations-latinDemo)
  * Make sure oXygen is set to output results as a file (click Edit, Output tab and make sure Evaluate as Sequence is unchecked)
* Click Transform Now
* Open translated xml
  * xml is in the xml folder
  * Greek translation is tlg1396.tlg001.teida-eng1.xml
  * Latin translation is stoa0261.stoa001_3.teida-eng1.xml
* run reversealignannotations-greekDemo or reversealignannotations-latinDemo XQuery transformation
  * Same instructions as above for alignannotations-greekDemo/alignannotations-latinDemo
* Open newly created digital edition xml
  * this the file created in the previous step, it should be in the digitaleditions directory and is either tlg1396.tlg001.teida-grc1.de.xml or stoa0261.stoa001_3.teida-grc1.de.xml
* run transformtodisplay-greekDemo or transformtodisplay-latinDemo XSLT Transformation
* load the resulting html file in your browser (Firefox is preferred)
  * digitaledition/tlg1396.tlg001.teida-grc1.de.html or digitaledition/tlg1396.tlg001.teida-grc1.de.html 
  * Note: the syntax viewer frame does not currently work properly in Chrome or Safari.

## Discussion 
* Annotating meter inline vs standoff markup
  * Hegesippus poem demonstrates alternation of hexameters and iambic trimeters (lines 1, 3, 5, and 7 are hexameters)
* Approaches to notes, commentary and apparatus
  * Sidonius notes were left out in the pre-prepared demo code, but should really be included
* ...

## Resources

The following resources may be helpful in understanding the exercise and for working with digital editions:

* [TEI-Analytics Schema](http://segonku.unl.edu/teianalytics/TEIAnalytics.html)
* [TEI XSL Customization Handbook](http://www.tei-c.org/release/doc/tei-xsl-common/customize.html)
* [Stylebear TEI XSL Customizer](http://www.tei-c.org/release/doc/tei-xsl-common/style.html)
* [Alpheios Treebank Editor Screencast](http://vimeo.com/15324213)
* [Alpheios Alignment Editor Screencast](http://alpheios.net/alpheios-demos/alignment/index.html)
* [ISAW's awld.js library](http://isawnyu.github.com/awld-js/)
* [Tufts/Bamboo Morphology Service API](https://wiki.projectbamboo.org/display/BTECH/Morphological+Analysis+Service+Contract+Description)
* [Tufts FRBR Catalog Prototype](http://catalog.perseus.tufts.edu/perseus.org/)
* [Pelagios](https://github.com/pelagios/pelagios-cookbook/wiki)
* [Open Annotation Collaboration](http://www.openannotation.org/)
* [CITE Architecture](http://www.homermultitext.org/hmt-doc/cite/index.html)
* [CTS Kit](http://homermultitext.blogspot.com/2012/07/html-cts-kit-abstract-announcing-for.html)


Created for the NEH Institute for Advanced Technology in the Digital Humanities by Bridget Almas, The Perseus Project, Tufts University July 2012

This free software: you can redistribute it and/or modify it under the terms of the [GNU General Public License](http://www.gnu.org/licenses/) as published by the Free Software Foundation, 
either version 3 of the License, or (at your option) any later version.

This  software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

See http://www.gnu.org/licenses/.