::  Tests for /lib/heathcliff-clay: its pure arms, and the per-mark
::  policy heathcliff hands urui-files.
::
/+  *test, hc=heathcliff-clay, ufiles=urui-files, web=heathcliff-web
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
++  marks
  ::  Every mark in desk/mar, with the codec heathcliff edits it by.
  ::  Keep in step with desk/mar: a mark added there needs a row here.
  ^-  (list [mark=@tas codec=@tas])
  :~  [%aac %view]  [%atom %view]  [%avi %view]  [%bill %mime]
      [%bmp %view]  [%css %cord]  [%csv %wain]  [%docket-0 %mime]
      [%flac %view]  [%gif %view]  [%hoon %cord]  [%html %cord]
      [%hymn %view]  [%ico %view]  [%jam %view]  [%jpeg %view]
      [%jpg %view]  [%js %cord]  [%json %json]  [%kelvin %mime]
      [%map %cord]  [%md %wain]  [%mid %view]  [%mime %view]
      [%mp3 %view]  [%mp4 %view]  [%mpeg %view]  [%noun %view]
      [%oga %view]  [%ogg %view]  [%ogv %view]  [%otf %view]
      [%pdf %view]  [%pem %wain]  [%png %view]  [%ship %mime]
      [%snip %view]  [%svg %cord]  [%tab %wain]  [%tiff %view]
      [%ttf %view]  [%txt %wain]  [%txt-diff %view]  [%udon %cord]
      [%umd %cord]  [%urb %view]  [%wav %view]  [%weba %view]
      [%webm %view]  [%webp %view]  [%woff2 %view]  [%xml %cord]
  ==
::
::  +|  The mark policy
::
++  test-edit-historical-copies
  =/  policy=policy:ufiles  file-policy:web
  (expect !>(edit-snapshots.policy))
::
++  test-every-mark-has-a-policy
  ::  52 marks; an unknown mark is read-only too.
  ::  wet +snoc and +weld here loop the type check (fuse-loop)
  =/  all=(list [mark=@tas codec=@tas])  [[%some-other-mark %view] marks]
  =/  policy=policy:ufiles  file-policy:web
  =/  found=(list tang)
    %+  turn  all
    |=  [mark=@tas codec=@tas]
    ^-  tang
    =/  rel=path  /base/now/folder/file/[mark]
    =/  want=(unit codec:ufiles)  `;;(codec:ufiles codec)
    =/  got=(unit codec:ufiles)  (file-codec:ufiles policy rel |)
    (expect-eq !>(want) !>(got))
  =/  count=tang  (expect-eq !>(52) !>((lent marks)))
  (zing `(list tang)`[count found])
::
++  test-text-marks-round-trip
  ::  Each pure text codec gives back exactly the text it was given.
  =/  text=@t  'first line\0a\0athird ☃\0a'
  =/  found=(list tang)
    %+  turn  codecs:hc
    |=  [mark=@tas =codec:ufiles]
    ^-  tang
    ?:  ?=(?(%mime %json) codec)  ~
    =/  made=(each cage tang)  (to-cage:ufiles mark codec text)
    ?:  ?=(%| -.made)  p.made
    (expect-eq !>(`text) !>((from-stored:ufiles codec q.q.p.made)))
  (zing found)
::
++  test-uploadable-marks-exist
  ::  A mark upload converts into must be a real mark; octs marks keep
  ::  their length.
  =/  have=(set @tas)  (silt (turn marks |=([m=@tas *] m)))
  ;:  weld
    (expect !>((levy ~(tap in grabs:hc) |=(m=@tas (~(has in have) m)))))
    (expect !>(!(~(has in grabs:hc) %hymn)))
    (expect !>(!(~(has in grabs:hc) %noun)))
    (expect !>((~(has in octs-marks:hc) %woff2)))
    (expect !>(!(~(has in octs-marks:hc) %png)))
  ==
::
::  +|  Roots and cases
::
++  test-order-by-title-then-desk
  =/  roots=(list root:hc)
    :~  [%zeta 'alpha' 1]
        [%base '%base' 3]
        [%garden 'Garden' 2]
        [%apps 'garden' 4]
        [%b 'Alpha' 1]
    ==
  %+  expect-eq
    !>(`(list @tas)`~[%base %b %zeta %apps %garden])
  !>((turn (sort roots order:hc) |=(=root:hc desk.root)))
::
++  test-read-case
  ::  `now`, or a revision of that desk between 1 and its head.
  =/  read
    |=  seg=@ta
    ^-  (unit case)
    (read-case:hc bowl seg 9)
  ;:  weld
    (expect-eq !>(`(unit case)``da+~2026.10.4) !>((read ~.now)))
    (expect-eq !>(`(unit case)``ud+5) !>((read ~.5)))
    (expect-eq !>(`(unit case)``ud+9) !>((read ~.9)))
    (expect-eq !>(`(unit case)`~) !>((read ~.10)))
    (expect-eq !>(`(unit case)`~) !>((read ~.0)))
    (expect-eq !>(`(unit case)`~) !>((read ~.five)))
  ==
::
++  test-identity-names-desk-and-case
  ::  One clay path on two desks, or at two cases, is two documents.
  =/  pax=path  /app/foo/hoon
  =/  here=path  (wire-path:hc bowl [~zod %base da+~2026.10.4] pax)
  =/  there=path  (wire-path:hc bowl [~zod %garden da+~2026.10.4] pax)
  =/  then=path  (wire-path:hc bowl [~zod %base ud+12] pax)
  ;:  weld
    (expect-eq !>(/base/now/app/foo/hoon) !>(here))
    (expect-eq !>(/garden/now/app/foo/hoon) !>(there))
    (expect-eq !>(`path`~[%base ~.12 %app %foo %hoon]) !>(then))
    (expect !>(!=(here there)))
    (expect !>(!=(here then)))
  ==
::
::  +|  Marks
::
++  test-kin
  ;:  weld
    (expect-eq !>(`(list @tas)`~[%txt %hoon]) !>((kin:hc %hoon)))
    (expect-eq !>(`(list @tas)`~[%mime %png]) !>((kin:hc %png)))
    (expect-eq !>(`(list @tas)`~[%noun %bill]) !>((kin:hc %bill)))
    (expect-eq !>(`(list @tas)`~[%txt]) !>((kin:hc %txt)))
  ==
::
++  test-splt
  ;:  weld
    %+  expect-eq
      !>(`(unit [@ta @tas])``[~.photo-one %png])
    !>((splt:hc 'Photo One.PNG'))
    %+  expect-eq
      !>(`(unit [@ta @tas])``[~.archive-tar %gz])
    !>((splt:hc 'archive.tar.gz'))
    (expect-eq !>(`(unit [@ta @tas])`~) !>((splt:hc 'noext')))
    (expect-eq !>(`(unit [@ta @tas])`~) !>((splt:hc '.hidden')))
    (expect-eq !>(`(unit [@ta @tas])`~) !>((splt:hc 'trailing.')))
  ==
::
::  +|  Inspection
::
++  test-dump
  =/  row=tape
    :(weld "00000000  41 42 " (reap 42 ' ') " |AB|")
  =/  long=wain  (dump:hc 0 5.000)
  ;:  weld
    (expect-eq !>(`wain`~[(crip row)]) !>((dump:hc 'AB' 2)))
    (expect-eq !>(257) !>((lent long)))
    (expect-eq !>('… 904 more bytes') !>((rear long)))
    (expect-eq !>(`wain`~) !>((dump:hc 0 0)))
  ==
::
++  test-inspect
  =/  font=@t  (inspect:hc %ttf [3 'abc'])
  =/  pic=@t  (inspect:hc %png 'abc')
  =/  env=@t  (inspect:hc %mime [/image/png 2 'AB'])
  =/  para=manx  ;p: hi
  =/  page=@t  (inspect:hc %hymn para)
  =/  diff=@t  (inspect:hc %txt-diff ~[[%& 2] [%| ~['a'] ~['b']]])
  =/  odd=@t  (inspect:hc %md 'stored as a cord')
  =/  cell=@t  (inspect:hc %noun [1 2])
  =/  big=@t  (inspect:hc %noun (reap 100.000 %a))
  ;:  weld
    %+  expect-eq
      !>('%ttf font, 3 bytes.\0aIts specimen is in the result pane.')
    !>(font)
    (expect !>(=('%png image, 3 bytes.' (snag 0 (to-wain:format pic)))))
    (expect !>(=('type: image/png' (snag 0 (to-wain:format env)))))
    (expect !>(=('length: 2 bytes' (snag 1 (to-wain:format env)))))
    (expect-eq !>('<p>hi</p>') !>(page))
    (expect-eq !>('= 2 unchanged lines\0a- a\0a+ b') !>(diff))
    (expect-eq !>('%md, stored as text:\0a\0astored as a cord') !>(odd))
    (expect-eq !>('%noun, a noun:\0a\0a[1 2]') !>(cell))
    (expect !>((lte (met 3 big) (add view-max:hc 32))))
  ==
--
