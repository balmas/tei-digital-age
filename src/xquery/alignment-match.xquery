(:
  Copyright 2009 Cantus Foundation
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

module namespace almt="http://alpheios.net/namespaces/alignment-match";

(:
  Find matches in two strings of words

  The output is a sequence of <match> elements with the following attributes:
    type - "1-to-1" for a run of identical words in both sets of words
           "skip" for a run of words that appears in only one set of words
           "mismatch" for runs of non-matching words in both sets of words
    o1 - offset of start of run in first set of words
    o2 - offset of start of run in second set of words
    l1 - length of run in first set of words
    l2 - length of run in second set of words
    w1 - first word in run in first set of words
    w2 - first word in run in second set of words
    w - first word in run (type "1-to-1" only)

  If the type is "skip" then only one of {o1,l1,w1} and {o2,l2,w2} will appear,
  depending on which set of words the skipped text belongs to.
  If the type is "1-to-1" then w appears and w1/w2 are absent.

  Several static variables parametrize the algorithm:
    s_maxMissing      max number of missing words to test for
    s_maxMismatch     max number of mismatched words to test for
    s_match           number of words to verify match

  The s_sync sequence holds the offsets to test for in searching
  for a synchronization point in the two sets of words.  Attributes
  x and y are the offsets to sets in the first and second set, respectively.
  The sequence tests first for missing words of increasing length
    (0, 1), (1, 0), (0, 2), (2, 0), ..., (0, s_maxMissing), (s_maxMissing, 0)
  Then the sequence tests for mismatched texts.  The test points are ordered
  by the increasing sum of x and y, where the difference between x and y is
  no more than s_maxMismatch.
    (1, 1), (0, 2), (1, 1), (2, 0), ..., (s_maxMismatch/2, 3*s_maxMismatch/2)

  s_match words must match after either a skip or mismatch in order to
  establish a new match.
 :)
declare variable $almt:s_maxMissing := 100;
declare variable $almt:s_maxMismatch := 10;
declare variable $almt:s_match := 3;
declare variable $almt:s_sync :=
(
  (: test points for missing text :)
  for $i in (1 to $almt:s_maxMissing)
  return
  (
    element pair { attribute x { 0 }, attribute y { $i } },
    element pair { attribute x { $i }, attribute y { 0 } }
  ),

  (: test points for mismatched text :)
  almt:gen-sync-list(1, 1, $almt:s_maxMismatch)
);

(:
  Recursive function to generate synchronization test points

  Parameters:
    $a_x         test offset for first list
    $a_y         test offset for second list
    $a_max       maximum difference between offsets

  Return value:
    sequence of <pair> elements with attributes:
      x = offset for first list
      y = offset for second list
 :)
declare function almt:gen-sync-list(
  $a_x as xs:integer,
  $a_y as xs:integer,
  $a_max as xs:integer) as element()*
{
  (
    (: put out current pair :)
    element pair { attribute x { $a_x }, attribute y { $a_y } },

    (: if need to start new line :)
    if (($a_x = 1) or (($a_y - $a_x + 2) > $a_max))
    then
      (: if at end of sequence :)
      if (($a_x + $a_y) = (2 * $a_max)) then ()
      else
        let $newsum := $a_x + $a_y + 1
        return
        if ($newsum > $a_max)
        then
          let $x := ($newsum + $a_max) idiv 2
          return almt:gen-sync-list($x, $newsum - $x, $a_max)
        else
          almt:gen-sync-list($newsum - 1, 1, $a_max)
    else
      almt:gen-sync-list($a_x - 1, $a_y + 1, $a_max)
  )
};

(:
  Function to generate word sequence matches

  Parameters:
    $a_w1        first list of words
    $a_w2        second list of words
    $a_ignore    whether to do case-insensitive compares

  Return value:
    sequence of <match> elements with attributes:
      w = starting word
      w1 = starting word in w1 list
      w2 = starting word in w2 list
      o1 = starting offset in w1 list
      o2 = starting offset in w2 list
      l1 = length of l1 matching sequence
      l2 = length of l2 matching sequence
 :)
declare function almt:match(
  $a_w1 as xs:string*,
  $a_w2 as xs:string*,
  $a_ignore as xs:boolean) as element()*
{
  almt:do-match($a_w1, $a_w2, $a_ignore, 1, 1)
};

(:
  Recursive function to generate word sequence matches

  Parameters:
    $a_w1        first list of words
    $a_w2        second list of words
    $a_ignore    whether to do case-insensitive compares
    $a_o1        offset in first list
    $a_o2        offset in second list

  Return value:
    sequence of <match> elements
 :)
declare function almt:do-match(
  $a_w1 as xs:string*,
  $a_w2 as xs:string*,
  $a_ignore as xs:boolean,
  $a_o1 as xs:integer,
  $a_o2 as xs:integer) as element()*
{
  (: if both lists are empty, nothing left to do :)
  if (($a_o1 > count($a_w1)) and ($a_o2) > count($a_w2)) then () else

  (: find last match :)
  let $len := min((count($a_w1) - $a_o1, count($a_w2) - $a_o2))
  let $firstMisMatch :=
  (
    for $i in (0 to $len)
    let $differ :=
      if ($a_ignore)
      then
        if (lower-case($a_w1[$a_o1 + $i]) = lower-case($a_w2[$a_o2 + $i]))
        then false() else true()
      else
        if ($a_w1[$a_o1 + $i] = $a_w2[$a_o2 + $i])
      then false() else true()
    where $differ
    return $i
  )[1]
  let $lastMatch :=
    if (exists($firstMisMatch)) then $firstMisMatch else $len + 1

  return
  (
    (: initial matching sequence was found :)
    if ($lastMatch > 0)
    then
      (: include matched words :)
      element match
      {
        attribute type { "1-to-1" },
        attribute o1 { $a_o1 },
        attribute o2 { $a_o2 },
        attribute l1 { $lastMatch },
        attribute l2 { $lastMatch },
        attribute w { $a_w1[$a_o1] }
      }
    else (),

    (: skip match and find next sync point :)
    let $sync := almt:sync($a_w1,
                           $a_w2,
                           $a_ignore,
                           $a_o1 + $lastMatch,
                           $a_o2 + $lastMatch,
                           1)
    return
    if ($sync)
    then
    (
      (: return words up to sync point :)
      element match
      {
        attribute type
        {
          if (($sync/@l1 = 0) or ($sync/@l2 = 0))
          then
            "skip"
          else
            "mismatch"
        },
        if ($sync/@l1 > 0)
        then
        (
          attribute o1 { $a_o1 + $lastMatch },
          attribute l1 { $sync/@l1 },
          attribute w1 { $a_w1[$a_o1 + $lastMatch] }
        )
        else (),
        if ($sync/@l2 > 0)
        then
        (
          attribute o2 { $a_o2 + $lastMatch },
          attribute l2 { $sync/@l2 },
          attribute w2 { $a_w2[$a_o2 + $lastMatch] }
        )
        else ()
      },

      (: continue matching from sync point :)
      almt:do-match($a_w1,
                    $a_w2,
                    $a_ignore,
                    xs:integer($a_o1 + $lastMatch + $sync/@l1),
                    xs:integer($a_o2 + $lastMatch + $sync/@l2))
    )
    else
      let $o1 := $a_o1 + $lastMatch
      let $o2 := $a_o2 + $lastMatch
      return
        if (($o1 <= count($a_w1)) or ($o2 <= count($a_w2)))
        then
        element oops
        {
          attribute w1 { $a_w1[$o1] },
          attribute w2 { $a_w2[$o2] },
          attribute o1 { $o1 },
          attribute o2 { $o2 }
        }
        else ()
  )
};

(:
  Recursive function to find synchronization point

  Parameters:
    $a_w1        first list of words
    $a_w2        second list of words
    $a_ignore    whether to do case-insensitive compares
    $a_o1        offset in first list
    $a_o2        offset in second list
    $a_isync     index into synchronization test point sequence

  Return value:
    <sync> element with attributes:
      l1 = length of l1 sequence
      l2 = length of l2 sequence
    () if empty input or no synchronization point is found
 :)
declare function almt:sync(
  $a_w1 as xs:string*,
  $a_w2 as xs:string*,
  $a_ignore as xs:boolean,
  $a_o1 as xs:integer,
  $a_o2 as xs:integer,
  $a_isync as xs:integer) as element()?
{
  (: if first list is empty :)
  if ($a_o1 > count($a_w1))
  then
    if ($a_o2 <= count($a_w2))
    then
      element sync
      {
        attribute l1 { 0 },
        attribute l2 { count($a_w2) - $a_o2 + 1 }
      }
    else ()
  else if ($a_o2 > count($a_w2))
  then
    element sync
    {
      attribute l1 { count($a_w1) - $a_o1 + 1 },
      attribute l2 { 0 }
    }

  (: if no more sync test points, we failed :)
  else if ($a_isync > count($almt:s_sync))
  then ()
  else
    let $so1 := $almt:s_sync[$a_isync]/@x
    let $so2 := $almt:s_sync[$a_isync]/@y
    (: count matches :)
    let $nmatches :=
      sum(for $i in (0 to $almt:s_match - 1)
          return
            if ($a_ignore)
            then
              if (lower-case($a_w1[$a_o1 + $so1 + $i]) =
                  lower-case($a_w2[$a_o2 + $so2 + $i]))
              then 1 else 0
            else
              if ($a_w1[$a_o1 + $so1 + $i] = $a_w2[$a_o2 + $so2 + $i])
              then 1 else 0
         )
    return
    (: if all words match :)
    if ($nmatches = $almt:s_match)
    then
      (: return result :)
      element sync
      {
        attribute l1 { $so1 },
        attribute l2 { $so2 }
      }
    else
      (: try next sync point :)
      almt:sync($a_w1, $a_w2, $a_ignore, $a_o1, $a_o2, $a_isync + 1)
};