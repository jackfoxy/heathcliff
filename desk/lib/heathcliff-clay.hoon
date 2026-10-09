::  heathcliff-clay: desks, marks, and file locations
::
::    A heathcliff document is the wire path [desk case ...clay-path].
::    `case` is `now`, the live and writable head of that desk, or a
::    revision number, a read-only snapshot of that desk alone; a
::    revision never travels to another desk.
::
/-  dock=docket
/+  ufiles=urui-files
|%
::  +|  Types
::
+$  root  [=desk title=@t rev=@ud]
::
::  +|  Constants
::
++  limit
  ::  Largest upload: 8MiB, so a stray POST cannot commit something
  ::  enormous into a desk.
  (bex 23)
::
++  dump-max
  ::  Bytes shown in a hex dump.
  4.096
::
++  view-max
  ::  Characters of read-only inspection text.
  65.536
::
++  codecs
  ::  Marks heathcliff edits as text, and how their nouns read.
  ::
  ::    Every other mark takes the %view fallback: read-only, inspected
  ::    by +inspect.  bill, docket-0, kelvin and ship hold structured
  ::    nouns, edited through their own mime conversion.  md is a wain
  ::    on %base but a cord on desks %docs serves, so it goes through
  ::    the mark on the file's own desk too.
  ^-  (list [mark=@tas =codec:ufiles])
  :~  [%txt %wain]  [%csv %wain]  [%tab %wain]  [%pem %wain]
      [%hoon %cord]  [%css %cord]  [%js %cord]  [%html %cord]
      [%svg %cord]  [%xml %cord]  [%udon %cord]  [%umd %cord]
      [%map %cord]  [%json %json]
      [%bill %mime]  [%docket-0 %mime]  [%kelvin %mime]  [%ship %mime]
      [%md %mime]
  ==
::
++  ctype
  ::  The content type of a mark's external form, where it is known.
  ::
  ::    Used for downloads and previews.  A mark absent here downloads
  ::    with the type its own +grow mime gives.
  |=  =mark
  ^-  (unit mite)
  ?+  mark  ~
    %txt    `/text/plain
    %hoon   `/text/x-hoon
    %css    `/text/css
    %js     `/text/javascript
    %json   `/application/json
    %html   `/text/html
    %hymn   `/text/html
    %urb    `/text/html
    %snip   `/text/html
    %xml    `/text/xml
    %csv    `/text/csv
    %tab    `/text/tab-separated-values
    %md     `/text/markdown
    ::  '+' is not a knot character, so this cannot be a path literal
    %svg    [~ `mite`~['image' 'svg+xml']]
    %png    `/image/png
    %jpg    `/image/jpeg
    %jpeg   `/image/jpeg
    %gif    `/image/gif
    %bmp    `/image/bmp
    %ico    `/image/x-icon
    %tiff   `/image/tiff
    %webp   `/image/webp
    %mp3    `/audio/mpeg
    %wav    `/audio/wav
    %ogg    `/audio/ogg
    %oga    `/audio/ogg
    %flac   `/audio/flac
    %aac    `/audio/aac
    %weba   `/audio/webm
    %mid    `/audio/midi
    %mp4    `/video/mp4
    %mov    `/video/quicktime
    %webm   `/video/webm
    %ogv    `/video/ogg
    %mpeg   `/video/mpeg
    %avi    `/video/x-msvideo
    %ttf    `/font/ttf
    %otf    `/font/otf
    %woff2  `/font/woff2
    %pdf    `/application/pdf
    %pem    `/application/x-pem-file
    %wasm   `/application/wasm
    %jam    `/application/x-urb-jam
    %noun   `/application/x-urb-jam
  ==
::
++  casts
  ::  Marks whose +grow mime heathcliff will build.
  ::
  ::    Clay offers no way to ask whether a conversion exists short of
  ::    building it, and a failed build crashes beyond +mule, so this
  ::    is an allowlist.  Covers %base and %yard as of 408K.
  ^-  (set mark)
  %-  silt
  ^-  (list mark)
  :~  %aac  %atom  %avi  %bill  %bmp  %css  %csv  %docket-0  %flac  %gif
      %hoon  %html  %hymn  %ico  %jam  %jpeg  %jpg  %js  %json  %kelvin
      %map  %md  %mid  %mov  %mp3  %mp4  %mpeg  %noun  %oga  %ogg  %ogv  %otf
      %pdf  %pem  %png  %ship  %snip  %story  %svg  %tab  %tiff  %ttf
      %txt  %udon  %umd  %urb  %wasm  %wav  %weba  %webm  %webp  %woff2
      %xml
  ==
::
++  grabs
  ::  Marks with a +grab mime, so an upload can be converted into them.
  ::
  ::    %mime needs no conversion.  hymn, jam, noun, snip, txt-diff and
  ::    urb have no +grab mime and cannot be uploaded.
  ^-  (set mark)
  %-  silt
  ^-  (list mark)
  :~  %aac  %atom  %avi  %bill  %bmp  %css  %csv  %docket-0  %flac  %gif
      %hoon  %html  %ico  %jpeg  %jpg  %js  %json  %kelvin  %map  %md
      %mid  %mov  %mp3  %mp4  %mpeg  %oga  %ogg  %ogv  %otf  %pdf  %pem  %png
      %ship  %svg  %tab  %tiff  %ttf  %txt  %udon  %umd  %wav  %weba
      %webm  %webp  %woff2  %xml
  ==
::
++  octs-marks
  ::  Marks that keep a byte length, so trailing NUL bytes survive.
  ::
  ::    Every other byte mark stores a bare atom, which has no high
  ::    zeros: its +grow recomputes the length with +met.
  ^-  (set mark)
  (silt `(list mark)`~[%mime %mov %otf %ttf %woff2])
::
::  +|  Paths
::
++  here
  ::  The scry prefix of `desk` at now.
  |=  [=bowl:gall =desk]
  ^-  path
  /(scot %p our.bowl)/[desk]/(scot %da now.bowl)
::
++  case-seg
  ::  The wire segment of a case: `now`, or the revision number.
  |=  [=bowl:gall =case]
  ^-  @ta
  ?:  =(da+now.bowl case)  %now
  ?>  ?=(%ud -.case)
  (crip (a-co:co p.case))
::
++  read-case
  ::  The case a wire segment names on a desk whose head is `head`.
  |=  [=bowl:gall seg=@ta head=@ud]
  ^-  (unit case)
  ?:  =(%now seg)  `da+now.bowl
  =/  num=(unit @ud)  (rush seg dem)
  ?~  num  ~
  ?.  &((gth u.num 0) (lte u.num head))  ~
  `ud+u.num
::
++  wire-path
  ::  The wire path of `pax` on `beak`.
  |=  [=bowl:gall =beak pax=path]
  ^-  path
  [q.beak (case-seg bowl r.beak) pax]
::
::  +|  Clay
::
++  desks
  ::  Every desk on this ship.
  ::
  ::    Pinned to now: clay's empty-desk fast path applies only there,
  ::    and the desk list belongs to the ship, not to a revision.
  |=  =bowl:gall
  ^-  (set desk)
  .^((set desk) %cd ~[(scot %p our.bowl) %$ (scot %da now.bowl)])
::
++  head-rev
  |=  [=bowl:gall =desk]
  ^-  @ud
  ud:.^(cass:clay %cw (here bowl desk))
::
++  has-file
  ::  Does `desk` hold a file at `pax` now?
  |=  [=bowl:gall =desk pax=path]
  ^-  ?
  .^(? %cu (weld (here bowl desk) pax))
::
++  live
  ::  Is the file at the full beam path `pax` still readable?
  ::
  ::    A tombstoned file keeps its place in %cy, but %cx or %cq on it
  ::    crashes the whole event, beyond +mule; ask before reading.
  |=  [=bowl:gall pax=path]
  ^-  ?
  .^(? %cx (weld ~[(scot %p our.bowl) %$ (scot %da now.bowl) %tomb] pax))
::
++  tombed
  ::  Is there a file at `pax` on `beak` whose data is gone?
  |=  [=bowl:gall =beak pax=path]
  ^-  ?
  =/  full=path  (en-beam beak pax)
  =/  =arch  .^(arch %cy full)
  ?~  fil.arch  |
  !(live bowl full)
::
++  title
  ::  The desk's docket title, or its name when it has none.
  ::
  ::    Read typelessly from /desk/docket-0, so neither the docket agent
  ::    nor the desk's own docket mark need be present.
  |=  [=bowl:gall =desk]
  ^-  @t
  =/  pax=path  (weld (here bowl desk) /desk/docket-0)
  ?.  .^(? %cu pax)  desk
  ?.  (live bowl pax)  desk
  =/  got=(each @t tang)
    (mule |.(title:;;(docket:dock .^(* %cq pax))))
  ?:  ?=(%| -.got)  desk
  ?:(=('' p.got) desk p.got)
::
++  roots
  ::  Every desk as an explorer root, by title regardless of case, then
  ::  by desk name.
  |=  =bowl:gall
  ^-  (list root)
  =/  all=(list root)
    %+  turn  ~(tap in (desks bowl))
    |=(=desk ^-(root [desk (title bowl desk) (head-rev bowl desk)]))
  (sort all order)
::
++  order
  ::  Roots by title regardless of case, then by desk name.
  |=  [a=root b=root]
  ^-  ?
  =/  x=@t  (crip (cass (trip title.a)))
  =/  y=@t  (crip (cass (trip title.b)))
  ?.  =(x y)  (aor x y)
  (aor desk.a desk.b)
::
++  listing
  ::  Every file at or under `scope` on `beak`, as full clay paths.
  ::
  ::    %ct is answered out of the yaki at the asked revision, so it is
  ::    safe on old cases.  An empty desk off now is a tang.
  |=  [=beak scope=path]
  ^-  (each (list path) tang)
  (mule |.(.^((list path) %ct (en-beam beak scope))))
::
++  locate
  ::  The clay location of a wire path, for urui-files.
  ::
  ::    The desk must exist; `now` is writable, a revision of that desk
  ::    is not.  A tombstoned file is refused here, so no reader ever
  ::    scries its data.
  |=  [=bowl:gall rel=path]
  ^-  (each location:ufiles failure:ufiles)
  ?.  ?=([@ @ *] rel)
    [%| (fail:ufiles %invalid-path 400 'a path names its desk and case')]
  =/  =desk  i.rel
  ?.  (~(has in (desks bowl)) desk)
    [%| (fail:ufiles %not-found 404 'no such desk')]
  =/  cas=(unit case)  (read-case bowl i.t.rel (head-rev bowl desk))
  ?~  cas  [%| (fail:ufiles %not-found 404 'no such revision of that desk')]
  =/  =beak  [our.bowl desk u.cas]
  ?:  (tombed bowl beak t.t.rel)
    [%| (fail:ufiles %not-found 404 'this file\'s data has been tombstoned')]
  [%& beak t.t.rel =(da+now.bowl u.cas)]
::
::  +|  Marks
::
++  kin
  ::  The marks a mark needs in order to build, dependencies first.
  ::
  ::    A mark written `++grad %foo` delegates its diff to mark %foo,
  ::    and clay builds %foo to build it, so installing one installs
  ::    the other.  An inline ++grad core is terminal even when its
  ::    ++form names a mark: %txt says `++form %txt-diff` but builds
  ::    without mar/txt-diff.  Every chain here is one deep.
  |=  =mark
  ^-  (list ^mark)
  ?+  mark  ~[%mime mark]
    ?(%mime %noun %txt)                                ~[mark]
    ?(%bill %docket-0 %hymn %kelvin %ship %snip %urb)  ~[%noun mark]
    %txt-diff                                          ~[%noun mark]
    ?(%hoon %udon %umd)                                ~[%txt mark]
  ==
::
++  missing
  ::  Which of a mark's build dependencies `desk` lacks now.
  |=  [=bowl:gall =desk =mark]
  ^-  (list ^mark)
  (skip (kin mark) |=(m=^mark (has-file bowl desk /mar/[m]/hoon)))
::
++  source
  ::  Where an install takes a mark's source: %base when it has the
  ::  mark, else heathcliff's own desk; ~ when neither does.
  |=  [=bowl:gall =mark]
  ^-  (unit [from=desk src=@t])
  =/  pax=path  /mar/[mark]/hoon
  =/  from=(unit desk)
    ?:  (has-file bowl %base pax)  `%base
    ?:  (has-file bowl q.byk.bowl pax)  `q.byk.bowl
    ~
  ?~  from  ~
  `[u.from .^(@t %cx (weld (here bowl u.from) pax))]
::
++  safe
  ::  Arbitrary text as a path element: lowercase, digits, hyphens.
  |=  t=@t
  ^-  @ta
  %-  crip
  %+  turn  (trip t)
  |=  c=@tD
  ^-  @tD
  ?:  &((gte c 'A') (lte c 'Z'))  (add c 32)
  ?:  ?|  &((gte c 'a') (lte c 'z'))
          &((gte c '0') (lte c '9'))
          =('-' c)
      ==
    c
  '-'
::
++  splt
  ::  A filename as [name mark] clay path elements.
  ::
  ::    Clay has no extensions: foo.png is the file /foo/png, whose mark
  ::    is png, so a file without one has no mark to be written under.
  |=  fil=@t
  ^-  (unit [nam=@ta =mark])
  =/  t=tape  (trip fil)
  ?~  dex=(find "." (flop t))  ~
  =/  cut=@ud  (sub (lent t) +(u.dex))
  =/  nam=@ta  (safe (crip (scag cut t)))
  =/  ext=@ta  (safe (crip (slag +(cut) t)))
  ?:  |(=('' ext) =('' nam))  ~
  `[nam ext]
::
::  +|  Inspection
::
++  inspect
  ::  Read-only text for a file heathcliff does not edit as text.
  ::
  ::    Bytes are summarized, and dumped when they have no richer form;
  ::    known structures are printed; anything else is a bounded noun.
  ::    The output is bounded by +view-max.
  |=  [=mark stored=*]
  ^-  @t
  =/  out=wain
    ?+  mark  (fallback mark stored)
        ?(%png %jpg %jpeg %gif %bmp %ico %tiff %webp)
      (media mark stored "image")
    ::
        ?(%mp3 %wav %ogg %oga %flac %aac %weba %mid)
      (media mark stored "audio")
    ::
        ?(%mov %mp4 %webm %ogv %mpeg %avi)
      (media mark stored "video")
    ::
        %pdf
      (media mark stored "document")
    ::
        ?(%otf %ttf %woff2)
      =/  got=(unit octs)  ((soft octs) stored)
      ?~  got  (fallback mark stored)
      :~  (crip "%{(trip mark)} font, {(a-co:co p.u.got)} bytes.")
          'Its specimen is in the result pane.'
      ==
    ::
        ?(%atom %jam)
      ?^  stored  (fallback mark stored)
      :-  (crip "%{(trip mark)}, {(a-co:co (met 3 stored))} bytes.")
      ['' (dump stored (met 3 stored))]
    ::
        %mime
      =/  got=(unit mime)  ((soft mime) stored)
      ?~  got  (fallback mark stored)
      :*  (crip "type: {(trip (en-mite:mimes:html p.u.got))}")
          (crip "length: {(a-co:co p.q.u.got)} bytes")
          ''
          (dump q.q.u.got p.q.u.got)
      ==
    ::
        ?(%hymn %urb)
      =/  got=(unit manx)  ((soft manx) stored)
      ?~  got  (fallback mark stored)
      (to-wain:format (crip (en-xml:html u.got)))
    ::
        %snip
      =/  got=(unit [hed=marl tal=marl])  ((soft ,[marl marl]) stored)
      ?~  got  (fallback mark stored)
      =/  both=manx  ;div:(div:"*{hed.u.got}" div:"*{tal.u.got}")
      (to-wain:format (crip (en-xml:html both)))
    ::
        %txt-diff
      =/  got=(unit (urge:clay cord))  ((soft (urge:clay cord)) stored)
      ?~  got  (fallback mark stored)
      (hunks u.got)
    ==
  =/  text=@t  (of-wain:format out)
  ?:  (lte (met 3 text) view-max)  text
  (cat 3 (end [3 view-max] text) '\0a… truncated')
::
++  media
  ::  A summary line for a byte file whose preview the result pane draws.
  |=  [=mark stored=* kind=tape]
  ^-  wain
  =/  size=(unit @ud)
    ?@  stored  `(met 3 stored)
    ?.  (~(has in octs-marks) mark)  ~
    =/  bytes=(unit octs)  ((soft octs) stored)
    ?~  bytes  ~
    `p.u.bytes
  ?~  size  (fallback mark stored)
  :~  (crip "%{(trip mark)} {kind}, {(a-co:co u.size)} bytes.")
      'Its preview is in the result pane; Download saves the file.'
  ==
::
++  fallback
  ::  Any other noun: text when it is valid UTF-8, else a hex dump of
  ::  an atom, else a bounded print.
  |=  [=mark stored=*]
  ^-  wain
  ?@  stored
    ?:  ((sane %t) stored)
      :-  (crip "%{(trip mark)}, stored as text:")
      ['' (to-wain:format stored)]
    :-  (crip "%{(trip mark)}, {(a-co:co (met 3 stored))} bytes.")
    ['' (dump stored (met 3 stored))]
  =/  printed=tape  (noah !>(stored))
  :-  (crip "%{(trip mark)}, a noun:")
  ['' (crip (scag view-max printed)) ~]
::
++  hunks
  ::  A clay text diff, hunk by hunk.
  |=  dif=(urge:clay cord)
  ^-  wain
  %-  zing
  %+  turn  dif
  |=  hun=(unce:clay cord)
  ^-  wain
  ?-  -.hun
      %&
    =/  plural=tape  ?:(=(1 p.hun) "" "s")
    [(crip "= {(a-co:co p.hun)} unchanged line{plural}") ~]
  ::
      %|
    %+  weld
      (turn p.hun |=(l=cord (cat 3 '- ' l)))
    (turn q.hun |=(l=cord (cat 3 '+ ' l)))
  ==
::
++  dump
  ::  A hex dump of the first +dump-max bytes of `len` bytes of `dat`.
  |=  [dat=@ len=@ud]
  ^-  wain
  =/  cap=@ud  (min len dump-max)
  =/  at=@ud  0
  =|  out=wain
  |-  ^-  wain
  ?:  (gte at cap)
    =?  out  (gth len cap)
      [(crip "… {(a-co:co (sub len cap))} more bytes") out]
    (flop out)
  =/  n=@ud  (min 16 (sub cap at))
  =/  bytes=(list @)
    (turn (gulf 0 (dec n)) |=(i=@ud (cut 3 [(add at i) 1] dat)))
  =/  hex=tape
    (zing (turn bytes |=(b=@ `tape`(weld ((x-co:co 2) b) " "))))
  =/  pad=tape  (reap (mul 3 (sub 16 n)) ' ')
  =/  asc=tape
    (turn bytes |=(b=@ `@tD`?:(&((gte b 32) (lth b 127)) b '.')))
  =/  row=tape  :(weld ((x-co:co 8) at) "  " hex pad " |" asc "|")
  $(at (add at n), out [(crip row) out])
--
