::  Tests for /app/heathcliff: state upgrades and the HTTP boundary.
::
::    Only paths that refuse or answer before any clay scry are driven
::    here; the scrying routes need a real desk.
::
/+  *test
/=  agent  /app/heathcliff
|%
::  +|  Fixtures
::
++  bol
  ^-  bowl:gall
  %*  .  *bowl:gall
    our  ~zod
    src  ~zod
    dap  %heathcliff
    now  ~2026.10.4
    byk  [~zod %heathcliff %da ~2026.10.4]
  ==
::
++  crews  (malt ~[[~.friends (silt ~[~nec ~bud])]])
::
++  mirror
  ^-  card:agent:gall
  [%pass /perm/crew %arvo %c %crew ~]
::
++  request
  |=  [method=method:http url=@t auth=? body=(unit octs)]
  ^-  inbound-request:eyre
  %*  .  *inbound-request:eyre
    authenticated  auth
    request
      %*  .  *request:http
        method       method
        url          url
        body         body
        header-list  ~[['content-type' 'application/json']]
      ==
  ==
::
++  poke
  |=  req=inbound-request:eyre
  ^-  (list card:agent:gall)
  -:(on-poke:~(. agent bol) %handle-http-request !>([~.eyre req]))
::
++  status
  ::  The status of the one response among `cards`.
  |=  cards=(list card:agent:gall)
  ^-  @ud
  =/  found=(list @ud)
    %+  murn  cards
    |=  =card:agent:gall
    ^-  (unit @ud)
    ?.  ?=([%give %fact * %http-response-header *] card)  ~
    `status-code:!<(response-header:http q.cage.p.card)
  ?>  ?=([* ~] found)
  i.found
::
++  body
  |=  cards=(list card:agent:gall)
  ^-  @t
  =/  found=(list @t)
    %+  murn  cards
    |=  =card:agent:gall
    ^-  (unit @t)
    ?.  ?=([%give %fact * %http-response-data *] card)  ~
    =/  data  !<((unit octs) q.cage.p.card)
    ?~(data ~ `q.u.data)
  ?>  ?=([* ~] found)
  i.found
::
++  load
  ::  The state saved after loading `old`, and the cards loading passed.
  ::
  ::    The %verb wrapper also gives event facts; only %pass cards are
  ::    the agent's own.
  |=  old=vase
  ^-  [cards=(list card:agent:gall) saved=*]
  =/  [cards=(list card:agent:gall) next=agent:gall]
    (on-load:~(. agent bol) old)
  =/  passed=(list card:agent:gall)
    (skim cards |=(=card:agent:gall ?=(%pass -.card)))
  [passed q:~(on-save next bol)]
::
::  +|  State
::
++  test-upgrades-keep-the-crew-mirror
  ::  Every version loads; crews survive; pending writes never do; and
  ::  the mirror is refreshed.
  =/  zero  (load !>([%0 ~]))
  =/  one  (load !>([%1 crews ~]))
  =/  job  [~.e ~.i %save /base/now/a/txt `'x' ~2026.10.4]
  =/  two  (load !>([%2 crews ~ `job ~]))
  ;:  weld
    (expect !>(=(saved.zero [%2 ~ ~ ~ ~])))
    (expect !>(=(saved.one [%2 crews ~ ~ ~])))
    (expect !>(=(saved.two [%2 crews ~ ~ ~])))
    (expect-eq !>(~[mirror]) !>(cards.zero))
    (expect-eq !>(~[mirror]) !>(cards.one))
    (expect-eq !>(~[mirror]) !>(cards.two))
  ==
::
::  +|  HTTP
::
++  test-the-page-needs-a-session
  =/  out  (poke (request %'GET' '/heathcliff' | ~))
  =/  in  (poke (request %'GET' '/heathcliff' & ~))
  ;:  weld
    (expect-eq !>(307) !>((status out)))
    (expect-eq !>(200) !>((status in)))
    (expect !>(!=(~ (find "apps-tree" (trip (body in))))))
    (expect !>(!=(~ (find "data-tree" (trip (body in))))))
  ==
::
++  test-data-routes-refuse-without-a-session
  =/  routes=(list [method:http @t])
    :~  [%'POST' '/heathcliff/files']
        [%'POST' '/heathcliff/api']
        [%'POST' '/heathcliff/upload/base/now']
        [%'GET' '/heathcliff/raw/base/now/sys/kelvin']
    ==
  %-  zing
  %+  turn  routes
  |=  [method=method:http url=@t]
  ^-  tang
  (expect-eq !>(401) !>((status (poke (request method url | ~)))))
::
++  test-old-routes-are-gone
  =/  old=(list @t)
    :~  '/heathcliff/view/our/base/now'
        '/heathcliff/perm/our/base/now'
        '/heathcliff/down/our/base/now/sys/kelvin'
    ==
  %-  zing
  %+  turn  old
  |=  url=@t
  ^-  tang
  (expect-eq !>(404) !>((status (poke (request %'GET' url & ~)))))
::
++  test-assets-serve
  =/  urls=(list @t)
    ~['/heathcliff/app.js' '/heathcliff/app.css' '/heathcliff/ace/ace.js']
  %-  zing
  %+  turn  urls
  |=  url=@t
  ^-  tang
  (expect-eq !>(200) !>((status (poke (request %'GET' url | ~)))))
::
++  test-root-browse-lists-nothing
  ::  urui's file dialog lists the root before a draft's first save.
  =/  text=@t  '{"op":"browse","scope":[]}'
  =/  out
    (poke (request %'POST' '/heathcliff/files' & `(as-octs:mimes:html text)))
  ;:  weld
    (expect-eq !>(200) !>((status out)))
    (expect !>(!=(~ (find "\"entries\":[]" (trip (body out))))))
  ==
::
++  test-perm-acks-are-quiet
  ::  clay acks every %cred; the agent takes it without crashing
  =/  ack=sign-arvo  [%clay %done ~]
  =/  out  (on-arvo:~(. agent bol) /perm/cred ack)
  =/  passed=(list card:agent:gall)
    (skim -.out |=(=card:agent:gall ?=(%pass -.card)))
  (expect-eq !>(`(list card:agent:gall)`~) !>(passed))
::
++  test-api-refuses-bad-requests
  =/  send
    |=  text=@t
    ^-  @ud
    %-  status
    (poke (request %'POST' '/heathcliff/api' & `(as-octs:mimes:html text)))
  ;:  weld
    (expect-eq !>(400) !>((send 'not json')))
    (expect-eq !>(400) !>((send '{"op":"nothing"}')))
    (expect-eq !>(400) !>((send '{"op":"attributes"}')))
    %+  expect-eq  !>(403)
    !>((send '{"op":"rule","path":["base","3"],"side":"read"}'))
  ==
--
