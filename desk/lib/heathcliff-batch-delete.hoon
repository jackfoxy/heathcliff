::  One current-revision delete commit for a frozen list of file paths.
::  Preflight failures are reported individually; Clay gets one soba.
::
/+  hc=heathcliff-clay, ufiles=urui-files
|%
::  +|  Types
::
+$  pending
  ::  The accepted selection and skipped paths awaiting one Clay commit.
  $:  eyre-id=@ta
      id=@ta
      =desk
      before=@ud
      paths=(list path)
      skipped=(list [path message=@t])
      until=@da
  ==
::
+$  outcome
  ::  Effects to emit and the transient batch state to retain.
  [cards=(list card:agent:gall) next=(unit pending)]
::
::  +|  Constants
::
++  max-files
  ::  Bound the synchronous preflight and the size of a single commit.
  10.000
::
::  +|  Requests
::
++  handle
  ::  Validate one HTTP request and start a batch, or return its refusal.
  |=  [=bowl:gall eyre-id=@ta req=inbound-request:eyre busy=?]
  ^-  outcome
  =/  no
    |=(err=failure:ufiles ^-(outcome [(refuse:ufiles eyre-id err) ~]))
  ?:  busy  (no busy:ufiles)
  =/  raw=request:http  request.req
  ?.  =(%'POST' method.raw)
    (no (fail:ufiles %bad-request 405 'method not allowed'))
  ?.  (json-type:ufiles header-list.raw)
    (no (fail:ufiles %unsupported-media 415 'expected application/json'))
  =/  bad=failure:ufiles  (fail:ufiles %invalid-path 400 'invalid delete batch')
  ?~  body.raw  (no bad)
  ?:  (gth p.u.body.raw default-max-bytes:ufiles)
    (no (fail:ufiles %payload-too-large 413 'request body is too large'))
  =/  jon=(unit json)  (de:json:html q.u.body.raw)
  ?.  ?=([~ %o *] jon)  (no bad)
  =/  got=(each (each outcome failure:ufiles) tang)
    (mule |.((plan bowl eyre-id p.u.jon)))
  ?:  ?=(%| -.got)
    (no (fail-with:ufiles %internal 500 'delete preflight failed' p.got))
  ?:  ?=(%| -.p.got)  (no p.p.got)
  p.p.got
::
++  plan
  ::  Validate every selected path before collecting one delete soba.
  ::  Missing or unreadable files are reported without deleting them.
  |=  [=bowl:gall eyre-id=@ta fields=(map @t json)]
  ^-  (each outcome failure:ufiles)
  =/  bad=failure:ufiles  (fail:ufiles %invalid-path 400 'invalid delete batch')
  =/  scope=(unit path)  (path-field fields 'path')
  ?.  ?=([~ @ %now *] scope)  [%| bad]
  =/  value=(unit json)  (~(get by fields) 'paths')
  ?.  ?=([~ %a *] value)  [%| bad]
  ?:  (gth (lent p.u.value) max-files)  [%| bad]
  ::  Validate the entire selection before reading or emitting changes.
  =/  paths=(list path)
    %+  murn  p.u.value
    |=  item=json
    ^-  (unit path)
    =/  pax=(unit path)  (path-field (my ~[['path' item]]) 'path')
    ?~  pax  ~
    ?.  ?&  (gte (lent u.pax) (add 2 (lent u.scope)))
            =(u.scope (scag (lent u.scope) u.pax))
        ==
      ~
    `u.pax
  ?.  =((lent paths) (lent p.u.value))  [%| bad]
  =/  where=(each location:ufiles failure:ufiles)  (locate:hc bowl u.scope)
  ?:  ?=(%| -.where)  [%| p.where]
  =/  desk  i.u.scope
  =/  before=@ud  (head-rev:hc bowl desk)
  =/  selected=(set path)  (silt paths)
  =/  paths  ~(tap in selected)
  =/  kept=(list path)  ~
  =/  skipped=(list [path message=@t])  ~
  |-
  ?~  paths
    =/  id=@ta  (scot %da now.bowl)
    =/  until=@da  (add now.bowl default-timeout:ufiles)
    =/  job=pending  [eyre-id id desk before kept skipped until]
    ?:  =(~ kept)  [%& (answer job before) ~]
    =/  first=path  (slag 2 (snag 0 kept))
    =/  changes=soba:clay
      (turn kept |=(pax=path [(slag 2 pax) %del ~]))
    :-  %&
    :_  `job
    :~  :*  %pass  /batch-delete/[id]/verify  %arvo  %c  %warp
            our.bowl  desk  ~  %next  %x  da+now.bowl  first
        ==
        [%pass /batch-delete/[id]/write %arvo %c %info desk %& changes]
        [%pass /batch-delete/[id]/timeout %arvo %b %wait until]
    ==
  =/  pax=path  i.paths
  =/  full=path  (en-beam beak.p.where (slag 2 pax))
  =/  found=(each arch tang)  (mule |.(.^(arch %cy full)))
  ?:  ?=(%| -.found)
    $(paths t.paths, skipped [[pax 'file could not be checked'] skipped])
  ?~  fil.p.found
    $(paths t.paths, skipped [[pax 'file no longer exists'] skipped])
  $(paths t.paths, kept [pax kept])
::
++  answer
  ::  Report confirmed deletions, preflight skips, and the desk revision.
  |=  [job=pending revision=@ud]
  ^-  (list card:agent:gall)
  %+  reply:ufiles  eyre-id.job
  %-  ok-json:ufiles
  :~  ['revision' (numb:enjs:format revision)]
      ['deleted' a+(turn paths.job path-json)]
      :-  'skipped'
      :-  %a
      %+  turn  skipped.job
      |=  [pax=path message=@t]
      %-  pairs:enjs:format
      ~[['path' (path-json pax)] ['message' s+message]]
  ==
::
++  path-json
  ::  Encode a wire path as the browser's array of segments.
  |=(pax=path ^-(json [%a (turn pax |=(seg=@ta s+seg))]))
::
++  path-field
  ::  Read a path field, rejecting malformed or unsafe segments.
  |=  [fields=(map @t json) key=@t]
  ^-  (unit path)
  =/  policy=policy:ufiles  *policy:ufiles
  =/  parsed  (path-field:ufiles policy(strict |) fields key)
  ?~  parsed  ~
  u.parsed
::
++  take
  ::  Verify the whole deletion after Clay responds; ignore stale signs.
  ::  Timeouts and failed verification must not claim any file succeeded.
  |=  [=bowl:gall =wire =sign-arvo current=(unit pending)]
  ^-  (unit outcome)
  ?.  ?=([%batch-delete @ @ ~] wire)  ~
  =/  job=(unit pending)  current
  ?~  job  `[~ current]
  ?.  =(i.t.wire id.u.job)  `[~ current]
  =/  id=@ta  id.u.job
  =/  cancel=(list card:agent:gall)
    :~  :*  %pass  /batch-delete/[id]/verify  %arvo  %c  %warp
            our.bowl  desk.u.job  ~
        ==
        [%pass /batch-delete/[id]/timeout %arvo %b %rest until.u.job]
    ==
  =/  no
    |=  err=failure:ufiles
    ^-  (unit outcome)
    `[(weld cancel (refuse:ufiles eyre-id.u.job err)) ~]
  ?:  =(%timeout i.t.t.wire)
    ?.  ?=([%behn %wake *] sign-arvo)  `[~ current]
    %-  no
    (fail:ufiles %timeout 504 'delete unconfirmed; refresh before retrying')
  ?:  =(%write i.t.t.wire)
    ?.  ?=([%clay %done *] sign-arvo)  `[~ current]
    ?~  error.sign-arvo  `[~ current]
    (no (fail:ufiles %internal 500 'Clay rejected the delete batch'))
  ?.  =(%verify i.t.t.wire)  `[~ current]
  ?.  ?=([%clay %writ *] sign-arvo)  `[~ current]
  =/  checked=(each @ud tang)
    %-  mule  |.
    =/  revision=@ud  (head-rev:hc bowl desk.u.job)
    ?>  (gth revision before.u.job)
    ?>  %+  levy  paths.u.job
        |=  pax=path
        =/  full=path
          (en-beam [our.bowl desk.u.job da+now.bowl] (slag 2 pax))
        =(~ fil:.^(arch %cy full))
    revision
  ?:  ?=(%| -.checked)
    %-  no
    (fail:ufiles %internal 500 'delete unconfirmed; refresh before retrying')
  `[(weld cancel (answer u.job p.checked)) ~]
--
