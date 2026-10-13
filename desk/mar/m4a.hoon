::  MPEG-4 audio bytes, stored as an atom like %mp4.
::
|_  dat=@
::
++  grow
  |%
  ++  mime  [/audio/mp4 (as-octs:mimes:html dat)]
  --
::
++  grab
  |%
  ++  mime  |=([p=mite q=octs] q.q)
  ++  noun  @
  --
::
++  grad  %mime
--
