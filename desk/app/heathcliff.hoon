::  heathcliff: clay exposed
::
::    viewing, editing, down- and uploading of filesystem contents
::
::TODO  code quality
::
/+  multipart, server, dbug, verb, default-agent
::
|%
+$  state-0  [%0 pend=(map eyre-id [=mode =beam])]  ::  posts pending response
::
::  state-1: mirrors of clay's permission groups
::
::    clay answers %crew and %crow with gifts and exposes no scry for either,
::    so there is no way to read the crews during a page render.  we keep a
::    copy instead, and refresh it whenever we change one.  going stale is
::    possible if crews are edited elsewhere (dojo), hence the reload button.
::
::    cez: every crew, by name.
::    use: which desks and paths name each crew, so deleting one can say what
::         it is about to affect.  clay strips a deleted crew from every rule,
::         which tightens a whitelist but *loosens* a blacklist.
::
+$  state-1
  $:  %1
      cez=(map @ta crew:clay)
      use=(map @ta (map desk [r=regs:clay w=regs:clay]))
  ==
::
+$  versioned-state  $%(state-0 state-1)
::
+$  mode
  ::TODO  %tree view?
  $?  %view  %edit  ::  w/ wrapper ui
      %perm         ::  w/ wrapper ui, permissions
      %down  %load  ::  raw down/upload
  ==
::
+$  card  card:agent:gall
::
+$  eyre-id  @ta
--
::
=|  state-1
=*  state  -
::
%-  agent:dbug
%+  verb  |
::
=<  ^-  agent:gall
  |_  =bowl:gall
  +*  this  .
      def   ~(. (default-agent this %|) bowl)
  ::
  ++  on-init
    ^-  (quip card _this)
    :_  this
    :-  [%pass /eyre/connect %arvo %e %connect [~ /[dap.bowl]] dap.bowl]
    mirror
  ::
  ++  on-save  !>(state)
  ::
  ++  on-load
    |=  ole=vase
    ^-  (quip card _this)
    =/  old=versioned-state  !<(versioned-state ole)
    =/  new=state-1
      ?-  -.old
        %1  old
        %0  [%1 ~ ~]  ::  pend was always cleared here and never written
      ==
    [mirror this(state new)]
  ::
  ++  on-poke
    |=  [=mark =vase]
    ^-  (quip card _this)
    ?+  mark  (on-poke:def mark vase)
      ::  %handle-http-request: incoming from eyre
      ::
        %handle-http-request
      :_  this
      =,  mimes:html
      =+  !<([=eyre-id =inbound-request:eyre] vase)
      ?.  authenticated.inbound-request
        ::TODO  depend on publicness of requested file?
        ::TODO  probably put a function for this into /lib/server
        ::      we can't use +require-authorization because we also emit cards
        %+  give-simple-payload:app:server
          eyre-id
        =-  [[307 ['location' -]~] ~]
        %^  cat  3
          '/~/login?redirect='
        url.request.inbound-request
      ::  parse request url into path and query args
      ::
      =/  ,request-line:server
        (parse-request-line:server url.request.inbound-request)
      ::
      ::  out: page or edit
      ::
      =;  out=(each simple-payload:http [l=@t c=(list card)])
        ?-  -.out
          %&  (give-simple-payload:app:server eyre-id p.out)
          %|  %+  weld  c.p.out
              %+  give-simple-payload:app:server  eyre-id
              [[303 ['location' l.p.out]~] ~]
        ==
      ::  500 to all unexpected requests
      ::
      ?.  &(?=(^ site) =(dap.bowl i.site))
        [%& [500 ~] `(as-octs 'unexpected route')]
      ::  400 to all invalid requests
      ::
      =*  invalid  [%& [400 ~] `(as-octs 'invalid route')]
      ::TODO  support viewing foreign desks?
      ?.  ?=([mode %our @ @ *] t.site)
        invalid
      ?^  ext  invalid
      =/  cus=(unit case)
        =+  (de-case i.t.t.t.t.site)
        ?+  -  ~
          [~ ?(%ud %da) @]  -
          [~ %tas %now]     `da+now.bowl
        ==
      ?~  cus    invalid
      =/  =mode  i.t.site
      =/  =ship  our.bowl
      =/  =desk  i.t.t.t.site
      =/  =case  u.cus
      =/  =path  t.t.t.t.t.site
      ?:  &(!=(~ path) =(~ (rear path)))  invalid  ::  reject trailing /
      ::
      =*  beam  [[ship desk case] path]
      =+  go=~(. work bowl mode beam state)
      ?-  mode
        %view  [%& (view:go request.inbound-request)]
        %edit  (edit:go request.inbound-request)
        %perm  (perm:go request.inbound-request)
        %down  [%& (down:go request.inbound-request)]
        %load  (load:go request.inbound-request)
      ==
    ==
  ::
  ++  on-watch
    |=  =path
    ^-  (quip card _this)
    ::NOTE  deliberately no =(our src) assertion here. eyre subscribes to
    ::      /http-response on our behalf using the _requester's_ identity,
    ::      which for a logged-out visitor is a synthesized comet. asserting
    ::      crashes the subscription, 500s every unauthenticated request, and
    ::      makes the login redirect in +on-poke unreachable.
    ?+  path  (on-watch:def path)
      [%http-response *]  [~ this]
    ==
  ::
  ++  on-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)
    ?+  wire  (on-arvo:def wire sign-arvo)
        [%eyre %connect ~]
      ?>  ?=([%eyre %bound *] sign-arvo)
      ~?  !accepted.sign-arvo
        [dap.bowl 'eyre bind rejected!' binding.sign-arvo]
      [~ this]
    ::
    ::  the crew mirror.  %cruz carries every crew; %croz carries usage but
    ::  not the crew it describes, so the name rides on the wire.
    ::
        [%perm %crew ~]
      ?>  ?=([%clay %cruz *] sign-arvo)
      :_  this(cez cez.sign-arvo, use ~)
      %+  turn  ~(tap in ~(key by `(map @ta crew:clay)`cez.sign-arvo))
      |=(nom=@ta ^-(card [%pass /perm/crow/[nom] %arvo %c %crow nom]))
    ::
        [%perm %crow @ ~]
      ?>  ?=([%clay %croz *] sign-arvo)
      [~ this(use (~(put by use) i.t.t.wire rus.sign-arvo))]
    ==
  ::
  ++  on-leave  on-leave:def
  ++  on-agent  on-agent:def
  ++  on-peek   on-peek:def
  ++  on-fail   on-fail:def
  --
::
|%
::  +ctype: content type for marks we know cast to %mime
::
::    membership doubles as the allowlist for building a mark->mime tube.
::    there is no way to ask clay whether a cast exists without building it,
::    and a failed build crashes uncatchably, so an explicit list is the only
::    crash-free option. marks absent here still download via +raw; they just
::    don't get a tube. covers %base and %yard as of 408K.
::
++  ctype
  |=  =mark
  ^-  (unit mite)
  ?+  mark  ~
    ::  text
    %txt         `/text/plain
    %hoon        `/text/x-hoon
    %css         `/text/css
    %js          `/text/javascript
    %json        `/application/json
    %html        `/text/html
    %hymn        `/text/html
    %xml         `/text/xml
    %csv         `/text/csv
    ::  '+' isn't a legal knot character, so this one can't be a path literal
    %svg         [~ `mite`~['image' 'svg+xml']]
    ::  images
    %png         `/image/png
    %jpg         `/image/jpeg
    %jpeg        `/image/jpeg
    %gif         `/image/gif
    %bmp         `/image/bmp
    %ico         `/image/x-icon
    %tiff        `/image/tiff
    %webp        `/image/webp
    ::  audio
    %mp3         `/audio/mpeg
    %wav         `/audio/wav
    %ogg         `/audio/ogg
    %oga         `/audio/ogg
    %flac        `/audio/flac
    %aac         `/audio/aac
    %weba        `/audio/webm
    %mid         `/audio/midi
    ::  video
    %mp4         `/video/mp4
    %webm        `/video/webm
    %ogv         `/video/ogg
    %mpeg        `/video/mpeg
    %avi         `/video/x-msvideo
    ::  fonts
    %ttf         `/font/ttf
    %otf         `/font/otf
    %woff2       `/font/woff2
    ::  documents
    %pdf         `/application/pdf
    %pem         `/application/x-pem-file
    %wasm        `/application/wasm
    ::  urbit-native, rendered as text
    ?(%atom %bill %kelvin %noun %ship %snip %story)  `/text/plain
    ?(%docket-0 %jam %map %udon %umd %urb)           `/text/plain
    %noun-autodiff                                   `/text/plain
  ==
::
::  +limit: largest upload we'll accept, to keep a stray POST from
::          committing something enormous into a desk
::
++  limit  (bex 23)  ::  8MiB
::
::  +walk: how many paths we'll check for explicit rules in one page
::
::    a %cp costs around 2ms, and a desk root can easily have several hundred
::    candidate paths, so this is bounded and the page says when it truncated.
::
++  walk  512
::
::  +ships: "~zod, ~nec", for rule membership
::
++  ships
  |=  who=(set ship)
  ^-  tape
  ::  sorted on the rendered name, not the raw @p, so the order reads the way
  ::  it looks
  =/  nam=(list tape)
    %+  sort  `(list tape)`(turn ~(tap in who) |=(p=ship (scow %p p)))
    aor
  |-  ^-  tape
  ?~  nam    ""
  ?~  t.nam  i.nam
  :(weld i.nam ", " $(nam t.nam))
::
::  +mirror: ask clay for the crews.  it answers with a gift, in on-arvo
::
++  mirror  ^-((list card:agent:gall) [%pass /perm/crew %arvo %c %crew ~]~)
::
::  +words: split free text on whitespace and commas
::
++  words
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
::  +tally: "a, b, c" from a list of cords
::
++  tally
  |=  wor=(list @t)
  ^-  tape
  =/  nam=(list tape)  (turn wor |=(w=@t (trip w)))
  |-  ^-  tape
  ?~  nam    ""
  ?~  t.nam  i.nam
  :(weld i.nam ", " $(nam t.nam))
::
::  +fleet: parse ships out of free text, keeping what didn't parse
::
++  fleet
  |=  t=@t
  ^-  [bad=(list @t) out=(set ship)]
  %+  roll  (words t)
  |=  [w=@t acc=[bad=(list @t) out=(set ship)]]
  ^-  [bad=(list @t) out=(set ship)]
  ?~  p=(slaw %p w)  [[w bad.acc] out.acc]
  [bad.acc (~(put in out.acc) u.p)]
::
::  +dull: the rule clay falls back to when nothing is set anywhere
::
++  dull  `real:clay`[%white ~ ~]
::
::  +owns: whether a rule is really set at pax, as opposed to inherited
::
::    a dict's src is the path its rule was found at, so src == pax normally
::    means "set here".  the exception is the desk root: clay hands back
::    src=/ with a hardcoded empty whitelist when no rule exists anywhere,
::    which is indistinguishable from someone having set that same rule at /.
::    we call the ambiguous case unset -- it's the weaker claim, and the two
::    are identical in effect regardless.
::
++  owns
  |=  [pax=path =dict:clay]
  ^-  ?
  ?.  =(pax src.dict)  |
  !&(?=(~ pax) =(rul.dict dull))
::
::  +gist: what a resolved rule actually means, in one phrase
::
::    an empty whitelist admits no one and an empty blacklist admits everyone,
::    which is easy to read backwards off the raw noun -- hence spelling it out.
::
++  gist
  |=  rul=real:clay
  ^-  tape
  =/  shp=@ud  ~(wyt in p.who.rul)
  =/  cru=@ud  ~(wyt by q.who.rul)
  ?:  &(=(0 shp) =(0 cru))
    ?:(=(%black mod.rul) "public" "private")
  =/  who=tape
    ;:  weld
      ?:(=(0 shp) "" "{(scow %ud shp)} ship{?:(=(1 shp) "" "s")}")
      ?:(|(=(0 shp) =(0 cru)) "" " and ")
      ?:(=(0 cru) "" "{(scow %ud cru)} crew{?:(=(1 cru) "" "s")}")
    ==
  ?:(=(%black mod.rul) "everyone except {who}" "only {who}")
::
::  +kin: the marks a given mark needs in order to build, dependencies first
::
::    a mark written as `++grad %foo` delegates its diff to mark %foo, and
::    clay builds %foo to build it -- so installing one means installing the
::    other. a mark whose ++grad is an inline core is terminal, even when its
::    ++form names another mark: %txt says `++form %txt-diff` but builds fine
::    without mar/txt-diff, because the name is never resolved as a mark.
::    that makes every chain here exactly one deep.
::
++  kin
  |=  =mark
  ^-  (list ^mark)
  ?+  mark  ~[%mime mark]  ::  the large majority grad to %mime
    ::  inline ++grad cores: nothing further to build
    ?(%mime %noun %txt)                                ~[mark]
    ::  ++grad %noun
    ?(%bill %docket-0 %hymn %kelvin %ship %snip %urb)  ~[%noun mark]
    %txt-diff                                          ~[%noun mark]
    ::  ++grad %txt
    ?(%hoon %udon %umd)                                ~[%txt mark]
  ==
::
::  +safe: coerce arbitrary text into something usable as a path element
::
++  safe
  |=  t=@t
  ^-  @ta
  %-  crip
  %+  turn  (trip t)
  |=  c=@tD
  ^-  @tD
  ?:  &((gte c 'A') (lte c 'Z'))  (add c 32)
  ?:  ?|  &((gte c 'a') (lte c 'z'))
          &((gte c '0') (lte c '9'))
          =('-' c)
      ==
    c
  '-'
::
::  +splt: filename -> [name mark], as clay path elements
::
::    clay has no notion of an extension: foo.png is the file /foo/png, whose
::    mark is png. so the extension is load-bearing, and a file without one
::    leaves us no mark to write it under.
::
++  splt
  |=  fil=@t
  ^-  (unit [nam=@ta =mark])
  =/  t=tape  (trip fil)
  ::  split on the last dot
  ?~  dex=(find "." (flop t))  ~  ::  no extension, so no mark
  =/  cut=@ud  (sub (lent t) +(u.dex))
  =/  nam=@ta  (safe (crip (scag cut t)))
  =/  ext=@ta  (safe (crip (slag +(cut) t)))
  ?:  |(=('' ext) =('' nam))  ~
  `[nam ext]
::
++  work
  |_  [bowl:gall =mode =beam sat=state-1]
  ++  arch  ~+  .^(^arch %cy rend)
  ++  tree  ~+  .^((list path) %ct rend)
  ++  cass  ~+  .^(cass:clay %cw rend)
  ++  last  ~+  ud:.^(cass:clay %cw rend(r.beam da+now))
  ++  rend  ~+  (en-beam beam)
  ::
  ++  fils  ?=(^ [fil:arch])  ::TODO  why are the [] needed?
  ++  have  &(fils live)      ::  a file whose data we can still read
  ++  gone  &(fils !live)     ::  a file whose data has been tombstoned
  ::
  ::  +live: whether this node's data is still in the store
  ::
  ::    a tombstoned file still shows up in the %cy arch with its lobe
  ::    intact, but %cx/%cq on it crashes -- and that crash bails the whole
  ::    event, escaping virtualization, so it cannot be caught with +mule.
  ::    we have to ask before reading.
  ::
  ++  live  ~+
    ^-  ?
    ?.  fils  |
    .^  ?  %cx
        %+  weld
          `path`[(scot %p our) %$ (scot %da now) %tomb ~]
        rend
    ==
  ::
  :: ++  curb  ?+  -.r.beam  !!  ::TODO  as wrapper function
  ::             %ud  (gth p.r.beam ud:.^(cass:clay %cw rend(r.beam da+now)))
  ::             %da  (gth p.r.beam now)
  ::           ==
  ::
  ::
  ++  sput  ~+  (spud dap mode spot)
  ++  spot  ~+
    ^-  path
    =+  ?:(=(da+now r.beam) rend(r.beam tas+%now) rend)
    ?.  =(p.beam our)  -
    [%our (slag 1 -)]
  ::
  ++  show  ~+
    ^-  (unit mime)
    ?.  have  ~  ::  absent, or tombstoned
    =/  =mark  (rear s.beam)
    ::  %mime needs no mark build at all, clay special-cases it
    ::
    ?:  =(%mime mark)  `.^(mime %cx rend)
    ::  detect tube scry failures ahead of time, per the TODO that used to
    ::  live here. building a mark the desk doesn't carry, or one with no
    ::  mime cast, crashes uncatchably (see +live), so we never build one
    ::  we aren't confident in, and read typelessly instead.
    ::
    ?.  &(?=(^ (ctype mark)) .^(? %cu rend(r.beam da+now, s.beam /mar/[mark]/hoon)))
      (raw mark)
    =;  =tube:clay
      `!<(mime (tube .^(vase %cr rend)))
    ::NOTE  because %c scries crash on older revisions, we do a best-effort
    ::      here by using the current mark definition instead.
    ::      eventually, clay should be patched to support historic %c,
    ::      and this should be updated to not use da+now.
    .^(tube:clay %cc rend(r.beam da+now, s.beam /[mark]/mime))
  ::
  ::  +raw: typeless read, for files whose mark we can't safely build
  ::
  ::    %cq hands back the stored noun without touching marks, so it works
  ::    on any desk. atom-shaped marks (most binary formats) serve directly;
  ::    anything structured we decline to render rather than guess.
  ::
  ++  raw
    |=  =mark
    ^-  (unit mime)
    =/  dat  .^(* %cq rend)
    ?.  ?=(@ dat)  ~
    `[(fall (ctype mark) /application/octet-stream) [(met 3 dat) dat]]
  ::
  ::
  ++  view
    |=  request:http
    ^-  simple-payload:http
    ?.  ?=(%'GET' method)  deny
    (page ~)
  ::
  ++  perm
    |=  request:http
    ^-  (each simple-payload:http [loc=@t (list card)])
    ?+  method  [%& `simple-payload:http`deny]
      %'GET'  [%& (page ~)]
    ::
        %'POST'
      ::  permissions aren't versioned, so editing from an older case would
      ::  imply we were changing that revision's rules.  we aren't.
      ?.  =(da+now r.beam)
        [%& (oops "permissions can only be changed at now")]
      =/  are=(unit (map @t @t))
        ?~  body  ~
        %+  bind
          (rush q.u.body yquy:de-purl:html)
        ~(gas by *(map @t @t))
      ?~  are  [%& (oops "couldn't read the form")]
      (deed u.are)
    ==
  ::
  ++  edit
    |=  request:http
    ^-  (each simple-payload:http [loc=@t (list card)])
    ::  editing only makes sense against the head of the desk. now that
    ::  historical cases render, this is reachable by hand, so decline it
    ::  politely instead of crashing.
    ?.  =(da+now r.beam)  [%& wack]
    ?+  method  [%& deny]
      %'GET'   [%& (page ~)]
    ::
        %'POST'
      =/  are=(unit (map @t @t))
        ?~  body  ~
        %+  bind
          (rush q.u.body yquy:de-purl:html)
        ~(gas by *(map @t @t))
      ?~  are  [%& wack]
      =*  arm  u.are
      ?:  (~(has by arm) 'cancel')
        [%| (crip sput(mode %view)) ~]
      ?:  (~(has by arm) 'delete')
        :+  %|  (crip sput)
        [%pass /edit/delete %arvo %c %info (fray:space:userlib rend)]~
      ?.  (~(has by arm) 'save')  [%& wack]
      ?.  (~(has by arm) 'file')  [%& wack]
      :+  %|  (crip sput)
      :_  ~
      :+  %pass  /edit/save
      :+  %arvo  %c
      =;  =mime
        [%info (foal:space:userlib rend %mime !>(mime))]
      :-  /application/x-urb-unknown
      %-  as-octt:mimes:html
      %+  rash  (~(got by arm) 'file')
      (star ;~(pose (cold '\0a' (jest '\0d\0a')) next))
    ==
  ::
  ++  down
    |=  request:http
    ^-  simple-payload:http
    ?.  ?=(%'GET' method)  deny
    =+  m=show
    ?~  m  miss
    :_  `q.u.m
    [200 ['content-type'^(en-mite:mimes:html p.u.m)]~]
  ::
  ::  +pear: read and write permissions in force at this node
  ::
  ::    pinned to now on purpose. clay's %cp ignores the case entirely --
  ::    +read-p takes only a path -- so permissions are always current state,
  ::    never historical. asking at the browsed case would imply a history
  ::    clay doesn't keep, so we ask at now and label it as such in the ui.
  ::
  ++  pear  ~+
    ^-  [red=dict:clay wit=dict:clay]
    .^([dict:clay dict:clay] %cp rend(r.beam da+now))
  ::
  ::  +sown: explicit rules at or under this node
  ::
  ::    clay exposes no way to enumerate its regs, so we reconstruct them: a
  ::    dict's src is the path its rule was found at, so src == path is
  ::    exactly "there's an explicit rule here". candidates are every prefix
  ::    of every file at or below us, which misses rules set on paths with no
  ::    files under them -- the only blind spot, and not one clay lets us fix.
  ::
  ++  sown  ~+
    ^-  [more=? out=(list [=path red=(unit real:clay) wit=(unit real:clay)])]
    =/  wid=@ud  (lent s.beam)
    =/  can=(list path)
      %~  tap  in
      %-  ~(gas in *(set path))
      %-  zing
      %+  turn  tree
      |=  p=path
      ^-  (list path)
      ?.  (gte (lent p) wid)  ~
      (turn (gulf wid (lent p)) |=(n=@ud (scag n p)))
    :-  (gth (lent can) walk)
    %+  murn  (scag walk (sort can aor))
    |=  p=path
    ^-  (unit [path (unit real:clay) (unit real:clay)])
    =/  d  .^([red=dict:clay wit=dict:clay] %cp rend(r.beam da+now, s.beam p))
    =/  red=(unit real:clay)  ?:((owns p red.d) `rul.red.d ~)
    =/  wit=(unit real:clay)  ?:((owns p wit.d) `rul.wit.d ~)
    ?:  &(?=(~ red) ?=(~ wit))  ~
    `[p red wit]
  ::
  ++  fire
    |=  [red=? new=(unit rule:clay)]
    ^-  (each simple-payload:http [loc=@t (list card)])
    :+  %|  (crip sput)
    :_  ~
    :+  %pass  /perm/set
    :+  %arvo  %c
    :+  %perm  q.beam
    :-  s.beam
    `rite:clay`?:(red [%r new] [%w new])
  ::
  ++  crew-save
    |=  arm=(map @t @t)
    ^-  (each simple-payload:http [loc=@t (list card)])
    =/  nom=@t  (~(gut by arm) 'name' '')
    ?:  =('' nom)  [%& (oops "a crew needs a name")]
    ?.  =(nom (safe nom))
      :-  %&
      %-  oops
      "that will not do as a crew name - lowercase, digits and hyphens"
    =/  shp  (fleet (~(gut by arm) 'members' ''))
    ?^  bad.shp  [%& (oops "not a ship: {(tally bad.shp)}")]
    ?:  =(~ out.shp)
      [%& (oops "a crew with no members deletes it - use delete if you meant that")]
    :+  %|  (crip sput)
    :~  [%pass /perm/cred %arvo %c %cred `@ta`nom out.shp]
        [%pass /perm/crew %arvo %c %crew ~]
    ==
  ::
  ++  crew-kill
    |=  arm=(map @t @t)
    ^-  (each simple-payload:http [loc=@t (list card)])
    =/  nom=@t  (~(gut by arm) 'name' '')
    ?.  (~(has by cez.sat) `@ta`nom)  [%& (oops "no such crew")]
    :+  %|  (crip sput)
    :~  [%pass /perm/cred %arvo %c %cred `@ta`nom ~]
        [%pass /perm/crew %arvo %c %crew ~]
    ==
  ::
  ++  named
    |=  t=@t
    ^-  [bad=(list @t) out=(set @ta)]
    %+  roll  (words t)
    |=  [w=@t acc=[bad=(list @t) out=(set @ta)]]
    ^-  [bad=(list @t) out=(set @ta)]
    ?.  (~(has by cez.sat) `@ta`w)  [[w bad.acc] out.acc]
    [bad.acc (~(put in out.acc) `@ta`w)]
  ::
  ++  grant
    |=  [arm=(map @t @t) keep=?]
    ^-  (each simple-payload:http [loc=@t (list card)])
    =/  wat=@t  (~(gut by arm) 'kind' '')
    ?.  ?|(=('r' wat) =('w' wat))  [%& (oops "which rule was that?")]
    =/  red=?  =('r' wat)
    ::  a ~ rule deletes the entry, so the node inherits from its parent again
    ?.  keep  (fire red ~)
    =/  shp  (fleet (~(gut by arm) 'ships' ''))
    =/  cru  (named (~(gut by arm) 'crews' ''))
    ?^  bad.shp
      [%& (oops "not a ship: {(tally bad.shp)}")]
    ?^  bad.cru
      :-  %&
      %-  oops
      ;:  weld
        "no such crew: {(tally bad.cru)}.  clay ignores a rule naming a crew "
        "it doesn't have -- it acks the poke and changes nothing -- so this "
        "was not sent.  create the crew first, below."
      ==
    =/  who=(list whom:clay)
      %+  weld
        `(list whom:clay)`(turn ~(tap in out.shp) |=(s=ship `whom:clay`[%& s]))
      `(list whom:clay)`(turn ~(tap in out.cru) |=(n=@ta `whom:clay`[%| n]))
    %-  fire
    :-  red
    :-  ~
    :-  ?:(=('black' (~(gut by arm) 'mode' 'white')) %black %white)
    (~(gas in *(set whom:clay)) who)
  ::  +cited: where a crew is referenced, from the %crow mirror
  ::
  ++  cited
    |=  nom=@ta
    ^-  tape
    =/  rus=(list [=desk r=regs:clay w=regs:clay])
      ~(tap by (~(gut by use.sat) nom *(map desk [r=regs:clay w=regs:clay])))
    ?~  rus  "nowhere"
    =/  dez=@ud  (lent rus)
    =/  n=@ud
      =/  lit=(list [=desk r=regs:clay w=regs:clay])  rus
      |-  ^-  @ud
      ?~  lit  0
      :(add ~(wyt by r.i.lit) ~(wyt by w.i.lit) $(lit t.lit))
    ;:  weld
      "{(scow %ud n)} rule"  ?:(=(1 n) "" "s")
      " across {(scow %ud dez)} desk"  ?:(=(1 dez) "" "s")
    ==
  ::
  ::  +deed: dispatch a POST from one of the permission forms
  ::
  ++  deed
    |=  arm=(map @t @t)
    ^-  (each simple-payload:http [loc=@t (list card)])
    ?:  (~(has by arm) 'reload')     [%| (crip sput) mirror]
    ?:  (~(has by arm) 'crew-save')  (crew-save arm)
    ?:  (~(has by arm) 'crew-kill')  (crew-kill arm)
    ?:  (~(has by arm) 'clear')      (grant arm |)
    ?:  (~(has by arm) 'save')       (grant arm &)
    [%& (oops "unrecognised form")]
  ::
  ::  +want: which of a mark's dependencies the target desk is missing
  ::
  ++  want
    |=  =mark
    ^-  (list ^mark)
    %+  skip  (kin mark)
    |=  m=^mark
    .^(? %cu rend(r.beam da+now, s.beam /mar/[m]/hoon))
  ::
  ::  +vend: source for a mark cliff carries, to install on another desk
  ::
  ++  vend
    |=  =mark
    ^-  (unit @t)
    =/  pax=path  /(scot %p our)/[q.byk]/(scot %da now)/mar/[mark]/hoon
    ?.  .^(? %cu pax)  ~
    `.^(@t %cx pax)
  ::
  ++  load
    |=  request:http
    ^-  (each simple-payload:http [loc=@t (list card)])
    ?.  ?=(%'POST' method)  [%& `simple-payload:http`deny]
    ::  uploads only make sense against the head of the desk
    ?.  =(da+now r.beam)  [%& `simple-payload:http`wack]
    ?~  par=(de-request:multipart header-list body)
      [%& (oops "expected a multipart/form-data upload")]
    (take (~(gas by *(map @t part:multipart)) u.par))
  ::
  ::  +take: commit an uploaded file, with the marks it needs
  ::
  ::    clay validates every changed file at commit time, building its mark to
  ::    do so, so a file can't land on a desk that doesn't carry its mark. we
  ::    put the marks and the file in a single %info, which commits atomically:
  ::    either the desk gains a working file or it gains nothing.
  ::
  ++  take
    |=  arm=(map @t part:multipart)
    ^-  (each simple-payload:http [loc=@t (list card)])
    ?~  fil=(~(get by arm) 'file')
      [%& (oops "no file was submitted")]
    ?~  file.u.fil
      [%& (oops "the upload had no filename")]
    =*  nom  (trip u.file.u.fil)
    ?:  =(0 size.u.fil)
      [%& (oops "{nom} is empty")]
    ?:  (gth size.u.fil limit)
      [%& (oops "{nom} is larger than the {(scow %ud (rsh 3^10 limit))}KiB limit")]
    ?~  spl=(splt u.file.u.fil)
      [%& (oops "can't derive a mark from {nom} - it needs an extension")]
    =*  nam  nam.u.spl
    =*  mak  mark.u.spl
    ::  a mark over a bare atom cannot hold trailing NUL bytes -- an atom has
    ::  no high-order zeros, so they're gone the moment we hand them over, and
    ::  the mark's ++grow recomputes the length with +met on the way back out.
    ::  %mime is the exception: it stores octs, which carry the length. refuse
    ::  rather than quietly hand back a shorter file than we were given.
    ::
    =/  nul=@ud  (sub size.u.fil (met 3 body.u.fil))
    ?:  &(!=(%mime mak) !=(0 nul))
      :-  %&
      %-  oops
      ;:  weld
        "{nom} ends in {(scow %ud nul)} NUL byte"  ?:(=(1 nul) "" "s")
        ", which the %{(trip mak)} mark can't store - marks over a bare atom "
        "have no high-order zeros.  rename it to end in .mime to store it "
        "byte-for-byte instead."
      ==
    ::  marks the target desk is missing, and whether we may add them
    ::
    =/  gap=(list mark)  (want mak)
    =/  yea=?            (~(has by arm) 'marks')
    ?:  &(?=(^ gap) !yea)
      :-  %&
      %-  oops
      ;:  weld
        "%{(trip q.beam)} doesn't carry "
        (mark-list gap)
        ", which {nom} needs.  "
        "tick \"install missing marks\" to add "
        ?:(?=([* ~] gap) "it" "them")  " to the desk."
      ==
    =/  new=(list [=mark src=@t])
      %+  murn  gap
      |=(m=mark ^-((unit [mark @t]) ?~(s=(vend m) ~ `[m u.s])))
    ?.  =((lent new) (lent gap))
      :-  %&
      %-  oops
      "heathcliff has no source for {(mark-list gap)}, so it can't install {?:(?=([* ~] gap) "it" "them")}."
    ::
    =/  tar=path  (weld s.beam /[nam]/[mak])
    =/  =mime
      :_  [size body]:u.fil
      (fall type.u.fil (fall (ctype mak) /application/octet-stream))
    :-  %|
    :-  (crip sput(mode %view, s.beam tar))
    :_  ~
    :+  %pass  /load/save
    :+  %arvo  %c
    :+  %info  q.beam
    :-  %&
    %+  weld
      ^-  soba:clay
      %+  turn  new
      |=([m=mark src=@t] ^-([path miso:clay] [/mar/[m]/hoon %ins %hoon !>(src)]))
    ^-  soba:clay
    [tar (feel:space:userlib rend(s.beam tar) %mime !>(mime))]~
  ::
  ::  +mark-list: "%png and %mime", for error text
  ::
  ++  mark-list
    |=  mus=(list mark)
    ^-  tape
    =/  nam=(list tape)  (turn mus |=(m=mark "%{(trip m)}"))
    |-  ^-  tape
    ?~  nam        ""
    ?~  t.nam      i.nam
    ?~  t.t.nam    "{i.nam} and {i.t.nam}"
    "{i.nam}, {$(nam t.nam)}"
  ::
  ++  deny  [[405 ~] `(as-octs:mimes:html 'method not allowed')]
  ++  miss  [[404 ~] `(as-octs:mimes:html 'file not found')]
  ++  wack  [[400 ~] `(as-octs:mimes:html 'invalid request')]
  ::
  ::  +oops: re-render this node with an error banner
  ::
  ::    rendered as %view: we're answering a POST, and the page's own links
  ::    would otherwise all point back at the POST-only route we came in on.
  ::
  ++  oops
    |=  msg=tape
    ^-  simple-payload:http
    =/  pay=simple-payload:http  (page(mode %view) `(crip msg))
    pay(status-code.response-header 400)
  ::
  ::  +hive: every path in the desk, for the navigation tree
  ::
  ::    %ct is answered straight out of the yaki at the requested aeon, so it
  ::    is safe on historical cases and comes back sorted.  paths are full
  ::    desk paths regardless of where in the desk we ask.
  ::
  ++  hive  ~+  .^((list path) %ct rend(s.beam ~))
  ::
  ::  page: renders file/directory content alongside metadata
  ::
  ::    page structure is roughly as follows:
  ::    header: brand, interactive beam
  ::    tree pane: desk selector, up, desk-wide file tree
  ::    workspace: notice, content or editor, metadata footer
  ::
  ++  page
    |=  msg=(unit @t)
    =/  edit=?  =(%edit mode)
    ::  step: the mode the tree and listing links navigate in
    ::
    ::    a directory has no edit page, so links out of an editor go to the
    ::    view of their target instead of a route that would 400.
    ::
    =/  step  ?:(edit %view mode)
    ^-  simple-payload:http
    :-  [200 ['content-type'^'text/html']~]
    |^  `(as-octt:mimes:html (en-xml:html full))
    ::
    ++  style
      '''
      :root {
        color-scheme: light dark;
        --bg: #f7f7f4;
        --surface: #ffffff;
        --surface-alt: #f0f0eb;
        --text: #181817;
        --muted: #66665f;
        --border: #d4d4cc;
        --accent: #6d28d9;
        --focus: #2563eb;
        --warn: #a4530f;
        --tree-width: 20rem;
        font-family: Inter, ui-sans-serif, system-ui, sans-serif;
        font-size: 15px;
      }

      @media (prefers-color-scheme: dark) {
        :root {
          --bg: #11110f;
          --surface: #191917;
          --surface-alt: #22221f;
          --text: #f2f2ec;
          --muted: #a7a79e;
          --border: #3b3b35;
          --accent: #8b5cf6;
          --focus: #60a5fa;
          --warn: #f0b45c;
        }
      }

      * { box-sizing: border-box; }

      html, body { height: 100%; margin: 0; }

      body {
        background: var(--bg);
        color: var(--text);
        overflow: hidden;
      }

      button, select, input, textarea { color: inherit; font: inherit; }

      button, select {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: 0.4rem;
        cursor: pointer;
        min-height: 2rem;
        padding: 0.35rem 0.7rem;
      }

      button:hover:not(:disabled), select:hover {
        border-color: var(--accent);
      }

      button:focus-visible, select:focus-visible, a:focus-visible,
      textarea:focus-visible, input:focus-visible,
      [role="separator"]:focus-visible {
        outline: 2px solid var(--focus);
        outline-offset: 2px;
      }

      a { color: inherit; text-decoration: none; }

      pre { margin: 0; }

      .sr-only {
        clip-path: inset(50%);
        height: 1px;
        overflow: hidden;
        position: absolute;
        white-space: nowrap;
        width: 1px;
      }

      .app-shell {
        display: grid;
        grid-template-rows: auto minmax(0, 1fr);
        height: 100%;
      }

      .app-header {
        align-items: center;
        background: var(--surface);
        border-bottom: 1px solid var(--border);
        display: flex;
        gap: 1rem;
        min-height: 3.25rem;
        padding: 0.6rem 1rem;
      }

      .brand {
        border-radius: 0.3rem;
        font-size: 1.05rem;
        font-weight: 700;
        padding: 0.15rem 0.3rem;
      }

      .brand:hover { background: var(--surface-alt); }

      .beam {
        color: var(--muted);
        display: flex;
        font-family: ui-monospace, monospace;
        font-size: 0.85rem;
        gap: 0.35rem;
        min-width: 0;
        overflow-x: auto;
        white-space: nowrap;
      }

      .beam-path { color: var(--text); }

      .workbench {
        display: grid;
        grid-template-columns:
          minmax(9rem, var(--tree-width)) 0.35rem minmax(0, 1fr);
        min-height: 0;
      }

      .tree-pane {
        background: var(--surface);
        display: grid;
        grid-template-rows: auto minmax(0, 1fr);
        min-height: 0;
        min-width: 0;
      }

      .pane-header {
        align-items: center;
        border-bottom: 1px solid var(--border);
        display: flex;
        gap: 0.5rem;
        justify-content: space-between;
        min-height: 3rem;
        padding: 0.45rem 0.7rem;
      }

      .pane-header h2 {
        font-family: ui-monospace, monospace;
        font-size: 0.9rem;
        margin: 0;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .up {
        align-items: center;
        border: 1px solid var(--border);
        border-radius: 0.4rem;
        display: inline-flex;
        height: 1.9rem;
        justify-content: center;
        width: 1.9rem;
      }

      .up:hover { border-color: var(--accent); }

      .file-tree {
        font-family: ui-monospace, monospace;
        font-size: 0.85rem;
        overflow: auto;
        padding: 0.5rem;
      }

      .tree-link {
        border-radius: 0.25rem;
        display: inline-block;
        max-width: 100%;
        overflow: hidden;
        padding: 0.1rem 0.3rem;
        text-overflow: ellipsis;
        vertical-align: middle;
        white-space: nowrap;
      }

      .tree-link:hover { background: var(--surface-alt); }

      .tree-here {
        background: var(--surface-alt);
        color: var(--accent);
        font-weight: 700;
      }

      .tree-dir-link { color: var(--muted); }

      .tree-desk > summary > .tree-link {
        color: var(--text);
        font-weight: 700;
      }

      .tree-desk > summary { padding: 0.2rem 0 0.2rem 0.2rem; }

      .tree-desk + .tree-desk {
        border-top: 1px solid var(--border);
        margin-top: 0.5rem;
        padding-top: 0.5rem;
      }

      /* the whole row toggles, so the caret is ours rather than the
         browser's: a default marker sits outside the box and is
         nearly impossible to hit */
      .tree-summary {
        align-items: center;
        cursor: pointer;
        display: flex;
        gap: 0.1rem;
        list-style: none;
        min-width: 0;
      }

      .tree-summary::-webkit-details-marker { display: none; }

      .tree-caret {
        align-items: center;
        color: var(--muted);
        display: inline-flex;
        flex: 0 0 auto;
        height: 1.15rem;
        justify-content: center;
        width: 1.15rem;
      }

      .tree-caret::before {
        border-bottom: 0.22rem solid transparent;
        border-left: 0.34rem solid currentcolor;
        border-top: 0.22rem solid transparent;
        content: "";
        transition: transform 0.12s ease;
      }

      .tree-summary:hover .tree-caret { color: var(--text); }

      details[open] > .tree-summary > .tree-caret::before {
        transform: rotate(90deg);
      }

      .tree-summary > .tree-link { flex: 0 1 auto; min-width: 0; }

      .tree-kids {
        border-left: 1px solid var(--border);
        margin-left: 0.5rem;
        padding-left: 0.35rem;
      }

      .splitter {
        background: var(--border);
        cursor: col-resize;
        touch-action: none;
      }

      .splitter:hover, .splitter:focus { background: var(--accent); }

      .workspace {
        display: grid;
        grid-template-rows: auto minmax(0, 1fr) auto;
        min-height: 0;
        min-width: 0;
      }

      .note {
        background: var(--surface);
        border-bottom: 1px solid var(--border);
        border-left: 0.3rem solid var(--warn);
        color: var(--warn);
        padding: 0.6rem 0.9rem;
      }

      .pane {
        background: var(--surface);
        display: grid;
        grid-template-rows: auto minmax(0, 1fr);
        min-height: 0;
        min-width: 0;
      }

      .pane-body {
        display: flex;
        flex-direction: column;
        min-height: 0;
        overflow: auto;
        padding: 0.9rem;
      }

      .pane.editing .pane-body { overflow: hidden; padding: 0; }

      .pane-actions {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.4rem;
      }

      .action {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: 0.4rem;
        font-size: 0.85rem;
        padding: 0.3rem 0.65rem;
      }

      .action:hover { border-color: var(--accent); }

      .upload {
        align-items: center;
        display: flex;
        gap: 0.4rem;
        margin: 0;
      }

      .upload label {
        align-items: center;
        color: var(--muted);
        display: flex;
        font-size: 0.78rem;
        gap: 0.25rem;
      }

      .upload input[type="file"] {
        font-size: 0.78rem;
        max-width: 13rem;
      }

      .view pre {
        font: 0.85rem/1.5 ui-monospace, monospace;
      }

      .fail {
        color: var(--warn);
        font-family: ui-monospace, monospace;
        font-size: 0.85rem;
      }

      .empty {
        color: var(--muted);
        font-size: 0.85rem;
        margin: 0;
      }

      .editor {
        display: flex;
        flex: 1;
        flex-direction: column;
        margin: 0;
        min-height: 0;
      }

      .editor-area {
        background: var(--surface);
        border: 0;
        color: var(--text);
        flex: 1;
        font: 0.9rem/1.55 ui-monospace, monospace;
        min-height: 0;
        outline-offset: -2px;
        padding: 0.9rem;
        resize: none;
        tab-size: 2;
        width: 100%;
      }

      .editor-actions {
        border-top: 1px solid var(--border);
        display: flex;
        gap: 0.5rem;
        padding: 0.5rem 0.7rem;
      }

      .perm { font-size: 0.9rem; }

      .perm h3 {
        font-size: 0.9rem;
        margin: 0 0 0.3rem 0;
      }

      .perm .rule, .perm .sown, .perm .crews {
        border-bottom: 1px solid var(--border);
        margin-bottom: 1.2rem;
        padding-bottom: 1.2rem;
      }

      .perm .gist {
        font-size: 1.05rem;
        margin: 0 0 0.2rem 0;
      }

      .perm .from, .status-bar .from { color: var(--muted); }

      .perm .warn { color: var(--warn); }

      .perm ul.who {
        margin: 0.3rem 0;
        padding-left: 1.4rem;
      }

      .perm form {
        align-items: flex-start;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        margin: 0.6rem 0;
      }

      .perm label {
        color: var(--muted);
        display: grid;
        font-size: 0.78rem;
        gap: 0.2rem;
        max-width: 30rem;
        width: 100%;
      }

      .perm textarea, .perm input, .perm select {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: 0.3rem;
        color: var(--text);
        font: 0.85rem/1.45 ui-monospace, monospace;
        padding: 0.35rem 0.5rem;
        width: 100%;
      }

      .perm table {
        border-collapse: collapse;
        font-size: 0.85rem;
      }

      .perm th, .perm td {
        padding: 0.15rem 1.4rem 0.15rem 0;
        text-align: left;
      }

      .perm th {
        color: var(--muted);
        font-weight: normal;
      }

      .status-bar {
        align-items: center;
        background: var(--surface);
        border-top: 1px solid var(--border);
        color: var(--muted);
        display: flex;
        flex-wrap: wrap;
        font-size: 0.8rem;
        gap: 0.9rem;
        padding: 0.45rem 0.9rem;
      }

      .status-bar a {
        border-radius: 0.25rem;
        padding: 0.1rem 0.3rem;
      }

      .status-bar a:hover {
        background: var(--surface-alt);
        color: var(--text);
      }

      @media (max-width: 760px) {
        .workbench {
          grid-template-columns: minmax(0, 1fr);
          grid-template-rows: minmax(7rem, 26vh) 0.35rem minmax(18rem, 1fr);
        }

        .splitter { cursor: row-resize; }
      }
      '''
    ::
    ::  +script: pane resizing, and keeping the open file in view
    ::
    ++  script
      '''
      (() => {
        'use strict';
        const store = 'heathcliff.tree.width';
        const root = document.documentElement;
        const pane = document.getElementById('tree-pane');
        const bar = document.getElementById('splitter');
        const least = 140;
        const apply = (px) => {
          const wide = Math.min(Math.max(px, least), window.innerWidth - 240);
          root.style.setProperty('--tree-width', wide + 'px');
          try { localStorage.setItem(store, String(wide)); } catch (e) {}
        };
        let kept = NaN;
        try { kept = parseInt(localStorage.getItem(store), 10); } catch (e) {}
        if (kept > 0) apply(kept);
        if (pane && bar) {
          bar.addEventListener('pointerdown', (event) => {
            bar.setPointerCapture(event.pointerId);
            event.preventDefault();
          });
          bar.addEventListener('pointermove', (event) => {
            if (!bar.hasPointerCapture(event.pointerId)) return;
            apply(event.clientX - pane.getBoundingClientRect().left);
          });
          bar.addEventListener('pointerup', (event) => {
            bar.releasePointerCapture(event.pointerId);
          });
          bar.addEventListener('keydown', (event) => {
            const step = event.shiftKey ? 64 : 16;
            const wide = pane.getBoundingClientRect().width;
            if (event.key === 'ArrowLeft') {
              apply(wide - step);
              event.preventDefault();
            }
            if (event.key === 'ArrowRight') {
              apply(wide + step);
              event.preventDefault();
            }
          });
        }
        const opened = 'heathcliff.tree.open';
        const cap = 400;
        const tree = document.getElementById('file-tree');
        if (tree) {
          // remembered state wins over what the page shipped open, so
          // collapsing the desk you are browsing sticks.  desks also record
          // the state they arrived in, so a desk opened by navigating into
          // it stays open when you navigate somewhere else.  directories
          // are only remembered once toggled, to keep this small
          let saved = null;
          try { saved = JSON.parse(localStorage.getItem(opened)); } catch (e) {}
          if (!saved || typeof saved !== 'object' || Array.isArray(saved)) {
            saved = {};
          }
          const keep = () => {
            const keys = Object.keys(saved);
            keys.slice(0, Math.max(0, keys.length - cap))
                .forEach((key) => { delete saved[key]; });
            try { localStorage.setItem(opened, JSON.stringify(saved)); }
            catch (e) {}
          };
          tree.querySelectorAll('details[data-node]').forEach((node) => {
            const key = node.dataset.node;
            if (key in saved) node.open = saved[key];
            else if (node.classList.contains('tree-desk')) {
              saved[key] = node.open;
            }
          });
          // landing on a branch itself is a request to see inside it, which
          // outranks having collapsed it earlier
          const landed = tree.querySelector('summary > .tree-here');
          const branch = landed && landed.closest('details[data-node]');
          if (branch) {
            branch.open = true;
            saved[branch.dataset.node] = true;
          }
          keep();
          // toggle does not bubble, so listen on the way down
          tree.addEventListener('toggle', (event) => {
            const key = event.target.dataset && event.target.dataset.node;
            if (!key) return;
            delete saved[key];
            saved[key] = event.target.open;
            keep();
          }, true);
        }
        const here = document.querySelector('.tree-here');
        if (here) here.scrollIntoView({ block: 'center' });
      })();
      '''
    ::
    ++  full
      ^-  manx
      ;html
        ;head
          ;title:"%heathcliff: {spot}"
          ;meta(charset "utf-8");
          ;meta(name "viewport", content "width=device-width, initial-scale=1");
          ;style:"{(trip style)}"
        ==
        ;body
          ;div.app-shell
            ;+  site
            ;main.workbench
              ;+  navi
              ;div#splitter.splitter
                =role  "separator"
                =tabindex  "0"
                =aria-orientation  "vertical"
                =aria-label  "resize the file tree"
                ;span.sr-only:"resize the file tree"
              ==
              ;section.workspace
                ;+  ?~  msg  :/""
                    ;div.note:"{(trip u.msg)}"
                ;+  body
                ;+  meta
              ==
            ==
          ==
          ;script:"{(trip script)}"
        ==
      ==
    ::
    ::  +site: the app header, with the beam we are looking at
    ::
    ++  site
      ^-  manx
      ;header.app-header
        ;a.brand(href "{sput(mode step, s.beam ~)}"):"heathcliff"
        ;div.beam
          ;span:"{(scow %p p.beam)}"
          ;span:"/"
          ;span:"\%{(trip q.beam)}"
          ;span:"/"
          ;span:"{?:(=(da+now r.beam) "now" (scow r.beam))}"
          ;span.beam-path:"{?~(s.beam "/" (spud s.beam))}"
        ==
      ==
    ::
    ::  +navi: the file tree pane, with the desk it is showing
    ::
    ++  navi
      ^-  manx
      ;aside#tree-pane.tree-pane(aria-label "clay navigation")
        ;div.pane-header
          ;h2:"{(scow %p p.beam)}"
          ;+  ?:  =(~ s.beam)  :/""
              ;a.up
                =href  "{sput(mode step, s.beam (snip s.beam))}"
                =title  "navigate up"
                ; ↖
              ==
        ==
        ;div#file-tree.file-tree(role "tree", aria-label "clay contents")
          ::NOTE  pinned to now: clay's empty-desk fast path only applies at
          ::      [%da now], and off it this scry crashes the whole event.
          ::      the desk list is a property of the ship, not of the revision
          ::      being browsed, so now is also the correct case.
          ;*  %+  turn
                =/  bem  rend(q.beam %$, r.beam da+now, s.beam ~)
                (sort ~(tap in .^((set desk) %cd bem)) aor)
              dnod
        ==
      ==
    ::
    ::  +dnod: one desk, as the root of its own tree
    ::
    ::    only the desk being browsed carries the case we're browsing at.  a
    ::    revision number means nothing on another desk, so the rest are read
    ::    and linked at now.
    ::
    ++  dnod
      |=  dek=desk
      ^-  manx
      =/  cur=?  =(dek q.beam)
      =/  sub=(list path)
        ?:  cur  hive
        .^((list path) %ct rend(q.beam dek, r.beam da+now, s.beam ~))
      =/  key=tape  (trip dek)
      =/  det=manx
        ;details.tree-desk(data-node key)
          ;summary.tree-summary
            ;span.tree-caret(aria-hidden "true");
            ;+  (item dek cur ~ "%{(trip dek)}" &)
          ==
          ;div.tree-kids
            ;*  (limb dek cur ~ sub)
          ==
        ==
      ::  the desk on screen is open on arrival; the browser remembers the
      ::  rest, so several desks can be open at once
      ::
      =?  a.g.det  cur  [[%open ""] a.g.det]
      det
    ::
    ::  +limb: one level of a desk's tree, as tree items
    ::
    ::    a node whose only child is a leaf is a file with its mark hanging
    ::    off it, so the two render as one entry.
    ::
    ++  limb
      |=  [dek=desk cur=? pre=path sub=(list path)]
      ^-  marl
      =/  kid=(jar @ta path)
        %+  roll  sub
        |=  [p=path j=(jar @ta path)]
        ?~  p  j
        (~(add ja j) i.p t.p)
      %+  turn  (sort ~(tap in ~(key by kid)) aor)
      |=  nom=@ta
      ^-  manx
      =/  pax=path          (snoc pre nom)
      =/  kits=(list path)  (~(get ja kid) nom)
      ?:  ?=([~ ~] kits)
        (item dek cur pax (trip nom) |)
      ?:  ?=([[@ ~] ~] kits)
        (item dek cur (snoc pax i.i.kits) "{(trip nom)}/{(trip i.i.kits)}" |)
      =/  key=tape  "{(trip dek)}{(spud pax)}"
      =/  det=manx
        ;details.tree-dir(data-node key)
          ;summary.tree-summary
            ;span.tree-caret(aria-hidden "true");
            ;+  (item dek cur pax (trip nom) &)
          ==
          ;div.tree-kids
            ;*  (limb dek cur pax kits)
          ==
        ==
      ::  open the branches that lead to the node on screen
      ::
      =?  a.g.det  &(cur =(pax (scag (lent pax) s.beam)))
        [[%open ""] a.g.det]
      det
    ::
    ::  +item: one tree entry, marked when it is the node on screen
    ::
    ++  item
      |=  [dek=desk cur=? pax=path nam=tape dir=?]
      ^-  manx
      =/  cls=tape
        ;:  weld
          "tree-link "
          ?:(dir "tree-dir-link" "tree-file-link")
          ?:(&(cur =(pax s.beam)) " tree-here" "")
        ==
      =/  loc=tape
        ?:  cur  sput(mode step, s.beam pax)
        sput(mode step, q.beam dek, r.beam da+now, s.beam pax)
      ;a(class cls, role "treeitem", href loc):"{nam}"
    ::
    ::  +pane: the workspace pane, titled with the path it is showing
    ::
    ++  pane
      |=  [cls=tape con=marl]
      ^-  manx
      ;section(class cls)
        ;div.pane-header
          ;h2:"{?~(s.beam "/" (spud s.beam))}"
          ;+  acts
        ==
        ;div.pane-body
          ;*  con
        ==
      ==
    ::
    ::  +acts: what can be done with the node on screen
    ::
    ++  acts
      ^-  manx
      ;div.pane-actions
        ;+  ?.  have  :/""
            ;a.action
              =id  "download"
              =href  "{sput(mode %down)}"
              =download  "{(join '.' (flop (scag 2 (flop s.beam))))}"
              =title  "download this file"
              ; download
            ==
        ;+  ?:  edit
              ;a.action
                =id  "view"
                =href  "{sput(mode %view)}"
                =title  "view this file"
                ; view
              ==
            ::  only the head of the desk is editable
            ?.  =(da+now r.beam)  :/""
            ;a.action
              =id  "edit"
              =href  "{sput(mode %edit)}"
              =title  "edit this file"
              ; edit
            ==
        ::  upload, into directories at the head of the desk only
        ;+  ?.  &(!fils =(da+now r.beam))  :/""
            ;form.upload(method "post", enctype "multipart/form-data")
              =action  sput(mode %load)
              ;input(type "file", name "file", required "");
              ;label
                =title
                  "heathcliff carries the mark sources, and can commit ".
                  "the ones this desk lacks"
                ;input(type "checkbox", name "marks", value "1");
                ; install missing marks
              ==
              ;button(type "submit", title "upload into this directory")
                ; upload
              ==
            ==
      ==
    ::
    ::TODO  display appropriate message if case is in the future
    ::  +folk: who a rule names, ships then crews with their membership
    ::
    ++  folk
      |=  rul=real:clay
      ^-  manx
      ?:  &(=(~ p.who.rul) =(~ q.who.rul))  :/""
      =/  cru=(list [nom=@ta mem=(set ship)])
        %+  sort  ~(tap by q.who.rul)
        |=  [a=[nom=@ta mem=(set ship)] b=[nom=@ta mem=(set ship)]]
        (aor nom.a nom.b)
      ;ul.who
        ;+  ?:  =(~ p.who.rul)  :/""
            ;li:"{(ships p.who.rul)}"
        ;*  %+  turn  cru
            |=  [nom=@ta mem=(set ship)]
            ^-  manx
            ;li
              ; \%{(trip nom)}
              ;+  ?:  =(~ mem)  :/" - empty, so it admits no one"
                  ;span.crew:" - {(ships mem)}"
            ==
      ==
    ::
    ::  +rite: one rule, with where it came from
    ::
    ++  rite
      |=  [wat=tape =dict:clay]
      ^-  manx
      ;div.rule
        ;h3:"{wat}"
        ;p.gist:"{(gist rul.dict)}"
        ;p.from
          ;+  ?:  (owns s.beam dict)
                :/"set on this node"
              ?:  &(?=(~ src.dict) =(rul.dict dull))
                :/"clay's default - no rule is set anywhere on this desk"
              :/"inherited from {?:(=(~ src.dict) "/" (spud src.dict))}"
        ==
        ;+  (folk rul.dict)
      ==
    ::
    ::  +sets: the editor for one side of the rule pair
    ::
    ++  sets
      |=  [wat=tape red=? =dict:clay]
      ^-  manx
      ?.  =(da+now r.beam)  :/""
      =/  kin=tape  ?:(red "r" "w")
      =/  shp=tape  (ships p.who.rul.dict)
      =/  cru=tape  (tally `(list @t)`~(tap in ~(key by q.who.rul.dict)))
      =/  wit=?     =(%white mod.rul.dict)
      ;form.rules(method "post")
        ;input(type "hidden", name "kind", value kin);
        ;label
          ; mode
          ;select(name "mode")
            ;+  ?:  wit
                  ;option(value "white", selected ""):"whitelist - only these"
                ;option(value "white"):"whitelist - only these"
            ;+  ?:  wit
                  ;option(value "black"):"blacklist - all but these"
                ;option(value "black", selected ""):"blacklist - all but these"
          ==
        ==
        ;label
          ; ships
          ;textarea(name "ships", rows "2", placeholder "~zod ~nec")
            ; {shp}
          ==
        ==
        ;label
          ; crews
          ;textarea(name "crews", rows "2", placeholder "friends")
            ; {cru}
          ==
        ==
        ;div.pane-actions
          ;button(type "submit", name "save"):"set {wat} here"
          ;button(type "submit", name "clear"):"clear - inherit from parent"
        ==
      ==
    ::
    ::  +crews: the crew list and its editor.  crews are per-ship, not per
    ::          desk, so this is the same content wherever you are
    ::
    ++  crews
      ^-  manx
      ;div.crews
        ;h3:"crews"
        ;+  ?:  =(~ cez.sat)
              ;p.from:"none yet"
            ;table
              ;tr
                ;th:"name"
                ;th:"members"
                ;th:"referenced"
                ;th:""
              ==
              ;*  %+  turn  `(list @ta)`(sort ~(tap in ~(key by cez.sat)) aor)
                  |=  nom=@ta
                  ^-  manx
                  =/  mem=(set ship)  (~(gut by cez.sat) nom *crew:clay)
                  =/  nam=tape        (trip nom)
                  ;tr
                    ;td:"\%{(trip nom)}"
                    ;td:"{?:(=(~ mem) "empty - admits no one" (ships mem))}"
                    ;td:"{(cited nom)}"
                    ;td
                      ;+  ?.  =(da+now r.beam)  :/""
                          ;form(method "post")
                            ;input(type "hidden", name "name", value nam);
                            ;button(type "submit", name "crew-kill"):"delete"
                          ==
                    ==
                  ==
            ==
        ;+  ?.  =(da+now r.beam)  :/""
            ;form.crew-new(method "post")
              ;label
                ; name
                ;input(name "name", placeholder "friends");
              ==
              ;label
                ; members
                ;textarea(name "members", rows "2", placeholder "~zod ~nec");
              ==
              ;button(type "submit", name "crew-save"):"save crew"
            ==
        ;p.from
          ; deleting a crew strips it from every rule that names it.  that
          ; tightens a whitelist, but it loosens a blacklist - the ships it
          ; was excluding are no longer excluded.
        ==
        ;form(method "post")
          ;button(type "submit", name "reload"):"reload crews from clay"
        ==
      ==
    ::
    ::  +hold: the permissions view
    ::
    ++  hold
      ^-  manx
      =/  d  pear
      =/  s  sown
      ;div.perm
        ;+  (rite "read" red.d)
        ;+  (sets "read" & red.d)
        ;+  (rite "write" wit.d)
        ;+  (sets "write" | wit.d)
        ;p.warn
          ; clay stores write rules and inherits them, but never consults
          ; them: +may-write has no callers at all as of 408K.  the write
          ; rule is a record, not a control.  call your local core dev
          ; before relying on it for anything.
        ==
        ;div.sown
          ;h3:"explicit rules here and below"
          ;+  ?~  out.s
                ;p.from:"none - everything here inherits"
              ;table
                ;tr
                  ;th:"path"
                  ;th:"read"
                  ;th:"write"
                ==
                ;*  %+  turn  out.s
                    |=  [p=path red=(unit real:clay) wit=(unit real:clay)]
                    ;tr
                      ;td
                        ;a/"{sput(s.beam p)}"
                          ; {?:(=(~ p) "/" (spud p))}
                        ==
                      ==
                      ;td:"{?~(red "-" (gist u.red))}"
                      ;td:"{?~(wit "-" (gist u.wit))}"
                    ==
              ==
          ;+  ?.  more.s  :/""
              ;p.warn
                ; more than {(scow %ud walk)} paths sit under this node; only
                ; the first {(scow %ud walk)} were checked, so there may be
                ; rules below that aren't listed.  navigate downwards to see
                ; them.
              ==
        ==
        ;+  crews
        ;p.from
          ; permissions are not versioned - clay keeps only the current rules,
          ; so these are as of now even when browsing an older revision.
        ==
      ==
    ::
    ++  body
      ^-  manx
      =/  bod=(unit mime)  show
      ?:  =(%perm mode)  (pane "pane" ~[hold])
      ?:  edit
        %+  pane  "pane editing"
        :_  ~
        ;form.editor(method "post")
          ;textarea.editor-area(name "file", spellcheck "false")
            ;+  :/(trip q.q:(fall bod *mime))
          ==
          ;div.editor-actions
            ;button(type "submit", name "save"):"save"
            ;button(type "submit", name "cancel"):"cancel"
            ;button(type "submit", name "delete"):"delete"
          ==
        ==
      %+  pane  "pane"
      :_  ~
      ?:  gone
        ;div.fail
          ; this file's data has been tombstoned
        ==
      ?.  have
        ::  navigation lives in the tree, so a node with no data of its own
        ::  has nothing to show here
        ::
        ?:  ?=(^ [dir:arch])
          ;p.empty
            ; a directory - pick a file in the tree
          ==
        ;div.fail
          ; no data at this path
        ==
      ?~  bod
        ;div.fail
          ; this file could not be displayed
        ==
      ;div.view
        ;pre:"{(trip q.q.u.bod)}"
      ==
    ::
    ++  meta
      ^-  manx
      =/  bod=(unit mime)  show
      ::TODO  need to find a nice way to do conditional inline text
      ;footer.status-bar
        ;span(title "case")
          ; rev {(scow %ud ud:cass)} @
          ; {(scow %da =+(da:cass (sub - (mod - ~s1))))}
        ==
        ;+  ?^  bod
              ;span(title "size")
                ; {(scow %ud p.q.u.bod)} bytes
              ==
            ?:  gone
              ;span(title "state")
                ; tombstoned
              ==
            ?:  fils
              ;span(title "state")
                ; unreadable
              ==
            ;span(title "tree")
              ; {(scow %ud ~(wyt by dir:arch))} items
            ==
        ;a/"{sput(mode %perm)}"
          =title  "read permissions in force here, as of now"
          ; read: {(gist rul.red:pear)}
        ==
      ==
    --
  --
--
