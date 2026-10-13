::  Tests for /lib/heathcliff-perm: rules, crews, and their JSON.
::
/+  *test, hp=heathcliff-perm
|%
::  +|  Fixtures
::
++  friends
  ^-  crews:hp
  (malt ~[[%friends (silt ~[~nec ~bud])]])
::
++  usage
  ^-  usage:hp
  =/  rule=rule:clay  [%white (silt ~[[%| %friends]])]
  =/  regs=regs:clay  (malt ~[[/app rule] [/lib rule]])
  =/  desks=(list [desk [r=regs:clay w=regs:clay]])
    ~[[%base [regs ~]] [%garden [~ regs]]]
  (malt ~[[%friends (malt desks)]])
::
++  json-text
  |=  jon=json
  ^-  @t
  (en:json:html jon)
::
::  +|  Reading rules
::
++  test-gist
  ;:  weld
    (expect-eq !>('private') !>((gist:hp [%white ~ ~])))
    (expect-eq !>('public') !>((gist:hp [%black ~ ~])))
    (expect-eq !>('only 1 ship') !>((gist:hp [%white (silt ~[~zod]) ~])))
    %+  expect-eq
      !>('everyone except 2 ships and 1 crew')
    !>((gist:hp [%black (silt ~[~zod ~nec]) (malt ~[[%friends ~]])]))
  ==
::
++  test-owns
  ::  Set here when the source is the path; at the desk root clay's own
  ::  empty whitelist counts as unset.
  =/  rule=real:clay  [%white (silt ~[~zod]) ~]
  ;:  weld
    (expect !>((owns:hp /app [/app rule])))
    (expect !>(!(owns:hp /app/foo [/app rule])))
    (expect !>(!(owns:hp / [/ dull:hp])))
    (expect !>((owns:hp / [/ rule])))
  ==
::
++  test-rule-json-origin
  =/  rule=real:clay
    [%black (silt ~[~zod]) (malt ~[[%friends (silt ~[~nec])]])]
  =/  here=@t  (json-text (rule-json:hp /app [/app rule]))
  =/  above=@t  (json-text (rule-json:hp /app/foo [/app rule]))
  =/  none=@t  (json-text (rule-json:hp / [/ dull:hp]))
  ;:  weld
    (expect !>(!=(~ (find "\"origin\":\"here\"" (trip here)))))
    (expect !>(!=(~ (find "\"origin\":\"inherited\"" (trip above)))))
    (expect !>(!=(~ (find "\"from\":\"/app\"" (trip above)))))
    (expect !>(!=(~ (find "\"origin\":\"default\"" (trip none)))))
    (expect !>(!=(~ (find "\"members\":[\"~nec\"]" (trip here)))))
  ==
::
++  test-cited
  ::  Usage counts rules on both sides of every desk.
  (expect-eq !>([rules=4 desks=2]) !>((cited:hp usage %friends)))
::
::  +|  Changing rules
::
++  test-words-and-fleet
  =/  got  (fleet:hp '~zod, ~nec\0anot-a-ship')
  ;:  weld
    (expect-eq !>(`(list @t)`~['a' 'b' 'c']) !>((words:hp 'a, b\0a\09c')))
    (expect-eq !>(`(list @t)`~['not-a-ship']) !>(bad.got))
    (expect-eq !>((silt ~[~zod ~nec])) !>(out.got))
  ==
::
++  test-set-rule
  =/  clear  (set-rule:hp friends %base /app & & '' '' '')
  =/  set
    (set-rule:hp friends %base /app | | 'black' '~zod' 'friends')
  =/  stranger  (set-rule:hp friends %base /app & | 'white' '' 'enemies')
  =/  junk  (set-rule:hp friends %base /app & | 'white' 'zod' '')
  ?>  ?=(%& -.clear)
  ?>  ?=(%& -.set)
  ;:  weld
    %+  expect-eq
      !>(`card:agent:gall`[%pass /perm/set %arvo %c %perm %base /app %r ~])
    !>(p.clear)
    %+  expect-eq
      !>  ^-  card:agent:gall
      :*  %pass  /perm/set  %arvo  %c  %perm  %base  /app  %w
          ~  %black  (silt `(list whom:clay)`~[[%& ~zod] [%| %friends]])
      ==
    !>(p.set)
    (expect !>(?=(%| -.stranger)))
    (expect !>(?=(%| -.junk)))
  ==
::
++  test-crews
  =/  saved  (crew-save:hp 'pals' '~zod ~nec')
  =/  empty  (crew-save:hp 'pals' '')
  =/  named  (crew-save:hp 'Pals!' '~zod')
  =/  nobody  (crew-save:hp '' '~zod')
  =/  killed  (crew-kill:hp friends 'friends')
  =/  missing  (crew-kill:hp friends 'pals')
  ?>  ?=(%& -.saved)
  ?>  ?=(%& -.killed)
  ;:  weld
    %+  expect-eq
      !>  ^-  (list card:agent:gall)
      :~  [%pass /perm/cred %arvo %c %cred %pals (silt ~[~zod ~nec])]
          [%pass /perm/crew %arvo %c %crew ~]
      ==
    !>(p.saved)
    (expect !>(?=(%| -.empty)))
    (expect !>(?=(%| -.named)))
    (expect !>(?=(%| -.nobody)))
    %+  expect-eq
      !>  ^-  (list card:agent:gall)
      :~  [%pass /perm/cred %arvo %c %cred %friends ~]
          [%pass /perm/crew %arvo %c %crew ~]
      ==
    !>(p.killed)
    (expect !>(?=(%| -.missing)))
  ==
--
