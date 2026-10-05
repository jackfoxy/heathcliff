::  heathcliff-transfer: uploads from the browser, downloads to it
::
::    An upload commits one file, and any marks it needs, in a single
::    %info, so the desk gains a working file or nothing.  Clay sends no
::    gift for an %info, so the commit is verified: a %warp watches the
::    path, a %wait bounds it, and the file must read back as the noun
::    its mark makes of the upload.
::
::    A download is the file's external form, its mark's +grow mime.
::    For a noun-shaped mark that is not necessarily the bytes that were
::    uploaded: %noun downloads as its jam.
::
/+  hc=heathcliff-clay, ufiles=urui-files
|%
::  +|  Types
::
+$  pending
  ::  The one upload awaiting clay, and the noun it must read back as.
  $:  eyre-id=@ta
      id=@ta
      =desk
      tar=path
      expect=*
      until=@da
  ==
::
+$  plan
  ::  What an upload into a directory would do.
  ::
  ::    `install` lists the marks the desk lacks, dependencies first,
  ::    each with the desk its source comes from.
  $:  tar=path
      =mark
      exists=?
      install=(list [=mark from=desk])
      problems=(list @t)
  ==
::
+$  outcome  [cards=(list card:agent:gall) next=(unit pending)]
::
::  +|  Uploads
::
++  check
  ::  What uploading `filename`, `size` bytes ending in `nul` NUL bytes,
  ::  into `dir` on `desk` would do, and anything that stops it.
  |=  [=bowl:gall =desk dir=path filename=@t size=@ud nul=@ud]
  ^-  (each plan @t)
  ?.  (~(has in (desks:hc bowl)) desk)  [%| 'no such desk']
  =/  spl=(unit [nam=@ta =mark])  (splt:hc filename)
  ?~  spl
    [%| (crip "{(trip filename)} needs an extension to name its mark")]
  =/  =mark  mark.u.spl
  =/  tar=path  (weld dir /[nam.u.spl]/[mark])
  =/  gap=(list ^mark)  (missing:hc bowl desk mark)
  =/  install=(list [^mark ^desk])
    %+  murn  gap
    |=  m=^mark
    ^-  (unit [^mark ^desk])
    =/  got  (source:hc bowl m)
    ?~(got ~ `[m from.u.got])
  =/  stops=(list @t)  (problems mark size nul (lent gap) (lent install))
  [%& tar mark (has-file:hc bowl desk tar) install stops]
::
++  problems
  ::  What stops an upload of `size` bytes ending in `nul` NUL bytes as
  ::  `mark`, when the desk lacks `gap` marks and `found` have sources.
  |=  [=mark size=@ud nul=@ud gap=@ud found=@ud]
  ^-  (list @t)
  %-  zing
  ^-  (list (list @t))
  :~  ?.  (gth size limit:hc)  ~
      ~[(crip "larger than the {(a-co:co (rsh [0 20] limit:hc))}MiB limit")]
    ::
      ?.  &(!=(0 nul) !(~(has in octs-marks:hc) mark))  ~
      :_  ~
      %-  crip
      ;:  weld
        "ends in {(a-co:co nul)} NUL byte{?:(=(1 nul) "" "s")}, which "
        "the %{(trip mark)} mark cannot store: it keeps a bare atom, "
        "which has no high zeros.  Name it .mime to keep every byte."
      ==
    ::
      ?:  |(=(%mime mark) (~(has in grabs:hc) mark))  ~
      ~[(crip "heathcliff cannot convert an upload into %{(trip mark)}")]
    ::
      ?:  =(found gap)  ~
      ~[(crip "no source for the %{(trip mark)} mark or its dependencies")]
  ==
::
++  commit
  ::  The cards committing an upload and verifying it, or the refusal.
  ::
  ::    Marks the desk lacks are installed only with `install`; an
  ::    existing file is replaced only with `overwrite`.  The conversion
  ::    is tried before the commit, on the target desk when it has the
  ::    mark, else on the desk the mark's source comes from.
  |=  $:  =bowl:gall
          eyre-id=@ta
          =desk
          dir=path
          filename=@t
          type=(unit mite)
          size=@ud
          body=@
          install=?
          overwrite=?
          current=(unit pending)
      ==
  ^-  outcome
  =/  no
    |=  =failure:ufiles
    ^-  outcome
    [(refuse:ufiles eyre-id failure) current]
  ?^  current
    (no [%unavailable 503 'another upload is pending' & ~])
  =/  nul=@ud  (sub size (met 3 body))
  =/  checked=(each plan @t)  (check bowl desk dir filename size nul)
  ?:  ?=(%| -.checked)  (no (fail:ufiles %bad-request 400 p.checked))
  =/  =plan  p.checked
  ?^  problems.plan  (no (fail:ufiles %unprocessable 422 i.problems.plan))
  ?:  &(exists.plan !overwrite)
    (no (fail:ufiles %exists 409 'a file with that name exists here'))
  ?:  &(?=(^ install.plan) !install)
    (no (fail:ufiles %needs-marks 409 'marks must be installed first'))
  =/  =mark  mark.plan
  =/  =mime
    :_  [size body]
    (fall type (fall (ctype:hc mark) /application/octet-stream))
  =/  via=^desk
    ?:  (has-file:hc bowl desk /mar/[mark]/hoon)  desk
    =/  got  (source:hc bowl mark)
    ?~(got desk from.u.got)
  =/  made=(each * tang)
    ?:  =(%mime mark)  [%& mime]
    %-  mule  |.
    =/  =tube:clay
      .^(tube:clay %cc (tube-path:ufiles bowl via %mime mark))
    q:(tube !>(mime))
  ?:  ?=(%| -.made)
    %-  no
    %:  fail-with:ufiles
      %unprocessable
      422
      (crip "the %{(trip mark)} mark does not accept this file")
      p.made
    ==
  =/  full=path  (en-beam [our.bowl desk da+now.bowl] tar.plan)
  =/  same=?
    ?&  exists.plan
        (live:hc bowl full)
        =(p.made .^(* %cq full))
    ==
  =/  done=(list card:agent:gall)
    =/  wire-path=path  [desk %now tar.plan]
    %+  reply:ufiles  eyre-id
    (ok-json:ufiles ~[['path' a+(turn wire-path |=(s=@ta s+s))]])
  ?:  same  [done current]
  =/  marks=soba:clay
    %+  murn  install.plan
    |=  [m=^mark from=^desk]
    ^-  (unit [path miso:clay])
    =/  got  (source:hc bowl m)
    ?~  got  ~
    `[/mar/[m]/hoon %ins %hoon !>(src.u.got)]
  =/  id=@ta  (scot %da now.bowl)
  =/  until=@da  (add now.bowl default-timeout:ufiles)
  =/  [verify=wire write=wire timeout=wire]  (wires id)
  :_  `[eyre-id id desk tar.plan p.made until]
  :~  :*  %pass  verify  %arvo  %c  %warp  our.bowl  desk
          ~  %next  %x  da+now.bowl  tar.plan
      ==
      :*  %pass  write  %arvo  %c  %info  desk  %&
          (snoc marks [tar.plan %ins %mime !>(mime)])
      ==
      [%pass timeout %arvo %b %wait until]
  ==
::
++  take
  ::  A clay or behn sign on an /upload wire; ~ for any other wire.
  |=  [=bowl:gall =wire =sign-arvo current=(unit pending)]
  ^-  (unit outcome)
  ?.  ?=([%upload @ @ ~] wire)  ~
  =/  job=(unit pending)  current
  ?~  job  `[~ current]
  ?.  =(i.t.wire id.u.job)  `[~ current]
  =/  [verify=^wire write=^wire timeout=^wire]  (wires id.u.job)
  ?:  =(%timeout i.t.t.wire)
    ?.  ?=([%behn %wake *] sign-arvo)  `[~ current]
    =/  late=failure:ufiles
      [%timeout 504 'clay did not confirm the upload' & ~]
    :-  ~
    :_  ~
    :-  [%pass verify %arvo %c %warp our.bowl desk.u.job ~]
    (refuse:ufiles eyre-id.u.job late)
  ?.  =(%verify i.t.t.wire)  `[~ current]
  ?.  ?=([%clay %writ *] sign-arvo)  `[~ current]
  =/  =riot:clay  +.+.sign-arvo
  =/  rest=card:agent:gall  [%pass timeout %arvo %b %rest until.u.job]
  :-  ~
  :_  ~
  :-  rest
  ?:  &(?=(^ riot) =(q.q.r.u.riot expect.u.job))
    =/  wire-path=path  [desk.u.job %now tar.u.job]
    %+  reply:ufiles  eyre-id.u.job
    (ok-json:ufiles ~[['path' a+(turn wire-path |=(s=@ta s+s))]])
  %+  refuse:ufiles  eyre-id.u.job
  (fail:ufiles %internal 500 'the uploaded file did not read back intact')
::
++  wires
  |=  id=@ta
  ^-  [verify=wire write=wire timeout=wire]
  [/upload/[id]/verify /upload/[id]/write /upload/[id]/timeout]
::
::  +|  Downloads
::
++  export
  ::  A file's external form, for a download or a preview; ~ when it is
  ::  absent, tombstoned, or has no form heathcliff can build safely.
  ::
  ::    Old revisions convert with the current mark: clay's %c scries do
  ::    not reach back in time.
  |=  [=bowl:gall =beak pax=path]
  ^-  (unit mime)
  ?:  =(~ pax)  ~
  =/  full=path  (en-beam beak pax)
  =/  =arch  .^(arch %cy full)
  ?~  fil.arch  ~
  ?.  (live:hc bowl full)  ~
  =/  =mark  (rear pax)
  ?:  =(%mime mark)  ((soft mime) .^(* %cq full))
  ?.  ?&  (~(has in casts:hc) mark)
          (has-file:hc bowl q.beak /mar/[mark]/hoon)
      ==
    (raw mark .^(* %cq full))
  =/  got=(each mime tang)
    %-  mule  |.
    =/  =tube:clay
      .^(tube:clay %cc (tube-path:ufiles bowl q.beak mark %mime))
    !<(mime (tube .^(vase %cr full)))
  ?:  ?=(%& -.got)  `p.got
  (raw mark .^(* %cq full))
::
++  raw
  ::  An atom-shaped file served as it is stored.
  |=  [=mark dat=*]
  ^-  (unit mime)
  ?^  dat  ~
  `[(fall (ctype:hc mark) /application/octet-stream) (met 3 dat) dat]
::
++  payload
  ::  A file's response: inline for a preview, an attachment for a
  ::  download.
  ::
  ::    Never sniffed, and sandboxed, so no stored HTML, SVG or script
  ::    runs as a heathcliff page.  A PDF previews unsandboxed, since a
  ::    sandbox blocks the browser's viewer; it runs no page script.
  |=  [pax=path =mime attach=?]
  ^-  simple-payload:http
  =/  =mark  (rear pax)
  =/  type=mite  ?:(=(%mime mark) p.mime (fall (ctype:hc mark) p.mime))
  =/  name=@t  (filename pax mime)
  =/  pdf=?  =(/application/pdf type)
  =/  headers=header-list:http
    ;:  weld
      :~  ['content-type' (en-mite:mimes:html type)]
          ['x-content-type-options' 'nosniff']
          ['cache-control' 'private, no-store']
          ['referrer-policy' 'no-referrer']
      ==
      ?:  &(pdf !attach)  ~
      ~[['content-security-policy' csp]]
      ?.  attach  ~
      ~[['content-disposition' (rap 3 'attachment; filename="' name '"' ~)]]
    ==
  [[200 headers] `q.mime]
::
++  csp
  ::  No script, no network beyond our own media, in an opaque origin.
  ^-  @t
  %+  rap  3
  :~  'sandbox; default-src \'none\'; img-src \'self\' data:; '
      'media-src \'self\'; style-src \'unsafe-inline\''
  ==
::
++  filename
  ::  name.ext for a download: the mark, except a %mime file takes the
  ::  extension of its stored type and a %noun downloads as jam.
  |=  [pax=path =mime]
  ^-  @t
  =/  name=@ta  ?:((gte (lent pax) 2) (snag (sub (lent pax) 2) pax) %file)
  =/  =mark  (rear pax)
  =/  ext=@ta
    ?+  mark  mark
      %noun  %jam
      %mime  (fall (extension p.mime) %bin)
    ==
  (rap 3 name '.' ext ~)
::
++  extension
  ::  The usual extension of a content type, among the marks heathcliff
  ::  knows.
  |=  type=mite
  ^-  (unit @ta)
  =/  known=(list mark)
    :~  %png  %jpg  %gif  %svg  %webp  %bmp  %ico  %tiff  %txt  %html
        %css  %js  %json  %xml  %csv  %md  %pdf  %mp3  %wav  %ogg  %flac
        %aac  %mp4  %webm  %mpeg  %ttf  %otf  %woff2  %wasm
    ==
  |-  ^-  (unit @ta)
  ?~  known  ~
  ?:  =(`type (ctype:hc i.known))  `i.known
  $(known t.known)
--
