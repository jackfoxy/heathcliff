::  heathcliff-api: the JSON route behind the explorer and the dialogs
::
::    One authenticated POST with an `op`, answered in urui's envelope:
::    `{ok: true, ...}`, or `{ok: false, error: {code, message, ...}}`.
::
/+  hc=heathcliff-clay, hp=heathcliff-perm, ht=heathcliff-transfer
/+  ufiles=urui-files
|%
::  +|  Requests
::
++  handle
  ::  The cards answering one request.
  |=  $:  =bowl:gall
          eyre-id=@ta
          req=inbound-request:eyre
          cez=crews:hp
          use=usage:hp
      ==
  ^-  (list card:agent:gall)
  =/  no
    |=  =failure:ufiles
    ^-  (list card:agent:gall)
    (refuse:ufiles eyre-id failure)
  =/  bad=failure:ufiles  (fail:ufiles %bad-request 400 'malformed request')
  =/  raw=request:http  request.req
  ?.  =(%'POST' method.raw)
    (no (fail:ufiles %bad-request 405 'method not allowed'))
  ?.  (json-type:ufiles header-list.raw)
    (no (fail:ufiles %unsupported-media 415 'expected application/json'))
  ?~  body.raw  (no bad)
  =/  jon=(unit json)  (de:json:html q.u.body.raw)
  ?.  ?=([~ %o *] jon)  (no bad)
  =/  got=(each (each [cards=(list card:agent:gall) =json] failure:ufiles) tang)
    (mule |.((dispatch bowl p.u.jon cez use)))
  ?:  ?=(%| -.got)
    (no (fail-with:ufiles %internal 500 'request failed' p.got))
  ?:  ?=(%| -.p.got)  (no p.p.got)
  (weld cards.p.p.got (reply:ufiles eyre-id json.p.p.got))
::
++  dispatch
  ::  One op: its cards and answer, or why it is refused.
  ::
  ::    Clay processes the cards before eyre sees the answer, so a client
  ::    reading again after `ok` sees a rule change; crews arrive with a
  ::    later gift.
  |=  [=bowl:gall fields=(map @t json) cez=crews:hp use=usage:hp]
  ^-  (each [cards=(list card:agent:gall) =json] failure:ufiles)
  =/  bad=failure:ufiles
    (fail:ufiles %bad-request 400 'missing or ill-typed field')
  =/  answer
    |=  jon=json
    ^-  (each [cards=(list card:agent:gall) =json] failure:ufiles)
    [%& ~ jon]
  =/  op=(unit @t)  (text-field:ufiles fields 'op')
  ?+  op  [%| (fail:ufiles %bad-request 400 'unknown op')]
      [~ %roots]
    %-  answer
    %-  ok-json:ufiles
    :~  :-  'roots'
        :-  %a
        %+  turn  (roots:hc bowl)
        |=  =root:hc
        %-  pairs:enjs:format
        :~  ['desk' s+desk.root]
            ['title' s+title.root]
            ['rev' (numb:enjs:format rev.root)]
        ==
    ==
  ::
      [~ %tree]
    =/  desk=(unit @t)  (text-field:ufiles fields 'desk')
    =/  seg=(unit @t)  (text-field:ufiles fields 'case')
    =/  scope=(unit path)  (path-field fields 'scope')
    ?:  |(?=(~ desk) ?=(~ seg) ?=(~ scope))  [%| bad]
    =/  where=(each [=beak head=@ud] failure:ufiles)
      (find-beak bowl u.desk u.seg)
    ?:  ?=(%| -.where)  [%| p.where]
    =/  found=(each (list path) tang)  (listing:hc beak.p.where u.scope)
    =/  paths=(list path)  ?:(?=(%| -.found) ~ p.found)
    ::  files whose data at this revision is gone
    =/  tombs=(list path)
      %+  skip  paths
      |=(p=path (live:hc bowl (en-beam beak.p.where p)))
    =/  to-json
      |=  p=path
      ^-  json
      a+(turn p |=(s=@ta s+s))
    %-  answer
    %-  ok-json:ufiles
    :~  ['rev' (numb:enjs:format head.p.where)]
        ['case' s+(case-seg:hc bowl r.beak.p.where)]
        ['paths' a+(turn paths to-json)]
        ['tombs' a+(turn tombs to-json)]
    ==
  ::
      [~ %attributes]
    =/  wire=(unit path)  (path-field fields 'path')
    ?~  wire  [%| bad]
    =/  made=(each json failure:ufiles)  (attributes bowl u.wire cez use)
    ?:  ?=(%| -.made)  [%| p.made]
    (answer p.made)
  ::
      [~ %rule]
    =/  wire=(unit path)  (path-field fields 'path')
    =/  side=(unit @t)  (text-field:ufiles fields 'side')
    ?:  |(?=(~ wire) ?=(~ side))  [%| bad]
    ?.  ?=([@ %now *] u.wire)
      [%| (fail:ufiles %read-only 403 'rules change only at now')]
    ?.  (~(has in (desks:hc bowl)) i.u.wire)
      [%| (fail:ufiles %not-found 404 'no such desk')]
    =/  clear=?  =([~ %b %.y] (~(get by fields) 'clear'))
    =/  text
      |=  key=@t
      ^-  @t
      (fall (text-field:ufiles fields key) '')
    =/  sent=(each card:agent:gall @t)
      %:  set-rule:hp
        cez  i.u.wire  t.t.u.wire  =('read' u.side)  clear
        (text 'mode')  (text 'ships')  (text 'crews')
      ==
    ?:  ?=(%| -.sent)  [%| (fail:ufiles %unprocessable 422 p.sent)]
    [%& ~[p.sent] (ok-json:ufiles ~)]
  ::
      [~ %crew-save]
    =/  name=@t  (fall (text-field:ufiles fields 'name') '')
    =/  members=@t  (fall (text-field:ufiles fields 'members') '')
    =/  sent=(each (list card:agent:gall) @t)  (crew-save:hp name members)
    ?:  ?=(%| -.sent)  [%| (fail:ufiles %unprocessable 422 p.sent)]
    [%& p.sent (ok-json:ufiles ~)]
  ::
      [~ %crew-kill]
    =/  name=@t  (fall (text-field:ufiles fields 'name') '')
    =/  sent=(each (list card:agent:gall) @t)  (crew-kill:hp cez name)
    ?:  ?=(%| -.sent)  [%| (fail:ufiles %unprocessable 422 p.sent)]
    [%& p.sent (ok-json:ufiles ~)]
  ::
      [~ %reload]
    [%& mirror:hp (ok-json:ufiles ~)]
  ::
      [~ %upload-check]
    =/  wire=(unit path)  (path-field fields 'path')
    =/  filename=(unit @t)  (text-field:ufiles fields 'filename')
    =/  size=(unit @ud)  (number-field fields 'size')
    =/  nul=(unit @ud)  (number-field fields 'nul')
    ?:  |(?=(~ wire) ?=(~ filename) ?=(~ size) ?=(~ nul))  [%| bad]
    ?.  ?=([@ %now *] u.wire)
      [%| (fail:ufiles %read-only 403 'uploads go into the current revision')]
    =/  checked=(each plan:ht @t)
      (check:ht bowl i.u.wire t.t.u.wire u.filename u.size u.nul)
    ?:  ?=(%| -.checked)  [%| (fail:ufiles %bad-request 400 p.checked)]
    =/  =plan:ht  p.checked
    %-  answer
    %-  ok-json:ufiles
    :~  ['clay' s+(spat tar.plan)]
        ['mark' s+mark.plan]
        ['exists' b+exists.plan]
        :-  'install'
        :-  %a
        %+  turn  install.plan
        |=  [m=@tas from=@tas]
        (pairs:enjs:format ~[['mark' s+m] ['from' s+from]])
        ['problems' a+(turn problems.plan |=(t=@t s+t))]
    ==
  ==
::
::  +|  Fields
::
++  path-field
  ::  A json array of knots.
  |=  [fields=(map @t json) key=@t]
  ^-  (unit path)
  =/  value=(unit json)  (~(get by fields) key)
  ?.  ?=([~ %a *] value)  ~
  =/  parts=(list @ta)
    %+  murn  p.u.value
    |=  item=json
    ^-  (unit @ta)
    ?.  ?=([%s *] item)  ~
    ?.  (valid-segment:ufiles | p.item)  ~
    `(@ta p.item)
  ?.  =((lent parts) (lent p.u.value))  ~
  `parts
::
++  number-field
  |=  [fields=(map @t json) key=@t]
  ^-  (unit @ud)
  =/  value=(unit json)  (~(get by fields) key)
  ?.  ?=([~ %n *] value)  ~
  (rush p.u.value dem)
::
::  +|  Answers
::
++  find-beak
  ::  The beak a desk name and case segment name, with the desk's head.
  |=  [=bowl:gall desk=@t seg=@t]
  ^-  (each [=beak head=@ud] failure:ufiles)
  ?.  ((sane %tas) desk)  [%| (fail:ufiles %invalid-path 400 'bad desk name')]
  ?.  (~(has in (desks:hc bowl)) desk)
    [%| (fail:ufiles %not-found 404 'no such desk')]
  =/  head=@ud  (head-rev:hc bowl desk)
  =/  cas=(unit case)  (read-case:hc bowl seg head)
  ?~  cas  [%| (fail:ufiles %not-found 404 'no such revision of that desk')]
  [%& [our.bowl desk u.cas] head]
::
++  attributes
  ::  What the attributes dialog shows of the item at a wire path.
  ::
  ::    Permissions are always current; `current` says whether the item
  ::    is too, which is when they may be changed from here.
  |=  [=bowl:gall wire=path cez=crews:hp use=usage:hp]
  ^-  (each json failure:ufiles)
  ?.  ?=([@ @ *] wire)
    [%| (fail:ufiles %invalid-path 400 'a path names its desk and case')]
  =/  where=(each [=beak head=@ud] failure:ufiles)
    (find-beak bowl i.wire i.t.wire)
  ?:  ?=(%| -.where)  [%| p.where]
  =/  =beak  beak.p.where
  =/  pax=path  t.t.wire
  =/  full=path  (en-beam beak pax)
  =/  =arch  .^(arch %cy full)
  =/  title=@t  (title:hc bowl q.beak)
  =/  file=?  ?=(^ fil.arch)
  =/  kind=@t
    ?:  =(~ pax)  'desk'
    ?:  file  'file'
    ?:  =(~ dir.arch)  'missing'
    'directory'
  =/  mark=(unit @tas)  ?:(file `(rear pax) ~)
  =/  label=@t
    ?:  =(~ pax)  title
    ?:  &(file (gte (lent pax) 2))
      (rap 3 (snag (sub (lent pax) 2) pax) '.' (rear pax) ~)
    (rear pax)
  =/  date=@da  da:.^(cass:clay %cw (en-beam beak ~))
  =/  file-json=json
    ?.  file  ~
    =/  gone=?  !(live:hc bowl full)
    =/  size=(unit @ud)  ?:(gone ~ (size-of .^(* %cq full)))
    =/  type=(unit mite)  (ctype:hc (rear pax))
    %-  pairs:enjs:format
    :~  ['size' ?~(size ~ (numb:enjs:format u.size))]
        ['type' s+?~(type 'unknown' (en-mite:mimes:html u.type))]
        ['tombstoned' b+gone]
    ==
  :-  %&
  %-  ok-json:ufiles
  :~  :-  'target'
      %-  pairs:enjs:format
      :~  ['path' a+(turn wire |=(s=@ta s+s))]
          ['label' s+label]
          ['ship' s+(scot %p p.beak)]
          ['desk' s+q.beak]
          ['title' s+title]
          ['case' s+(case-seg:hc bowl r.beak)]
          ['clay' s+(spat pax)]
          ['kind' s+kind]
          ['mark' ?~(mark ~ s+u.mark)]
      ==
      ['current' b+=(da+now.bowl r.beak)]
      ['head' (numb:enjs:format head.p.where)]
      ['date' s+(scot %da (sub date (mod date ~s1)))]
      ['file' file-json]
      ['items' ?:(file ~ (numb:enjs:format ~(wyt by dir.arch)))]
      ['permissions' (perm-json:hp bowl q.beak pax cez use)]
  ==
::
++  size-of
  ::  A stored noun's byte length, where its shape says.
  |=  dat=*
  ^-  (unit @ud)
  ?@  dat  `(met 3 dat)
  =/  as-mime=(unit mime)  ((soft mime) dat)
  ?^  as-mime  `p.q.u.as-mime
  =/  as-octs=(unit octs)  ((soft octs) dat)
  ?^  as-octs  `p.u.as-octs
  =/  as-wain=(unit wain)  ((soft wain) dat)
  ?^  as-wain  `(met 3 (of-wain:format u.as-wain))
  ~
--
