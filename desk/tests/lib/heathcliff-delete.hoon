::  Deletes with Heathcliff's locator, with virtual Clay reads.
::
/-  urui
/+  *test, hc=heathcliff-clay, ufiles=urui-files
|%
++  policy
  ^-  policy:ufiles
  =/  store=store:urui
    [%clay 'File' 'new file' '' ~[[~ ~ ~ &]] ~ ~[%save %copy] | ~]
  =/  config=files:urui  ['/heathcliff/files' ~[store] ~]
  =/  made=policy:ufiles  (make-policy:ufiles config ~ |)
  %=  made
    codecs          codecs:hc
    fallback        `%view
    locate          `locate:hc
    view            `inspect:hc
    edit-snapshots  &
  ==
::
++  bowl
  ^-  bowl:gall
  %*  .  *bowl:gall
    our  ~zod
    now  ~2026.10.11
    byk  [~zod %heathcliff da+~2026.10.11]
  ==
::
++  remove-result
  |=  $:  pax=path
          cod=codec:ufiles
          exists=?
          base=(unit @t)
          busy=?
          observe=?(%out %status %pending)
      ==
  ^-  tone
  =/  test-bowl=bowl:gall  bowl
  =/  pol=policy:ufiles  policy
  =/  now-path=path  /(scot %p ~zod)/base/(scot %da now.test-bowl)
  =/  full=path  (weld now-path (slag 2 pax))
  =/  past=path  (weld /(scot %p ~zod)/base/3 (slag 2 pax))
  =/  tomb=path  /(scot %p ~zod)//(scot %da now.test-bowl)/tomb
  =/  pending=(unit pending:ufiles)
    ?.  busy  ~
    `[~.previous ~.id %delete /base/now/other/txt ~ now.test-bowl]
  =/  run
    |.
    =/  out=outcome:ufiles
      (remove:ufiles pol test-bowl ~.req pax cod base pending)
    ?-  observe
      %out      out
      %status   (status out)
      %pending  ?=(^ next.out)
    ==
  %+  mink  [run %9 2 %0 1]
  |=  [ref=* request=*]
  ^-  (unit (unit))
  ?:  =(request [%cd /(scot %p ~zod)//(scot %da now.test-bowl)])
    ``(silt ~[%base])
  ?:  =(request [%cw now-path])  ``[10 now.test-bowl]
  ?:  |(=(request [%cy full]) =(request [%cy past]))
    ``[?:(exists `1 ~) ~]
  ?:  ?|  =(request [%cx (weld tomb full)])
          =(request [%cx (weld tomb past)])
      ==
    ``exists
  ?:  =(request [%cq full])  ``'stored'
  `~
::
++  status
  |=  out=outcome:ufiles
  ^-  @ud
  =/  found=(list @ud)
    %+  murn  cards.out
    |=  =card:agent:gall
    ^-  (unit @ud)
    ?.  ?=([%give %fact * %http-response-header *] card)  ~
    `status-code:!<(response-header:http q.cage.p.card)
  ?>  ?=([* ~] found)
  i.found
::
++  test-delete-commits-one-file-on-the-selected-desk
  ::  %info with one %del creates a revision; it does not discard lobes
  ::  or edit any historical revision. Text and binary files both work.
  =/  test-bowl=bowl:gall  bowl
  =/  id=@ta  (scot %da now.test-bowl)
  =/  until=@da  (add now.test-bowl default-timeout:ufiles)
  =/  cases=(list [path codec:ufiles])
    :~  [/base/now/note/hoon %cord]
        [/base/now/note/txt %wain]
        [/base/now/picture/png %view]
        [/base/now/unknown/mark %view]
        [/base/now/malformed/json %json]
        [/base/now/missing-mark/md %mime]
    ==
  %-  zing
  %+  turn  cases
  |=  [pax=path cod=codec:ufiles]
  ^-  tang
  ?>  ?=([@ @ ^] pax)
  =/  result=tone  (remove-result pax cod & ~ | %out)
  =/  expected=(list card:agent:gall)
    :~  :*  %pass  /urui-files/[id]/verify  %arvo  %c  %warp
            ~zod  %base  ~  %next  %x  da+now.test-bowl  t.t.pax
        ==
        :*  %pass  /urui-files/[id]/write  %arvo  %c  %info  %base  %&
            ~[[t.t.pax %del ~]]
        ==
        [%pass /urui-files/[id]/timeout %arvo %b %wait until]
    ==
  =/  job=(unit pending:ufiles)  `[~.req id %delete pax ~ until]
  (expect-eq !>([%0 expected job]) !>(result))
::
++  test-delete-refuses-history-missing-files-and-busy-writes
  ;:  weld
    %+  expect-eq  !>([%0 403])
    !>((remove-result /base/3/note/hoon %cord & ~ | %status))
    %+  expect-eq  !>([%0 404])
    !>((remove-result /base/now/note/hoon %cord | ~ | %status))
    %+  expect-eq  !>([%0 404])
    !>((remove-result /base/now/folder %view | ~ | %status))
    %+  expect-eq  !>([%0 404])
    !>((remove-result /missing/now/note/hoon %cord & ~ | %status))
    %+  expect-eq  !>([%0 400])
    !>((remove-result /base %cord & ~ | %status))
    %+  expect-eq  !>([%0 503])
    !>((remove-result /base/now/note/hoon %cord & ~ & %status))
  ==
::
++  test-delete-hash-protects-against-stale-content
  =/  good=tone
    %:  remove-result
      /base/now/note/hoon  %cord  &  `(text-hash:ufiles 'stored')  |
      %pending
    ==
  =/  stale=tone
    (remove-result /base/now/note/hoon %cord & `'old-hash' | %status)
  ;:  weld
    (expect-eq !>([%0 &]) !>(good))
    (expect-eq !>([%0 409]) !>(stale))
  ==
--
