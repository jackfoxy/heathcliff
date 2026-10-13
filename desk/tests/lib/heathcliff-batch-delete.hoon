::  Batch deletion against virtual Clay: one soba, never per-file commits.
/+  *test, hd=heathcliff-batch-delete, ufiles=urui-files
|%
++  bowl
  ^-  bowl:gall
  %*  .  *bowl:gall
    our  ~zod
    now  ~2026.10.11
    byk  [~zod %heathcliff da+~2026.10.11]
  ==
::
++  fields
  |=  [scope=path paths=(list path)]
  ^-  (map @t json)
  %-  my
  :~  ['path' (path-json:hd scope)]
      ['paths' a+(turn paths path-json:hd)]
  ==
::
++  run
  |=  [scope=path paths=(list path) present=(set path)]
  ^-  tone
  =/  test-bowl=bowl:gall  bowl
  =/  request-fields  (fields scope paths)
  =/  now-path=path  /(scot %p ~zod)/base/(scot %da now.test-bowl)
  =/  work  |.((plan:hd test-bowl ~.req request-fields))
  %+  mink  [work %9 2 %0 1]
  |=  [ref=* request=*]
  ^-  (unit (unit))
  ?:  =(request [%cd /(scot %p ~zod)//(scot %da now.test-bowl)])
    ``(silt ~[%base])
  ?:  =(request [%cw now-path])  ``[10 now.test-bowl]
  ?:  ?=([%cy *] request)
    =/  rel=path  (slag 3 ;;(path +.request))
    ``[?:((~(has in present) rel) `1 ~) ~]
  ?:  ?=([%cx *] request)  ``&
  `~
::
++  planned
  |=  [scope=path paths=(list path) present=(set path)]
  ^-  outcome:hd
  =/  got=tone  (run scope paths present)
  ?>  ?=(%0 -.got)
  =/  result  ;;((each outcome:hd failure:ufiles) +.got)
  ?>  ?=(%& -.result)
  p.result
::
++  test-one-commit-for-multiple-files
  =/  paths=(list path)
    ~[/base/now/notes/a/txt /base/now/notes/sub/b/png]
  =/  present=(set path)  (silt (turn paths |=(p=path (slag 2 p))))
  =/  out  (planned /base/now/notes paths present)
  ?>  ?=(^ next.out)
  =/  changes=(list card:agent:gall)
    %+  murn  cards.out
    |=  =card:agent:gall
    ^-  (unit card:agent:gall)
    ?.  ?=([%pass * %arvo %c %info *] card)  ~
    `card
  =/  id=@ta  id.u.next.out
  =/  edits=soba:clay
    (turn paths.u.next.out |=(p=path [(slag 2 p) %del ~]))
  ;:  weld
    (expect-eq !>(1) !>((lent changes)))
    %+  expect-eq
      !>(~[[%pass /batch-delete/[id]/write %arvo %c %info %base %& edits]])
    !>(changes)
    (expect-eq !>(2) !>((lent paths.u.next.out)))
    (expect-eq !>((silt paths)) !>((silt paths.u.next.out)))
  ==
::
++  test-skips-missing-and-deduplicates
  =/  paths=(list path)
    ~[/base/now/a/txt /base/now/a/txt /base/now/missing/txt]
  =/  out  (planned /base/now paths (silt ~[/a/txt]))
  ?>  ?=(^ next.out)
  ;:  weld
    (expect-eq !>(~[/base/now/a/txt]) !>(paths.u.next.out))
    (expect-eq !>(1) !>((lent skipped.u.next.out)))
  ==
::
++  test-no-eligible-files-no-commit
  =/  out  (planned /base/now ~[/base/now/missing/txt] ~)
  ;:  weld
    (expect-eq !>(~) !>(next.out))
    %+  expect-eq  !>(|)
    !>((lien cards.out |=(c=card:agent:gall ?=(%pass -.c))))
  ==
::
++  test-rejects-history-cross-desk-and-out-of-scope
  =/  cases=(list [scope=path paths=(list path)])
    :~  [/base/3 ~[/base/3/a/txt]]
        [/base/now/notes ~[/base/now/other/a/txt]]
        [/base/now ~[/other/now/a/txt]]
        [/base/now ~[/base/now/a]]
    ==
  %-  zing
  %+  turn  cases
  |=  [scope=path paths=(list path)]
  ^-  tang
  =/  got=tone  (run scope paths ~)
  ?>  ?=(%0 -.got)
  =/  result  ;;((each outcome:hd failure:ufiles) +.got)
  (expect-eq !>(%|) !>(-.result))
::
++  status
  |=  out=outcome:hd
  ^-  @ud
  =/  found=(list @ud)
    %+  murn  cards.out
    |=  =card:agent:gall
    ^-  (unit @ud)
    ?.  ?=([%give %fact * %http-response-header *] card)  ~
    `status-code:!<(response-header:http q.cage.p.card)
  (snag 0 found)
::
++  job
  ^-  pending:hd
  =/  test-bowl=bowl:gall  bowl
  :*  ~.req  ~.batch  %base  10
      ~[/base/now/a/txt /base/now/b/png]
      ~[[/base/now/missing/txt 'file no longer exists']]
      (add now.test-bowl ~s10)
  ==
::
++  verified
  |=  [revision=@ud remaining=?]
  ^-  tone
  =/  test-bowl=bowl:gall  bowl
  =/  pending=pending:hd  job
  =/  work
    |.
    =/  out=outcome:hd
      %-  need
      %:  take:hd
        test-bowl  /batch-delete/batch/verify  [%clay %writ ~]  `pending
      ==
    (status out)
  %+  mink  [work %9 2 %0 1]
  |=  [ref=* request=*]
  ^-  (unit (unit))
  ?:  ?=([%cw *] request)  ``[revision now.test-bowl]
  ?:  ?=([%cy *] request)
    =/  full=path  ;;(path +.request)
    ::  First watched file is gone; verification must check the second.
    ``[?:(&(remaining =(/b/png (slag 3 full))) `1 ~) ~]
  `~
::
++  test-verifies-all-files-and-a-new-revision
  ;:  weld
    (expect-eq !>([%0 200]) !>((verified 11 |)))
    (expect-eq !>([%0 500]) !>((verified 10 |)))
    (expect-eq !>([%0 500]) !>((verified 11 &)))
  ==
::
++  test-timeout-write-failure-and-late-signs
  =/  expired=outcome:hd
    (need (take:hd bowl /batch-delete/batch/timeout [%behn %wake ~] `job))
  =/  failed=outcome:hd
    %-  need
    %:  take:hd
      bowl  /batch-delete/batch/write  [%clay %done `[%fail ~]]  `job
    ==
  ;:  weld
    (expect-eq !>(504) !>((status expired)))
    (expect-eq !>(500) !>((status failed)))
    (expect-eq !>(~) !>(next.expired))
    (expect-eq !>(~) !>(next.failed))
    %+  expect-eq  !>(`(unit outcome:hd)``[~ ~])
    !>((take:hd bowl /batch-delete/batch/verify [%clay %writ ~] ~))
    %+  expect-eq  !>(`(unit outcome:hd)``[~ `job])
    !>((take:hd bowl /batch-delete/old/timeout [%behn %wake ~] `job))
  ==
::
++  test-request-guards-and-empty-selection
  =/  req=inbound-request:eyre
    %*  .  *inbound-request:eyre
      authenticated  &
      request
        :*  %'POST'  '/heathcliff/delete-tree'
            ~[['content-type' 'application/json']]
            `(as-octs:mimes:html '{"path":["base","now"],"paths":[]}')
        ==
    ==
  =/  held=outcome:hd  (handle:hd bowl ~.req req &)
  =/  wrong=outcome:hd  (handle:hd bowl ~.req req(method.request %'GET') |)
  =/  broken=outcome:hd
    (handle:hd bowl ~.req req(body.request `(as-octs:mimes:html '{')) |)
  =/  empty=outcome:hd  (planned /base/now ~ ~)
  ;:  weld
    (expect-eq !>(503) !>((status held)))
    (expect-eq !>(405) !>((status wrong)))
    (expect-eq !>(400) !>((status broken)))
    (expect-eq !>(200) !>((status empty)))
    (expect-eq !>(~) !>(next.empty))
  ==
--
