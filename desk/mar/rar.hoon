::  RAR archive bytes, including trailing NULs.
::
|_  dat=octs
::
++  grow
  |%
  ++  mime  [~['application' 'vnd.rar'] dat]
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
