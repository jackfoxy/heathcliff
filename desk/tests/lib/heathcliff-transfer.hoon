::  Tests for /lib/heathcliff-transfer: what stops an upload, how one
::  is verified, and how a download is served.
::
/+  *test, ht=heathcliff-transfer, ufiles=urui-files
|%
::  +|  Fixtures
::
++  bowl
  ^-  bowl:gall
  %*  .  *bowl:gall
    our  ~zod
    now  ~2026.10.4
    byk  [~zod %heathcliff da+~2026.10.4]
  ==
::
++  id  (scot %da ~2026.10.4)
::
++  job
  ^-  pending:ht
  [~.req id %base /notes/plan/txt ~['a' 'b'] (add ~2026.10.4 ~s10)]
::
++  writ
  |=  held=(unit cage)
  ^-  sign-arvo
  :+  %clay  %writ
  ?~  held  ~
  `[[%x da+~2026.10.4 %base] /notes/plan/txt u.held]
::
++  reply-status
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
++  header
  |=  [=simple-payload:http key=@t]
  ^-  (unit @t)
  (get-header:http key headers.response-header.simple-payload)
::
::  +|  Upload checks
::
++  test-problems
  ;:  weld
    (expect-eq !>(`(list @t)`~) !>((problems:ht %png 100 0 0 0)))
    ::  an empty file is a valid empty atom or empty text
    (expect-eq !>(`(list @t)`~) !>((problems:ht %txt 0 0 0 0)))
    (expect-eq !>(1) !>((lent (problems:ht %png (bex 24) 0 0 0))))
    ::  trailing NULs: lost by a bare atom, kept by octs and mime
    (expect-eq !>(1) !>((lent (problems:ht %png 10 2 0 0))))
    (expect-eq !>(1) !>((lent (problems:ht %txt 10 1 0 0))))
    (expect-eq !>(`(list @t)`~) !>((problems:ht %ttf 10 2 0 0)))
    (expect-eq !>(`(list @t)`~) !>((problems:ht %mime 10 2 0 0)))
    (expect-eq !>(`(list @t)`~) !>((problems:ht %mov 7.000 6.645 2 2)))
    (expect-eq !>(`(list @t)`~) !>((problems:ht %zip 10 7 2 2)))
    (expect-eq !>(`(list @t)`~) !>((problems:ht %rar 10 7 2 2)))
    (expect-eq !>(`(list @t)`~) !>((problems:ht %heic 10 0 2 2)))
    (expect-eq !>(`(list @t)`~) !>((problems:ht %sh 10 0 2 2)))
    (expect-eq !>(1) !>((lent (problems:ht %heic 10 1 0 0))))
    (expect-eq !>(`(list @t)`~) !>((problems:ht %m4a 10 0 2 2)))
    (expect-eq !>(1) !>((lent (problems:ht %m4a 10 1 0 0))))
    ::  no conversion into marks without +grab mime
    (expect-eq !>(1) !>((lent (problems:ht %hymn 10 0 0 0))))
    (expect-eq !>(1) !>((lent (problems:ht %jam 10 0 0 0))))
    ::  a missing mark with no source anywhere
    (expect-eq !>(1) !>((lent (problems:ht %png 10 0 2 1))))
    (expect-eq !>(`(list @t)`~) !>((problems:ht %png 10 0 2 2)))
  ==
::
++  test-m4a-download
  =/  data=mime  [/audio/mp4 3 'abc']
  ;:  weld
    (expect-eq !>(`data) !>((raw:ht %m4a 'abc')))
    (expect-eq !>(`%m4a) !>((extension:ht /audio/mp4)))
    (expect-eq !>('song.m4a') !>((filename:ht /song/m4a data)))
    (expect-eq !>('song.m4a') !>((filename:ht /song/mime data)))
  ==
::
::  +|  Verification
::
++  test-take-ignores-other-wires
  =/  [verify=wire write=wire timeout=wire]  (wires:ht id)
  =/  old=wire  timeout:(wires:ht ~.older)
  ;:  weld
    (expect !>(=(~ (take:ht bowl /urui-files/x/verify (writ ~) `job))))
    %+  expect-eq
      !>(`(unit outcome:ht)``[~ ~])
    !>((take:ht bowl timeout [%behn %wake ~] ~))
    %+  expect-eq
      !>(`(unit outcome:ht)``[~ `job])
    !>((take:ht bowl old [%behn %wake ~] `job))
  ==
::
++  test-take-verifies-the-read-back
  =/  [verify=wire write=wire timeout=wire]  (wires:ht id)
  =/  good=outcome:ht
    (need (take:ht bowl verify (writ `[%txt !>(`wain`~['a' 'b'])]) `job))
  =/  bad=outcome:ht
    (need (take:ht bowl verify (writ `[%txt !>(`wain`~['a'])]) `job))
  =/  lost=outcome:ht
    (need (take:ht bowl verify (writ ~) `job))
  ?>  ?=([[%pass * %arvo %b %rest *] *] cards.good)
  ;:  weld
    (expect-eq !>(200) !>((reply-status cards.good)))
    (expect !>(=(~ next.good)))
    (expect-eq !>(500) !>((reply-status cards.bad)))
    (expect-eq !>(500) !>((reply-status cards.lost)))
  ==
::
++  test-take-times-out
  =/  [verify=wire write=wire timeout=wire]  (wires:ht id)
  =/  out=outcome:ht  (need (take:ht bowl timeout [%behn %wake ~] `job))
  ?>  ?=([[%pass * %arvo %c %warp %~zod %base ~] *] cards.out)
  ;:  weld
    (expect-eq !>(504) !>((reply-status cards.out)))
    (expect !>(=(~ next.out)))
  ==
::
::  +|  Tombstones
::
++  tomb-result
  ::  Virtual Clay: a desk at revision 10, with independently controlled
  ::  historical and current lobes. Unhandled reads fail the test.
  |=  [pax=path old=(unit @uvI) current=(unit @uvI) live=?]
  ^-  tone
  =/  test-bowl=bowl:gall  bowl
  =/  now-path=path  /(scot %p ~zod)/base/(scot %da now.test-bowl)
  =/  old-path=path  /(scot %p ~zod)/base/3/note/txt
  =/  current-path=path  (weld now-path /note/txt)
  =/  tomb-path=path
    (weld /(scot %p ~zod)//(scot %da now.test-bowl)/tomb old-path)
  =/  run  |.((tomb-plan:ht test-bowl ~.req pax))
  %+  mink  [run %9 2 %0 1]
  |=  [ref=* request=*]
  ^-  (unit (unit))
  ?:  =(request [%cd /(scot %p ~zod)//(scot %da now.test-bowl)])
    ``(silt ~[%base])
  ?:  =(request [%cw now-path])  ``[10 now.test-bowl]
  ?:  =(request [%cy old-path])  ``[old ~]
  ?:  =(request [%cy current-path])  ``[current ~]
  ?:  =(request [%cx tomb-path])  ``live
  `~
::
++  test-tomb-rejects-current-and-invalid-revisions
  ;:  weld
    %+  expect-eq
      !>([%0 %| 'only a prior revision can be tombstoned'])
    !>((tomb-result /base/now/note/txt `0v1 `0v2 &))
    %+  expect-eq
      !>([%0 %| 'only a prior revision can be tombstoned'])
    !>((tomb-result /base/10/note/txt `0v1 `0v2 &))
    %+  expect-eq
      !>([%0 %| 'no such revision of that desk'])
    !>((tomb-result /base/11/note/txt `0v1 `0v2 &))
    %+  expect-eq
      !>([%0 %| 'no such revision of that desk'])
    !>((tomb-result /base/0/note/txt `0v1 `0v2 &))
    %+  expect-eq
      !>([%0 %| 'no such revision of that desk'])
    !>((tomb-result /base/bad/note/txt `0v1 `0v2 &))
    %+  expect-eq
      !>([%0 %| 'no such desk'])
    !>((tomb-result /missing/3/note/txt `0v1 `0v2 &))
    %+  expect-eq
      !>([%0 %| 'a path names its desk, revision and file'])
    !>((tomb-result /base/3 `0v1 `0v2 &))
  ==
::
++  test-tomb-rejects-missing-gone-and-current-content
  ;:  weld
    %+  expect-eq
      !>([%0 %| 'no file at that path in that revision'])
    !>((tomb-result /base/3/note/txt ~ `0v2 &))
    %+  expect-eq
      !>([%0 %| 'that version is already tombstoned'])
    !>((tomb-result /base/3/note/txt `0v1 `0v2 |))
    %+  expect-eq
      !>([%0 %| 'this version has the same content as the current file'])
    !>((tomb-result /base/3/note/txt `0v1 `0v1 &))
  ==
::
++  test-tomb-discards-only-the-historical-lobe
  =/  test-bowl=bowl:gall  bowl
  =/  verify=wire  /tomb/check/req/(scot %p ~zod)/base/3/note/txt
  =/  cards=(list card:agent:gall)
    :~  [%pass /tomb/clay %arvo %c %tomb %lobe 0v1]
        [%pass verify %arvo %b %wait now.test-bowl]
    ==
  ;:  weld
    %+  expect-eq  !>([%0 %& cards])
    !>((tomb-result /base/3/note/txt `0v1 `0v2 &))
    ::  Deleting the current file first also permits tombstoning history.
    %+  expect-eq  !>([%0 %& cards])
    !>((tomb-result /base/3/note/txt `0v1 ~ &))
  ==
::
++  test-tomb-verifies-success-and-clay-refusal
  =/  check
    |=  live=?
    ^-  @ud
    =/  test-bowl=bowl:gall  bowl
    =/  pax=path  /(scot %p ~zod)/base/3/note/txt
    =/  tomb-path=path
      (weld /(scot %p ~zod)//(scot %da now.test-bowl)/tomb pax)
    =/  verify=wire  (weld /tomb/check/req pax)
    =/  run
      |.((tomb-take:ht test-bowl verify [%behn %wake ~]))
    =/  result=tone
      %+  mink  [run %9 2 %0 1]
      |=  [ref=* request=*]
      ^-  (unit (unit))
      ?:  =(request [%cx tomb-path])  ``live
      `~
    ?>  ?=(%0 -.result)
    =/  cards=(unit (list card:agent:gall))
      ;;((unit (list card:agent:gall)) product.result)
    (reply-status (need cards))
  ;:  weld
    (expect-eq !>(200) !>((check |)))
    ::  Clay protects content referenced by any current desk or path.
    (expect-eq !>(409) !>((check &)))
  ==
::
++  test-tomb-take-ignores-other-signs
  ::  Only a %wake on a /tomb/check wire is read back; that read needs a
  ::  ship.
  ;:  weld
    (expect !>(=(~ (tomb-take:ht bowl /upload/x/verify [%behn %wake ~]))))
    %+  expect-eq
      !>(`(unit (list card:agent:gall))``~)
    !>((tomb-take:ht bowl /tomb/check/req/zod (writ ~)))
  ==
::
::  +|  Downloads
::
++  test-filename
  ;:  weld
    %+  expect-eq  !>('photo.png')
    !>((filename:ht /a/photo/png [/image/png 1 'x']))
    %+  expect-eq  !>('blob.png')
    !>((filename:ht /a/blob/mime [/image/png 1 'x']))
    %+  expect-eq  !>('movie.mov')
    !>((filename:ht /a/movie/mime [/video/quicktime 7.000 'x']))
    %+  expect-eq  !>('blob.bin')
    !>((filename:ht /a/blob/mime [/application/x-weird 1 'x']))
    %+  expect-eq  !>('thing.jam')
    !>((filename:ht /a/thing/noun [/application/x-urb-jam 1 'x']))
    %+  expect-eq  !>('file.kelvin')
    !>((filename:ht /kelvin [/text/plain 1 'x']))
  ==
::
++  test-raw
  ::  Atoms and known octs marks serve as stored; other nouns do not.
  ;:  weld
    %+  expect-eq
      !>(`(unit mime)``[/image/png 3 'abc'])
    !>((raw:ht %png 'abc'))
    %+  expect-eq
      !>(`(unit mime)``[/application/octet-stream 1 'a'])
    !>((raw:ht %unknown 'a'))
    %+  expect-eq
      !>(`(unit mime)``[/video/quicktime 7.000 'abc'])
    !>((raw:ht %mov [7.000 'abc']))
    (expect-eq !>(`(unit mime)`~) !>((raw:ht %noun [1 2])))
  ==
::
++  test-payload
  ::  Never sniffed; sandboxed except an inline PDF; a download is an
  ::  attachment named for the file.
  =/  html=mime  [/text/html 3 'abc']
  =/  shown  (payload:ht /a/page/html html |)
  =/  saved  (payload:ht /a/page/html html &)
  =/  pdf  (payload:ht /a/doc/pdf [/application/pdf 3 'abc'] |)
  =/  pdf-saved  (payload:ht /a/doc/pdf [/application/pdf 3 'abc'] &)
  ;:  weld
    (expect-eq !>(`'nosniff') !>((header shown 'x-content-type-options')))
    (expect-eq !>(`csp:ht) !>((header shown 'content-security-policy')))
    (expect-eq !>(~) !>((header shown 'content-disposition')))
    %+  expect-eq
      !>(`'attachment; filename="page.html"')
    !>((header saved 'content-disposition'))
    (expect-eq !>(~) !>((header pdf 'content-security-policy')))
    (expect-eq !>(`csp:ht) !>((header pdf-saved 'content-security-policy')))
    (expect-eq !>(`'application/pdf') !>((header pdf 'content-type')))
    (expect-eq !>(`octs`[3 'abc']) !>((need data.shown)))
  ==
--
