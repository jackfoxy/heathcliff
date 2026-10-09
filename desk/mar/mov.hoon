::  QuickTime movie bytes, including trailing NULs.
::
|_  dat=octs
::
++  grow
  |%
  ++  mime  [/video/quicktime dat]
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
