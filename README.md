# tei-digital-age

Digital Edition Demonstration and Sample Code 

NEH Institute 2012 

Working With Text In a Digital Age

Tufts University

## Overview

The goal of this demo/sample code is to provide a platform which institute participants can use to complete an exercise to create a miniature digital edition.  We will use
these editions as concrete examples for discussion of decisions and issues to consider when creating digital editions from TEI XML, annotations and other related resources.

Some specific items for consideration and discussion through this exercise :

* Creating identifiers for your texts.
* Establishing markup guidelines. 
* Use of inline annotations versus standoff markup.
* Applying Linked Data concepts.
* Leveraging annotation tools.
* Distribution formats for display versus for enabling data reuse.

## Data

We have selected 2 sample texts for the exercise, one Greek and one Latin. The Greek is a fragment of Hegesippus from the Greek Anthology and the Latin is a poem of Sidonius.  

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
* the Alpheios Alignment and Treebank editors to prepare alignment and syntactic annotations in standoff markup. (http://alpheios.net)
* the Stylebear XSLT maker was used to customize the standard TEI to XHTML transformations provided by tei-c.org (http://www.tei-c.org/release/doc/tei-xsl-common/style.html)

### Display
* ISAW's awld.js library for display of linked data resources (http://isawnyu.github.com/awld-js/awld-test.html)
* Tufts Morphology Service + Alpheios Lexicon service for lemma lookup
* Alpheios Treebank Viewer for Syntax

## Markup Guidelines

We are using the TEI-Analytics subset of TEI P5. This schema is in the src/schemas directory.  

The scripts which prepare the digital edition require the following specific applications of this standard:

* TEI element must contain an @xml:lang attribute for the main language of the text. Use 3 character language codes (grc, lat or eng)
* Named entities should be identified using the <name/> element, using the ref attribute to point to a URI for the named entity.
  * If you specify a URI reference for a named entity which is among those supported by awld.js good things will happen in your display.
* Citations should be identified using a quote tag inside a cit tag.  
  * If you specify a valid CTS URN from the Perseus repository as the value of the @n attribute on your quote tag, good things may happen in your display.

## Preparing the Digital Edition

1. clone this repository or download the zip file and extract to a local directory, preserving folders
2. Select one of the two sample texts in the src/data directory (tlg1396.tlg001.data.txt for Greek or stoa0261.stoa001_3.data.txt for Latin)

##  Transcribe
* Create a new TEI XML file named according to the edition in the empty xml directory
* to use the digital edition demo scripts with minimal hassle, adhere to the following naming schemes:
  * tlg1396.tlg1000.teida-grc1.xml (Hegesippus Text)
  * stoa0261.stoa001_3.teida-lat1.xml (Sidonius Text)
* add the markup for the text to the file
* Create a new TEI XML file named according to the translation in the empty xml directory
* to use the digital edition scripts with minimal hassle, adhere to the following naming schemes:
  * tlg1396.tlg1000.teida-eng1.xml (Hegesippus Text)
  * stoa0261.stoa001_3.teida-eng1.xml (Sidonius Text)
* add the markup for the translation to the file

## Annotate

### Align Translation

* Use the Alpheios Alignment Editor to align the translations.
  * http://repos1.alpheios.net/exist2/rest/db/xq/align-getlist.xq?doc=tlg1396.tlg001.align (Hegesippus)
  * http://repos1.alpheios.net/exist2/rest/db/xq/align-getlist.xq?doc=stoa0261.stoa001.align (Sidonius)
* After aligning the translation, click the Export XML button to download your alignment.  Do this for as many of the sentences as you want to annotate, and then combine 
the downloaded XML files into a single file in the xml directory of the demo environment by copying the sentence elements from the n+1 sentences into the file of the first sentence's file (as siblings to sentence). 
* To use the digital edition demo scripts with minimal hassle, adhere to the following naming schemes:
  * tlg1396.tlg1000.teida-grc1.teida-eng1.xml (Hegesippus Text)
  * stoa0261.stoa001_3.teida-lat1.teida-eng1.xml (Sidonius Text)

### Annotate Syntax

* Use the Alpheios Treebank Editor to align the translations.
  * http://repos1.alpheios.net/exist2/rest/db/xq/treebank-getlist.xq?doc=tlg1396.tlg001 (Hegesippus)
  * http://repos1.alpheios.net/exist2/rest/db/xq/treebank-getlist.xq?doc=stoa0261.stoa001 (Sidonius)
  * NOTE: for purposes of the demo, just experiment with the treebank editor but do not save your annotations.  We will use pre-prepared annotations for the integration demo.
* Copy the pre-prepared treebank annotation for your text from the xml-demo to the xml directory:
  * tlg1396.tlg1000.teida-grc1.tb.xml (Hegesippus Text)
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
* run alignannotations-greekDemo or alignannotations-latinDemo Xquery transformation
  * Document, Transformation, Configure Transformation Scenario
  * Select XML Transformation With XQuery transformation type
  * Select alignannotations-greekDemo (or alignannotations-latinDemo)
  * Make sure oXygen is set to output results as a file
   * click Edit
   * click Output tab
   * make sure Evaluate as sequence is unchecked
* Click Transform Now
* Open translated xml
  * xml is in the xml folder
  * Greek translation is tlg1396.tlg001.teida-eng1.xml
  * Latin translation is stoa0261.stoa001_3.teida-eng1.xml
* run reversealignannotations-greekDemo or reversealignannotations-latinDemo XQuery transformation
  * See instructions under step 3
* Open newly created digital edition xml
  * this the file created in the previous step, it should be in the digitaleditions directory and is either tlg1396.tlg001.teida-grc1.de.xml or stoa0261.stoa001_3.teida-grc1.de.xml
* run transformtodisplay-greekDemo or transformtodisplay-latinDemo XSLT Transformation
* load the resulting html file in your browser
  * digitaledition/tlg1396.tlg001.teida-grc1.de.html or digitaledition/tlg1396.tlg001.teida-grc1.de.html 


## Discussion Points
* Do we annotate meter inline or as standoff markup
  * Hegesippus poem demonstrates alternation of hexameters and iambic trimeters (lines 1, 3, 5, and 7 are hexameters)
* Where do we put notes, commentary and apparatus?
  * Sidonius notes were left out in the pre-prepared demo code, but should really be included
* ...