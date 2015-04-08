(:
  Copyright 2012 The Alpheios Project, Ltd.
  http://alpheios.net

  This file is part of Alpheios.

  Alpheios is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Alpheios is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 :)

(:
  Mark words in text with <w> elements
 :)

import module namespace almt="http://alpheios.net/namespaces/alignment-match"
              at "alignment-match.xquery";
              
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace align="http://alpheios.net/namespaces/aligned-text";

declare variable $e_work as xs:string external;
declare variable $e_edition as xs:string external;
declare variable $e_translation as xs:string external;
declare variable $e_transLang as xs:string external;
declare variable $e_srcLang as xs:string external;
declare variable $e_reverse as xs:boolean external;
declare variable $e_path as xs:string external;
declare variable $e_includePunc as xs:boolean external;

declare variable $e_docname as xs:string := 
 if ($e_reverse) then concat($e_work,'.',$e_translation,'.xml') else concat($e_work,'.',$e_edition,'.xml');
declare variable $e_align as xs:string := concat($e_work,'.',$e_edition,'.',$e_translation,'.align.xml');
declare variable $e_treebank as xs:string := concat($e_work,'.',$e_edition,'.tb.xml');
declare variable $e_transDoc as xs:string := 
 if ($e_reverse) then concat($e_work,'.',$e_edition,'.xml') else concat($e_work,'.',$e_translation,'.xml');
declare variable $e_lang as xs:string :=
 if ($e_reverse) then $e_transLang else $e_srcLang;

(: sets of characters by language :)
(: non-text characters :)
declare variable $s_nontext :=
(
  element nontext
  {
    attribute lang { "grc" },
    " “”—&quot;‘’,.:;&#x0387;&#x00B7;?!\[\]{}\-"
  },
  element nontext
  {
    attribute lang { "ara" },
    " “”—&quot;‘’,.:;?!\[\]{}\-&#x060C;&#x060D;"
  },
  element nontext
  {
    attribute lang { "*" },
    " “”—&quot;‘’,.:;&#x0387;&#x00B7;?!\[\](){}\-"
  }
);
(: characters which signify word break and are part of word :)
declare variable $s_breaktext :=
(
  element breaktext
  {
    attribute lang { "grc" },
    "᾽"
  },
   element breaktext
  {
    attribute lang { "ara" },
    "᾽"
  },
  element breaktext
  {
    attribute lang { "*" },
    "᾽"
  }
);

declare variable $s_linenum :=
(
  element breaktext
  {
    attribute lang { "*" },
    "1234567890"
  }
);

declare variable $s_tbPunc :=
(
  element punc
  {
    attribute lang { "*" },
    ",.:;\-—"
  }
);


(:
  Process set of nodes
 :)
declare function local:process-nodes(
  $a_nodes as node()*,
  $a_in-text as xs:boolean,
  $a_id as xs:string,
  $a_match-text as xs:string,
  $a_match-nontext as xs:string,
  $a_match-linenum as xs:string,
  $a_match-punc as xs:string) as node()*
{
  (: for each node :)
  for $node at $i in $a_nodes
  return
  typeswitch ($node)
    (:
      if element, copy and process all child nodes
     :)
    case element()
    return
    element { QName(namespace-uri($node),name($node)) }
    {
      local:process-nodes(
        $node/(node()|@*),
        ($a_in-text or (local-name($node) eq "body")) 
        and not(local-name($node) = ("note", "head")),
        concat($a_id, "-", $i),
        $a_match-text,
        $a_match-nontext,
        $a_match-linenum,
        $a_match-punc)
    }

    (: if text in body, process it else just copy it :)
    case $t as text()
    return
    if ($a_in-text)
    then
      local:process-text(normalize-space($t),
                         concat($a_id, "-", $i),
                         1,
                         $a_match-text,
                         $a_match-nontext,
                         $a_match-linenum,
                         $a_match-punc)
    else
      $node

    (: otherwise, just copy it :)
    default
    return $node
};

(:
  Process text string in body
 :)
declare function local:process-text(
  $a_text as xs:string,
  $a_id as xs:string,
  $a_i as xs:integer,
  $a_match-text as xs:string,
  $a_match-nontext as xs:string,
  $a_match-linenum as xs:string,
  $a_match-punc as xs:string) as node()*
{
  (: if anything to process :)
  if (string-length($a_text) > 0)
  then
    (: see if it starts with text :)
    let $is-text := matches($a_text, $a_match-text)
    
     (: see if it starts with text :)
    let $is-punc := matches($a_text, $a_match-punc)
    
    (: see if its a line number:)
    let $is-linenum := matches($a_text, $a_match-linenum)

    (: get initial text/non-text string :)
    let $t := replace($a_text,
                      if ($is-text) then $a_match-text else if ($is-punc) then $a_match-punc else $a_match-nontext,
                      "$1")

    return
    (
      (: return w element with text or non-text string :)      
      if ($is-text)
      then
        element {QName("http://www.tei-c.org/ns/1.0","w")}
            {
              (: assign unique id to word :)
              attribute xml:id { concat($a_id, "-", $a_i) },
              $t
            }
        else if ($is-linenum)
        then
            element {QName("http://www.tei-c.org/ns/1.0","milestone")} 
            {
                attribute unit { "Line"},
                attribute n { $t }
            }
        else if ($is-punc and ($e_includePunc = true()))
        then
            element {QName("http://www.tei-c.org/ns/1.0","w")}
            {
             (: assign unique id to word :)
              attribute xml:id { concat($a_id, "-", $a_i) },
              $t
             }
        else
          text { $t },
      (: then recursively process rest of text :)
      local:process-text(substring-after($a_text, $t),
                         $a_id,
                         $a_i + 1,
                         $a_match-text,
                         $a_match-nontext,
                         $a_match-linenum,
                         $a_match-punc)
    )
  else ()
};


(:
  Print a set of aligned nodes
  
  Parameters:
    $a_nodes           set of nodes to process
    $a_fixedWords      set of adjusted w nodes

  Return value:
    sequence of adjusted nodes

  Each <w> in the original text has a unique id attribute.
  Each fixed <w> is wrapped in a <wrap> element with the
  matching id.  The fixed <w>'s do not have id attributes,
  since these are needed only for the purpose of efficiently
  matching original with fixed elements.
 :)
declare function local:print-nodes(
  $a_nodes as node()*,
  $a_fixedWords as element(wrap)*) as node()*
{
  (: for each node :)
  for $node in $a_nodes
  return
  typeswitch ($node)
    (: if w, replace with corresponding fixed word, if it exists :)
    case $word as element(tei:w) 
    return
      if ($a_fixedWords[@xml:id = $word/@xml:id]/tei:w) 
        then 
            let $fixed := $a_fixedWords[@xml:id = $word/@xml:id]/tei:w
            return
                element {QName("http://www.tei-c.org/ns/1.0","w")} {
                    $fixed/@*[name(.) != 'nrefs' and name(.) != 'tbrefs' and local-name(.) != 'id'],
                    if ($fixed/@nrefs) then 
                        attribute corresp {
                            if (contains($fixed/@nrefs, ' ')) then 
                                string-join (
                                    for $t in tokenize(normalize-space($fixed/@nrefs),' ')
                                    return concat($e_transDoc,"#xpointer(//*[@n='", $t, "'])"), ' ')
                            else 
                                concat($e_transDoc,"#xpointer(//*[@n='", $fixed/@nrefs, "'])")
                        } else (),
                    if ($fixed/@tbrefs) then 
                        attribute ana {
                            string($fixed/@tbrefs)
                            (:
                            if (contains($fixed/@tbrefs, ' ')) then 
                                string-join (
                                    for $t in tokenize(normalize-space($fixed/@tbrefs),' ')
                                        let $parts := tokenize($t,'-')
                                        return concat($e_treebank,"#xpointer(//sentence[@id='", $parts[1],"']/word[@id='", $parts[2], "'])"), ' ')
                            else 
                                let $parts := tokenize($fixed/@tbrefs,'-')
                                return concat($e_treebank,"#xpointer(//sentence[@id='", $parts[1],"']/word[@id='", $parts[2], "'])")
                            :)
                        } 
                    else (),
                    $fixed/*,
                    $fixed/text()
            } 
        else $node
      

    (:
      if element, copy and process all child nodes
     :)
    case element()
    return
    element { QName(namespace-uri($node),name($node)) }
    {
      local:print-nodes(
        $node/(node()|@*),
        $a_fixedWords)
    }

    (: otherwise, just copy it :)
    default
    return $node
};

(:
  Fix a set of text words

  Parameters:
    $a_textWords      set of text words
    $a_dataWords      set of data words (either alignment or treebank)
    $a_matches        match info on sets of words
    $a_treebank       whether data is treebank or alignment

  Return value:
    sequence of text words with appropriate attributes added from data
 :)
declare function local:fix-words(
  $a_textWords as element(wrap)*,
  $a_dataWords as element(tei:w)*,
  $a_matches as element()*,
  $a_treebank as xs:boolean) as element(wrap)*
{
  (: nothing to do if no text words left :)
  if (count($a_textWords) eq 0) 
  then () 
  else
    (: if no matches left, copy text words :)
    if (count($a_matches) eq 0) 
    then $a_textWords 
    else
        if ($a_matches/*:oops) 
        then $a_textWords 
        else 

        (: create words for this match :)
        let $match := $a_matches[1]
        let $newWords :=
          (: if 1-to-1 match :)
          if ($match/@type eq "1-to-1")
          then
            for $i in (1 to $match/@l1)
            return
              local:fix-word($a_textWords[$i],
                             $a_dataWords[$i]/@n,
                             $a_dataWords[$i]/@nrefs,
                             $a_treebank)

            (: if mismatch :)
            else if ($match/@type eq "mismatch")
                then
                    let $n :=
                        string-join(
                          for $j in (1 to $match/@l2)
                          return $a_dataWords[$j]/@n,
                          ' ')
                    let $nrefs :=
                      string-join(
                        for $j in (1 to $match/@l2)
                        return $a_dataWords[$j]/@nrefs,
                        ' ')
                    for $i in (1 to $a_matches[1]/@l1)
                    return
                        local:fix-word($a_textWords[$i], $n, $nrefs, $a_treebank)

                (: if skip :)
                else
                  subsequence($a_textWords, 1, if ($match/@l1) then $match/@l1 else 0)

        return
        (
          $newWords,
          local:fix-words(
            subsequence($a_textWords, if ($match/@l1) then $match/@l1 + 1 else 1),
            subsequence($a_dataWords, if ($match/@l2) then $match/@l2 + 1 else 1),
            subsequence($a_matches, 2),
            $a_treebank)
        )
};

(:
  Fix a single text word

  Parameters:
    $a_textWord       text word to fix
    $a_dataWord       data word (either alignment or treebank)
    $a_treebank       whether data is treebank or alignment

  Return value:
    text word with appropriate attributes added from data
 :)
declare function local:fix-word(
  $a_textWord as element(wrap)?,
  $a_n as xs:string?,
  $a_nrefs as xs:string?,
  $a_treebank as xs:boolean) as element(wrap)?
{
  (: if no textword, nothing to do :)
  if (not($a_textWord)) then () else

  (: if no data, just copy textword :)
  if (not($a_n)) then $a_textWord else

  (: wrapper to hold id :)
  element wrap
  {
    (: preserve original word id :)
    $a_textWord/@xml:id,

    (: new w element :)
    element {QName("http://www.tei-c.org/ns/1.0","w")}
    {
      (: preserve any existing attributes :)
      $a_textWord/tei:w/@*,

      (: if this is treebank data :)
      if ($a_treebank)
      then
        (: create tb ref attribute :)
        attribute tbrefs { $a_n }
      else
      (
        (: copy word id and alignment refs :)
        attribute n { $a_n },
        if (exists($a_nrefs)) then attribute nrefs {$a_nrefs } else ()
      ),

      (: content is original word :)
      $a_textWord/*:w/text()
    }
  }
};


let $doc := doc(concat($e_path,$e_docname))
let $nontext :=
  if ($s_nontext[@lang eq $e_lang])
  then
    $s_nontext[@lang eq $e_lang]/text()
  else
    $s_nontext[@lang eq "*"]/text()
let $breaktext :=
  if ($s_breaktext[@lang eq $e_lang])
  then
    $s_breaktext[@lang eq $e_lang]/text()
  else
    $s_breaktext[@lang eq "*"]/text()
let $linenum :=
    $s_linenum[@lang eq "*"]/text()
let $punc :=
    $s_tbPunc[@lang eq "*"]/text()
    
let $match-text :=
  concat("^([^", $nontext, $breaktext, $linenum, "]+",
         if ($breaktext) then concat("[", $breaktext, "]?") else (),
         ").*")
let $match-nontext := concat("^([", $nontext, $linenum, "]+).*")

let $match-linenum := concat("^([", $linenum, "]+).*")

let $match-punc := concat("^([", $punc, "]+).*")

let $marked-words := 
    local:process-nodes($doc/node(), false(), "w1", $match-text, $match-nontext, $match-linenum, $match-punc)

(: END MARK WORDS :)
let $alignDoc := concat($e_path,'/',$e_align)
let $tbDoc := concat($e_path,'/',$e_treebank)

(: get words from original text :)
return 
if (doc-available($alignDoc) or doc-available($tbDoc))
then
    (: speakers aren't treebanked so ignore words inside speaker tags :)    
    let $textWords :=         
        for $word in
          $marked-words//tei:w[not(parent::tei:speaker) and not(parent::tei:label) and not(ancestor::tei:docAuthor) ]
        return
          element wrap 
          {
            $word/@xml:id,
            element {QName("http://www.tei-c.org/ns/1.0","w")} {
                if ($word/@nrefs or $word/@tbrefs)
                then ($word/@nrefs,$word/@tbrefs)
                else $word/@*,
                $word/text() 
            }
          }
          
      
    (: get words from aligned text, ignoring non-text :)
    
    let $alignLnum := 
        if (doc-available($alignDoc)) 
        then doc($alignDoc)//align:language[@xml:lang = $e_lang]/@lnum 
        else ()
    let $alignWords :=
        if (doc-available($alignDoc)) 
        then
            for $word in doc($alignDoc)//align:wds[@lnum=$alignLnum]/align:w
            where not(matches($word/*:text, $match-nontext)) or ($e_includePunc = true() and matches($word/*:text,$match-punc))
            return
            element {QName("http://www.tei-c.org/ns/1.0","w")}
            {
                $word/@n,
                $word/align:refs/@nrefs,
                $word/align:text/text()
            }
       else ()
   
    (: get words from treebank, ignoring non-text :)
    
    let $tbWords :=
      if (doc-available($tbDoc))
      then
        for $word in doc($tbDoc)//*:word
            where not(matches($word/@form, $match-nontext)) or ($e_includePunc = true() and matches($word/@form,$match-punc))  
            return
            element {QName("http://www.tei-c.org/ns/1.0","w")}
            {
                (: if sentence is valid :)
                if (exists($word/../@id))
                then
                (: build name from sentence# and word# :)
                    attribute n
                    {
                      (: concat($word/../@id, "-", $word/@id) :)
                      $word/@relation
                    }
                else (),
                  data($word/@form)
            }
      else ()
    
        
    (: create fixed words to replace original :)
    let $fix1 := 
       local:fix-words($textWords,
                      $alignWords,
                      almt:match(data($textWords/tei:w), data($alignWords), true()),
                      false())
    
    let $fix2 := 
    
      if (doc-available($tbDoc))      
      then
        local:fix-words(if ($fix1) then $fix1 else $textWords,
                        $tbWords,
                        almt:match(data($textWords/tei:w), data($tbWords), true()),
                        true())                                        
      else $fix1
    
    return        
        (: create copy of original text with fixed words :)
        element {QName("http://www.tei-c.org/ns/1.0","TEI")} {
            $doc/tei:TEI/@*,
            local:print-nodes($marked-words/node(), $fix2)
        }
else $marked-words
