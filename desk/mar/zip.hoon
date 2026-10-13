::  ZIP archive bytes, including trailing NULs.
::
|_  dat=octs
::
++  grow
  |%
  ++  mime  [/application/zip dat]
  --
::
++  grab
  |%
  ++  mime  |=([=mite =octs] octs)
  ++  noun  octs
  --
::
++  grad  %mime
--
