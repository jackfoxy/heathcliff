::  heathcliff-perm: clay read and write rules, and crews
::
::    Clay keeps only current rules: %cp ignores the case.  Rules are
::    therefore read and changed at now, and a historical target shows
::    the current rules, labelled, and cannot change them.
::
::    Clay answers %crew and %crow with gifts and has no scry for either,
::    so the agent keeps a mirror (`cez`, `use`) and refreshes it after
::    each change; edits made elsewhere show after a reload.
::
|%
::  +|  Types
::
+$  crews  (map @ta crew:clay)
+$  usage  (map @ta (map desk [r=regs:clay w=regs:clay]))
::
::  +|  Constants
::
++  walk
  ::  How many paths one scan checks for explicit rules.
  ::
  ::    A %cp costs about 2ms and a desk root can have hundreds of
  ::    candidate paths, so the scan is bounded and says when it stopped.
  512
::
++  dull
  ::  The rule clay falls back to when nothing is set anywhere.
  `real:clay`[%white ~ ~]
::
::  +|  Cards
::
++  mirror
  ::  Ask clay for the crews; it answers with a %cruz gift.
  ^-  (list card:agent:gall)
  [%pass /perm/crew %arvo %c %crew ~]~
::
::  +|  Reading
::
++  pear
  ::  The read and write rules in force at `pax` on `desk`, now.
  |=  [=bowl:gall =desk pax=path]
  ^-  [red=dict:clay wit=dict:clay]
  =/  at=path  /(scot %p our.bowl)/[desk]/(scot %da now.bowl)
  .^([dict:clay dict:clay] %cp (weld at pax))
::
++  owns
  ::  Is a rule really set at `pax`, rather than inherited?
  ::
  ::    A dict's src is where its rule was found, so src == pax normally
  ::    means set here.  At the desk root clay answers src=/ with an empty
  ::    whitelist when no rule exists anywhere, which reads the same as
  ::    that rule set at /; the ambiguous case counts as unset, the
  ::    weaker claim and identical in effect.
  |=  [pax=path =dict:clay]
  ^-  ?
  ?.  =(pax src.dict)  |
  !&(?=(~ pax) =(rul.dict dull))
::
++  gist
  ::  What a resolved rule means, in one phrase.
  ::
  ::    An empty whitelist admits no one and an empty blacklist admits
  ::    everyone, which is easy to read backwards off the raw noun.
  |=  rul=real:clay
  ^-  @t
  =/  shp=@ud  ~(wyt in p.who.rul)
  =/  cru=@ud  ~(wyt by q.who.rul)
  ?:  &(=(0 shp) =(0 cru))
    ?:(=(%black mod.rul) 'public' 'private')
  =/  who=tape
    ;:  weld
      ?:(=(0 shp) "" "{(a-co:co shp)} ship{?:(=(1 shp) "" "s")}")
      ?:(|(=(0 shp) =(0 cru)) "" " and ")
      ?:(=(0 cru) "" "{(a-co:co cru)} crew{?:(=(1 cru) "" "s")}")
    ==
  (crip ?:(=(%black mod.rul) "everyone except {who}" "only {who}"))
::
++  scan
  ::  The explicit rules at or under `pax` on `desk`, now.
  ::
  ::    Clay cannot enumerate its rules, so they are reconstructed: the
  ::    candidates are every prefix of every file at or below `pax`, and
  ::    a rule is explicit where its dict's src is the candidate.  A rule
  ::    on a path with no files under it is invisible.
  |=  [=bowl:gall =desk pax=path]
  ^-  [more=? out=(list [=path red=(unit real:clay) wit=(unit real:clay)])]
  =/  at=path  /(scot %p our.bowl)/[desk]/(scot %da now.bowl)
  =/  wid=@ud  (lent pax)
  =/  files=(list path)
    =/  got=(each (list path) tang)
      (mule |.(.^((list path) %ct (weld at pax))))
    ?:(?=(%| -.got) ~ p.got)
  =/  can=(set path)
    %+  roll  files
    |=  [p=path seen=(set path)]
    ^-  (set path)
    ?.  (gte (lent p) wid)  seen
    =/  more=(list path)
      (turn (gulf wid (lent p)) |=(n=@ud `path`(scag n p)))
    (~(gas in seen) more)
  =/  all=(list path)  (sort ~(tap in (~(put in can) pax)) aor)
  :-  (gth (lent all) walk)
  %+  murn  (scag walk all)
  |=  p=path
  ^-  (unit [path (unit real:clay) (unit real:clay)])
  =/  d  .^([red=dict:clay wit=dict:clay] %cp (weld at p))
  =/  red=(unit real:clay)  ?:((owns p red.d) `rul.red.d ~)
  =/  wit=(unit real:clay)  ?:((owns p wit.d) `rul.wit.d ~)
  ?:  &(?=(~ red) ?=(~ wit))  ~
  `[p red wit]
::
++  cited
  ::  How often and where a crew is named, from the %crow mirror.
  |=  [=usage nom=@ta]
  ^-  [rules=@ud desks=@ud]
  =/  rus=(list [=desk r=regs:clay w=regs:clay])
    ~(tap by (~(gut by usage) nom *(map desk [r=regs:clay w=regs:clay])))
  :_  (lent rus)
  %+  roll  rus
  |=  [[=desk r=regs:clay w=regs:clay] n=@ud]
  :(add n ~(wyt by r) ~(wyt by w))
::
::  +|  JSON
::
++  ship-list
  ::  Ships sorted as they print.
  |=  who=(set ship)
  ^-  json
  :-  %a
  %+  turn
    (sort (turn ~(tap in who) |=(p=ship (scot %p p))) aor)
  |=(t=@t s+t)
::
++  rule-json
  ::  One side of the rule pair at `pax`, and where it comes from.
  |=  [pax=path =dict:clay]
  ^-  json
  =/  origin=@t
    ?:  (owns pax dict)  'here'
    ?:  &(?=(~ src.dict) =(rul.dict dull))  'default'
    'inherited'
  =/  cru=(list [nom=@ta mem=(set ship)])
    %+  sort  ~(tap by q.who.rul.dict)
    |=([a=[nom=@ta *] b=[nom=@ta *]] (aor nom.a nom.b))
  %-  pairs:enjs:format
  :~  ['mode' s+mod.rul.dict]
      ['gist' s+(gist rul.dict)]
      ['origin' s+origin]
      ['from' s+(spat src.dict)]
      ['ships' (ship-list p.who.rul.dict)]
      :-  'crews'
      :-  %a
      %+  turn  cru
      |=  [nom=@ta mem=(set ship)]
      (pairs:enjs:format ~[['name' s+nom] ['members' (ship-list mem)]])
  ==
::
++  crews-json
  ::  Every crew, its members, and where it is named.
  |=  [cez=crews =usage]
  ^-  json
  :-  %a
  %+  turn  (sort ~(tap in ~(key by cez)) aor)
  |=  nom=@ta
  =/  use  (cited usage nom)
  %-  pairs:enjs:format
  :~  ['name' s+nom]
      ['members' (ship-list (~(gut by cez) nom *crew:clay))]
      ['rules' (numb:enjs:format rules.use)]
      ['desks' (numb:enjs:format desks.use)]
  ==
::
++  perm-json
  ::  The permissions part of the attributes of `pax` on `desk`.
  |=  [=bowl:gall =desk pax=path cez=crews =usage]
  ^-  json
  =/  d  (pear bowl desk pax)
  =/  s  (scan bowl desk pax)
  =/  rule
    |=  r=(unit real:clay)
    ^-  json
    ?~(r ~ s+(gist u.r))
  %-  pairs:enjs:format
  :~  ['read' (rule-json pax red.d)]
      ['write' (rule-json pax wit.d)]
      :-  'explicit'
      %-  pairs:enjs:format
      :~  ['more' b+more.s]
          ['walk' (numb:enjs:format walk)]
          :-  'rows'
          :-  %a
          %+  turn  out.s
          |=  [p=path red=(unit real:clay) wit=(unit real:clay)]
          %-  pairs:enjs:format
          :~  ['path' s+(spat p)]
              ['read' (rule red)]
              ['write' (rule wit)]
          ==
      ==
      ['crews' (crews-json cez usage)]
      ::  verified against sys/vane/clay.hoon at 408K: +may-write has no
      ::  callers, so a write rule is a record, not a control
      ['enforced' (pairs:enjs:format ~[['read' b+&] ['write' b+|]])]
  ==
::
::  +|  Changes
::
++  words
  ::  Free text split on whitespace and commas.
  |=  t=@t
  ^-  (list @t)
  =/  sep  ;~(pose ace com (just '\0a') (just '\0d') (just '\09'))
  =/  raw=(list tape)
    %+  fall
      `(unit (list tape))`(rush t (more sep (star ;~(less sep next))))
    ~
  %+  murn  raw
  |=(s=tape ^-((unit @t) ?~(s ~ `(crip s))))
::
++  tally
  ::  "a, b, c" from a list of cords.
  |=  wor=(list @t)
  ^-  tape
  =/  nam=(list tape)  (turn wor |=(w=@t (trip w)))
  |-  ^-  tape
  ?~  nam    ""
  ?~  t.nam  i.nam
  :(weld i.nam ", " $(nam t.nam))
::
++  fleet
  ::  Ships parsed out of free text, and what did not parse.
  |=  t=@t
  ^-  [bad=(list @t) out=(set ship)]
  %+  roll  (words t)
  |=  [w=@t acc=[bad=(list @t) out=(set ship)]]
  ^-  [bad=(list @t) out=(set ship)]
  ?~  p=(slaw %p w)  [[w bad.acc] out.acc]
  [bad.acc (~(put in out.acc) u.p)]
::
++  named
  ::  Crew names in free text, and those that name no crew.
  |=  [cez=crews t=@t]
  ^-  [bad=(list @t) out=(set @ta)]
  %+  roll  (words t)
  |=  [w=@t acc=[bad=(list @t) out=(set @ta)]]
  ^-  [bad=(list @t) out=(set @ta)]
  ?.  (~(has by cez) `@ta`w)  [[w bad.acc] out.acc]
  [bad.acc (~(put in out.acc) `@ta`w)]
::
++  set-rule
  ::  The %perm card setting, or with `rule=~` clearing, one rule.
  ::
  ::    A cleared rule makes the node inherit from its parent again.
  ::    Clay acks a rule naming a crew it lacks and changes nothing, so
  ::    such a rule is refused here instead.
  |=  $:  cez=crews
          =desk
          pax=path
          red=?
          clear=?
          mode=@t
          ships=@t
          names=@t
      ==
  ^-  (each card:agent:gall @t)
  =/  send
    |=  new=(unit rule:clay)
    ^-  card:agent:gall
    =/  =rite:clay  ?:(red [%r new] [%w new])
    [%pass /perm/set %arvo %c %perm desk pax rite]
  ?:  clear  [%& (send ~)]
  =/  shp  (fleet ships)
  =/  cru  (named cez names)
  ?^  bad.shp  [%| (crip "not a ship: {(tally bad.shp)}")]
  ?^  bad.cru
    :-  %|
    %-  crip
    ;:  weld
      "no such crew: {(tally bad.cru)}.  clay ignores a rule naming a "
      "crew it does not have, so this was not sent; create the crew first."
    ==
  =/  who=(set whom:clay)
    %-  ~(gas in *(set whom:clay))
    %+  weld
      (turn ~(tap in out.shp) |=(s=ship `whom:clay`[%& s]))
    (turn ~(tap in out.cru) |=(n=@ta `whom:clay`[%| n]))
  [%& (send `[?:(=('black' mode) %black %white) who])]
::
++  crew-save
  ::  The cards creating or replacing a crew, or why not.
  |=  [nom=@t members=@t]
  ^-  (each (list card:agent:gall) @t)
  ?:  =('' nom)  [%| 'a crew needs a name']
  ?.  ((sane %tas) nom)
    [%| 'a crew name is lowercase letters, digits and hyphens']
  =/  shp  (fleet members)
  ?^  bad.shp  [%| (crip "not a ship: {(tally bad.shp)}")]
  ?:  =(~ out.shp)
    [%| 'a crew with no members deletes it; use delete for that']
  :-  %&
  :~  [%pass /perm/cred %arvo %c %cred `@ta`nom out.shp]
      [%pass /perm/crew %arvo %c %crew ~]
  ==
::
++  crew-kill
  ::  The cards deleting a crew, or why not.
  ::
  ::    Clay strips a deleted crew from every rule naming it, which
  ::    tightens a whitelist but loosens a blacklist.
  |=  [cez=crews nom=@t]
  ^-  (each (list card:agent:gall) @t)
  ?.  (~(has by cez) `@ta`nom)  [%| 'no such crew']
  :-  %&
  :~  [%pass /perm/cred %arvo %c %cred `@ta`nom ~]
      [%pass /perm/crew %arvo %c %crew ~]
  ==
--
