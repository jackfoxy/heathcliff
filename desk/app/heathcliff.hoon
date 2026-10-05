::  heathcliff: clay exposed
::
::    Browse, edit, download and upload the files of every desk, and
::    manage their permissions, in urui's three-pane workbench.  This is
::    the Gall boundary only: routes, authentication, cards and signs.
::    The libraries do the rest.
::
/+  server, dbug, verb, default-agent, multipart
/+  uhttp=urui-http, ufiles=urui-files
/+  hp=heathcliff-perm, ht=heathcliff-transfer, ha=heathcliff-api
/+  hc=heathcliff-clay, web=heathcliff-web
/*  fav         %png  /favicon/png
/*  logo        %png  /heathcliff/png
/*  ace-core    %js   /web/ace/ace/js
/*  ace-light   %js   /web/ace/theme-github/js
/*  ace-dark    %js   /web/ace/theme-monokai/js
/*  ace-beaut   %js   /web/ace/ext-beautify/js
/*  ace-prompt  %js   /web/ace/ext-prompt/js
/*  ace-search  %js   /web/ace/ext-searchbox/js
/*  ace-sets    %js   /web/ace/ext-settings-menu/js
/*  ace-vim     %js   /web/ace/keybinding-vim/js
/*  ace-lic     %txt  /web/ace/license/txt
::
|%
::  +|  State
::
::    state-0: posts pending a response; never written in practice.
::    state-1: the crew mirror (see /lib/heathcliff-perm).
::    state-2: the mirror, and the one file change and one upload that
::             await clay.  Neither pending change is saved: an in-flight
::             request does not survive a reload.
::
+$  state-0  [%0 pend=(map @ta *)]
+$  state-1  [%1 cez=crews:hp use=usage:hp]
+$  state-2
  $:  %2
      cez=crews:hp
      use=usage:hp
      files=(unit pending:ufiles)
      load=(unit pending:ht)
  ==
+$  versioned-state  $%(state-0 state-1 state-2)
+$  card  card:agent:gall
::
::  +|  Assets
::
++  assets
  ^-  (list [suffix=@t asset=asset:uhttp])
  =/  js=@t  'text/javascript; charset=utf-8'
  =/  text=@t  'text/plain; charset=utf-8'
  %+  turn
    :~  ['/app.js' js javascript:web]
        ['/app.css' 'text/css; charset=utf-8' css:web]
        ['/ace/ace.js' js ace-core]
        ['/ace/heathcliff-config.js' js ace-config-js:web]
        ['/ace/theme-github.js' js ace-light]
        ['/ace/theme-monokai.js' js ace-dark]
        ['/ace/ext-beautify.js' js ace-beaut]
        ['/ace/ext-prompt.js' js ace-prompt]
        ['/ace/ext-searchbox.js' js ace-search]
        ['/ace/ext-settings_menu.js' js ace-sets]
        ['/ace/keybinding-vim.js' js ace-vim]
        ['/ace/license.txt' text (of-wain:format ace-lic)]
    ==
  |=  [suffix=@t content-type=@t body=@t]
  [suffix content-type (as-octs:mimes:html body)]
::
++  give
  |=  [eyre-id=@ta =simple-payload:http]
  ^-  (list card)
  (give:uhttp eyre-id simple-payload)
::
++  refused
  ::  The 401 every data route answers without a session.
  |=  eyre-id=@ta
  ^-  (list card)
  %+  refuse:ufiles  eyre-id
  (fail:ufiles %unauthorized 401 'authentication required')
::
++  empty-browse
  ::  A browse of the namespace root, which names no desk.
  ::
  ::    urui's file dialog lists a root's scope before a draft's first
  ::    save; heathcliff's root scope is every desk, so it lists nothing
  ::    and the path is typed as desk/now/folder/name.mark.
  |=  req=inbound-request:eyre
  ^-  ?
  ?~  body.request.req  |
  =/  jon=(unit json)  (de:json:html q.u.body.request.req)
  ?.  ?=([~ %o *] jon)  |
  ?&  =(`s+'browse' (~(get by p.u.jon) 'op'))
      =(`a+~ (~(get by p.u.jon) 'scope'))
  ==
::
++  raw
  ::  A file's bytes for a preview, or with `?download` an attachment.
  |=  [=bowl:gall pax=(list @t) args=(list [key=@t value=@t])]
  ^-  simple-payload:http
  =/  missing=simple-payload:http
    [[404 ~] `(as-octs:mimes:html 'file not found')]
  =/  wire=(unit path)
    ?.  (levy pax |=(s=@t (valid-segment:ufiles | s)))  ~
    `(turn pax |=(s=@t `@ta`s))
  ?~  wire  missing
  =/  where=(each location:ufiles failure:ufiles)  (locate:hc bowl u.wire)
  ?:  ?=(%| -.where)  missing
  =/  out=(unit mime)  (export:ht bowl beak.p.where rel.p.where)
  ?~  out  missing
  =/  attach=?  (lien args |=([key=@t *] =('download' key)))
  (payload:ht rel.p.where u.out attach)
::
++  upload
  ::  A multipart upload into `dir` on `desk`, verified before it is
  ::  answered.
  |=  $:  =bowl:gall
          eyre-id=@ta
          desk=@t
          dir=(list @t)
          req=inbound-request:eyre
          load=(unit pending:ht)
      ==
  ^-  (quip card (unit pending:ht))
  =/  no
    |=  =failure:ufiles
    ^-  (quip card (unit pending:ht))
    [(refuse:ufiles eyre-id failure) load]
  ?.  =(%'POST' method.request.req)
    (no (fail:ufiles %bad-request 405 'method not allowed'))
  ?.  (levy dir |=(s=@t (valid-segment:ufiles | s)))
    (no (fail:ufiles %invalid-path 400 'invalid directory'))
  =/  parts=(unit (list [@t part:multipart]))
    (de-request:multipart [header-list body]:request.req)
  ?~  parts
    (no (fail:ufiles %bad-request 400 'expected a multipart/form-data upload'))
  =/  form=(map @t part:multipart)  (malt u.parts)
  =/  file=(unit part:multipart)  (~(get by form) 'file')
  ?~  file  (no (fail:ufiles %bad-request 400 'no file was submitted'))
  ?~  file.u.file  (no (fail:ufiles %bad-request 400 'the file has no name'))
  =/  done=outcome:ht
    %:  commit:ht
      bowl  eyre-id  `@tas`desk  (turn dir |=(s=@t `@ta`s))
      u.file.u.file  type.u.file  size.u.file  body.u.file
      (~(has by form) 'marks')  (~(has by form) 'overwrite')  load
    ==
  [cards.done next.done]
--
::
=|  state-2
=*  state  -
::
%-  agent:dbug
%+  verb  |
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  [[%pass /eyre/connect %arvo %e %connect [~ /[dap.bowl]] dap.bowl] mirror:hp]
::
++  on-save  !>(state(files ~, load ~))
::
++  on-load
  ::  Every version keeps its crew mirror, if it has one, and refreshes it.
  |=  ole=vase
  ^-  (quip card _this)
  =/  old=versioned-state  !<(versioned-state ole)
  =/  new=state-2
    ?-  -.old
      %0  [%2 ~ ~ ~ ~]
      %1  [%2 cez.old use.old ~ ~]
      %2  old(files ~, load ~)
    ==
  [mirror:hp this(state new)]
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?.  =(%handle-http-request mark)  (on-poke:def mark vase)
  =+  !<([eyre-id=@ta req=inbound-request:eyre] vase)
  =/  line=request-line:server  (parse-request-line:server url.request.req)
  =/  site=(list @t)
    ?~  ext.line  site.line
    ::  =(~ ...), not ?~: a narrowed list breaks +snip's ^+ product
    ?:  =(~ site.line)  ~
    (snoc (snip site.line) (rap 3 (rear site.line) '.' u.ext.line ~))
  ?.  ?=([%heathcliff *] site)
    [(give eyre-id [[404 ~] `(as-octs:mimes:html 'not found')]) this]
  =/  rest=(list @t)  t.site
  =/  method=@t  method.request.req
  ::  the page needs a session; its assets carry nothing private
  ?:  &(=(%'GET' method) ?=(?(~ [%$ ~]) rest))
    ?.  authenticated.req
      =/  to=@t  (cat 3 '/~/login?redirect=' url.request.req)
      [(give eyre-id [[307 ['location' to]~] ~]) this]
    =/  page=asset:uhttp
      ['text/html; charset=utf-8' (as-octs:mimes:html page:web)]
    [(give eyre-id (respond:uhttp 200 page)) this]
  ?:  &(=(%'GET' method) =(~[%'favicon.png'] rest))
    [(give eyre-id (respond:uhttp 200 ['image/png' [(met 3 fav) fav]])) this]
  ::  the docket tile's image
  ?:  &(=(%'GET' method) =(~[%'heathcliff.png'] rest))
    [(give eyre-id (respond:uhttp 200 ['image/png' [(met 3 logo) logo]])) this]
  ?:  =(%'GET' method)
    ?:  ?=([%raw *] rest)
      ?.  authenticated.req  [(refused eyre-id) this]
      [(give eyre-id (raw bowl t.rest args.line)) this]
    =/  found  (asset-route:uhttp '/heathcliff' url.request.req assets)
    ?~  found
      [(give eyre-id [[404 ~] `(as-octs:mimes:html 'not found')]) this]
    [(give eyre-id (respond:uhttp 200 u.found)) this]
  ?.  authenticated.req  [(refused eyre-id) this]
  ?:  =(~[%files] rest)
    ?:  (empty-browse req)
      [(reply:ufiles eyre-id (ok-json:ufiles ~[['entries' a+~]])) this]
    =^  cards  files.state
      (handle:ufiles file-policy:web bowl eyre-id req files.state)
    [cards this]
  ?:  =(~[%api] rest)
    [(handle:ha bowl eyre-id req cez.state use.state) this]
  ?:  ?=([%upload @ %now *] rest)
    =^  cards  load.state
      (upload bowl eyre-id i.t.rest t.t.t.rest req load.state)
    [cards this]
  [(give eyre-id [[404 ~] `(as-octs:mimes:html 'not found')]) this]
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ::NOTE  no =(our src) assertion: eyre subscribes for the requester's
  ::      identity, a synthesized comet when logged out, and asserting
  ::      would 500 every unauthenticated request before it is refused.
  ?+  path  (on-watch:def path)
    [%http-response *]  [~ this]
  ==
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?:  ?=([%eyre %connect ~] wire)
    ?>  ?=([%eyre %bound *] sign-arvo)
    ~?  !accepted.sign-arvo
      [dap.bowl 'eyre bind rejected!' binding.sign-arvo]
    [~ this]
  ::  the crew mirror: %cruz carries every crew; %croz carries a crew's
  ::  usage but not its name, so the name rides on the wire
  ?:  ?=([%perm %crew ~] wire)
    ?>  ?=([%clay %cruz *] sign-arvo)
    :_  this(cez cez.sign-arvo, use ~)
    %+  turn  ~(tap in ~(key by `crews:hp`cez.sign-arvo))
    |=(nom=@ta ^-(card [%pass /perm/crow/[nom] %arvo %c %crow nom]))
  ?:  ?=([%perm %crow @ ~] wire)
    ?>  ?=([%clay %croz *] sign-arvo)
    [~ this(use (~(put by use) i.t.t.wire rus.sign-arvo))]
  =/  file=(unit outcome:ufiles)
    (take:ufiles file-policy:web bowl wire sign-arvo files.state)
  ?^  file
    =.  files.state  next.u.file
    [cards.u.file this]
  =/  sent=(unit outcome:ht)  (take:ht bowl wire sign-arvo load.state)
  ?^  sent
    =.  load.state  next.u.sent
    [cards.u.sent this]
  (on-arvo:def wire sign-arvo)
::
++  on-leave  on-leave:def
++  on-agent  on-agent:def
++  on-peek   on-peek:def
++  on-fail   on-fail:def
--
