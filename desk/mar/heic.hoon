::  HEIC image bytes, stored as an atom like %png.
::
|_  dat=@
::
++  grow
  |%
  ++  mime  [/image/heic (as-octs:mimes:html dat)]
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
