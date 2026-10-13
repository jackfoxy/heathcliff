::  Shell source as text lines, with %txt's diff and merge behavior.
::
|_  dat=wain
::
++  grow
  |%
  ++  mime  [/text/plain (as-octs:mimes:html (of-wain:format dat))]
  ++  txt   dat
  --
::
++  grab
  |%
  ++  mime  |=([p=mite q=octs] (to-wain:format q.q))
  ++  txt   wain
  ++  noun  wain
  --
::
++  grad  %txt
--
