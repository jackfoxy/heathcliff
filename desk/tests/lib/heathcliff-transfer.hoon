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
    ::  no conversion into marks without +grab mime
    (expect-eq !>(1) !>((lent (problems:ht %hymn 10 0 0 0))))
    (expect-eq !>(1) !>((lent (problems:ht %jam 10 0 0 0))))
    ::  a missing mark with no source anywhere
    (expect-eq !>(1) !>((lent (problems:ht %png 10 0 2 1))))
    (expect-eq !>(`(list @t)`~) !>((problems:ht %png 10 0 2 2)))
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
::  +|  Downloads
::
++  test-filename
  ;:  weld
    %+  expect-eq  !>('photo.png')
    !>((filename:ht /a/photo/png [/image/png 1 'x']))
    %+  expect-eq  !>('blob.png')
    !>((filename:ht /a/blob/mime [/image/png 1 'x']))
    %+  expect-eq  !>('blob.bin')
    !>((filename:ht /a/blob/mime [/application/x-weird 1 'x']))
    %+  expect-eq  !>('thing.jam')
    !>((filename:ht /a/thing/noun [/application/x-urb-jam 1 'x']))
    %+  expect-eq  !>('file.kelvin')
    !>((filename:ht /kelvin [/text/plain 1 'x']))
  ==
::
++  test-raw
  ::  An atom serves as stored; a structured noun has no raw form.
  ;:  weld
    %+  expect-eq
      !>(`(unit mime)``[/image/png 3 'abc'])
    !>((raw:ht %png 'abc'))
    %+  expect-eq
      !>(`(unit mime)``[/application/octet-stream 1 'a'])
    !>((raw:ht %unknown 'a'))
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
