::  heathcliff-web: the page, its styles, and its script
::
::    urui owns the frame, panes, tabs, editor, file lifecycle, menus and
::    dialogs.  Heathcliff draws the Apps and Data trees into the views
::    urui seeds, renders the result pane and attribute reference tabs, and runs
::    upload dialogs on urui's modal controller.
::
/-  urui
/+  shell=urui-shell, ucss=urui-css, uace=urui-ace
/+  ucfg=urui-config, ujs=urui-js, ufiles=urui-files
/+  hc=heathcliff-clay
|%
++  base  '/heathcliff'
::
++  config
  ^-  app-config:urui
  :*  :*  name=%heathcliff
          title='Heathcliff'
          base=base
          storage-key='heathcliff.session'
          storage-version=1
      ==
      :*  render-debounce=250
          save-debounce=150
          min-explorer=220
          divider=10
          pane-min=25
          pane-max=75
          max-source=1.048.576
      ==
      slots
      shortcuts
      :~  [%ready 'Ready']
          [%loading 'Loading']
          [%empty 'Nothing selected']
          [%error 'Error']
      ==
      docs-root=`'/docs/d/heathcliff/'
      ace-spec
      layout=%columns
      collapse=|
      files=`files
      tips=~
  ==
::
++  files
  ::  One store for every file on every desk: the path is
  ::  [desk case ...clay-path], admitted by one root that takes any mark.
  ^-  files:urui
  :*  url='/heathcliff/files'
      :~  :*  name=%clay
              noun='File'
              untitled='new file'
              starter=''
              roots=~[[~ ~ ~ &]]
              preview=~
              actions=~[%save %copy]
              refs=|
              share=~
          ==
      ==
      ~
  ==
::
++  file-policy
  ::  Text marks by codec, everything else read-only; paths located by
  ::  +locate:hc on any desk and case.
  ^-  policy:ufiles
  =/  made=policy:ufiles  (make-policy:ufiles files ~ |)
  %=  made
    codecs         codecs:hc
    fallback       `%view
    locate         `locate:hc
    view           `inspect:hc
    edit-snapshots  &
    max-bytes      (add limit:hc 65.536)
  ==
::
++  slots
  ^-  (list slot:urui)
  :~  ['paneBands' %urui %record ~]
      ['paneWidth' %urui %scalar ~]
      ['paneHeight' %urui %scalar ~]
      ['explorerWidth' %urui %scalar ~]
      ['explorerOpen' %urui %scalar ~]
      ['resultOpen' %urui %scalar ~]
      ['explorerView' %urui %scalar ~]
      ['explorerOrder' %urui %scalar ~]
      ['docsTabs' %urui %tabs ~]
      ['nextDocs' %urui %next ~]
      ['clayTabs' %urui %tabs `%clay]
      ['activeClayTabId' %urui %active `%clay]
      ['nextClayTab' %urui %next `%clay]
      ['heathcliffTrees' %app %record ~]
      ['preferences.theme' %urui %scalar ~]
      ['preferences.layout' %urui %scalar ~]
      ['preferences.keybindings' %urui %scalar ~]
      ['preferences.appsUploadRoot' %app %scalar ~]
  ==
::
++  shortcuts
  ^-  (list shortcut:urui)
  :~  ['Ctrl-S' 'save:clay' %always]
  ==
::
++  ace-spec
  ^-  ace-spec:urui
  :*  base='/heathcliff/ace'
      global='heathcliffAceAssets'
      version='1.44.0'
      mode='ace/mode/text'
      light='ace/theme/github'
      dark='ace/theme/monokai'
      :~  'ace/ext/beautify'  'ace/ext/prompt'
          'ace/ext/searchbox'  'ace/ext/settings_menu'
      ==
      use-worker=|
  ==
::
++  ace-config-js
  ^-  @t
  (config-js:uace ace-spec)
::
::  +|  The page
::
++  page
  ^-  @t
  (crip (en-xml:html (build:shell spec)))
::
++  spec
  ^-  shell-spec:urui
  :*  config
      brand
      toolbar
      [reference-pane editor-pane result-pane]
      help
      dialogs
      styles=~['/heathcliff/app.css']
      :~  '/heathcliff/ace/ace.js'
          '/heathcliff/ace/heathcliff-config.js'
          '/heathcliff/ace/theme-github.js'
          '/heathcliff/ace/ext-beautify.js'
          '/heathcliff/app.js'
      ==
      head=~[favicon]
  ==
::
++  favicon
  ^-  manx
  ;link(rel "icon", type "image/png", href "/heathcliff/favicon.png");
::
++  pinned
  ::  A band the user cannot hide.
  |=  [name=@tas item=band-item:urui]
  ^-  band:urui
  [name [key=~ open=& label=''] item]
::
++  reference-pane
  ::  Exactly two permanent views; urui draws their strip and panels,
  ::  heathcliff the trees inside them.
  ^-  pane:urui
  :*  role=%reference
      id='explorer-pane'
      label='Heathcliff explorer'
      mode=%read-only
      kind=~
      :~  %+  pinned  %tabs
          :-  %tabs
          :~  :*  name=%view
                  label='Heathcliff explorer'
                  source=%views
                  kind=~
                  fixed=~[[%apps 'Apps'] [%data 'Data']]
                  add=~
                  close=|
                  reorder=|
              ==
          ==
          (pinned %body [%panel 'explorer-body' ~ ~])
      ==
  ==
::
++  editor-pane
  ^-  pane:urui
  :*  role=%editor
      id='editor-pane'
      label='File source'
      mode=%read-write
      kind=`%clay
      :~  (pinned %head [%heading `'Source' `'source-status' ~])
          %+  pinned  %tabs
          :-  %tabs
          :~  :*  name=%document
                  label='Open files'
                  source=%documents
                  kind=`%clay
                  fixed=~
                  add=~
                  close=&
                  reorder=&
              ==
          ==
          (pinned %body [%panel 'editor-body' `clay-host ~])
      ==
  ==
::
++  clay-host
  ^-  editor:urui
  ['clay-editor' 'File source editor' 'ace/mode/text']
::
++  result-pane
  ::  Read-only: a preview or decoded view of the active file.
  ^-  pane:urui
  :*  role=%result
      id='result-pane'
      label='Result'
      mode=%read-only
      kind=~
      :~  %+  pinned  %body
          :^  %panel  'result-body'  ~
          :~  ;div#result-view.hc-result(aria-live "polite")
                ;+  %:  fullscreen-toggle:shell
                      'hc-result-fullscreen'  'result-pane'  'results'
                    ==
              ==
          ==
      ==
  ==
::
++  brand
  ^-  marl
  :~  ;div.brand
        ;h1: Heathcliff
      ==
  ==
::
++  toolbar
  ::  File transfers sit left of Settings, so this toolbar places
  ::  urui's Settings button itself.
  ^-  marl
  :~  ;nav.toolbar(aria-label "Heathcliff controls")
        ;button#hc-download-button
          =type      "button"
          =title     "Download the active file at its selected revision"
          =disabled  ""
          Download…
        ==
        ;button#hc-upload-button
          =type   "button"
          =title
            "Choose a destination and upload a file from this computer"
          Upload…
        ==
        ;+  settings-button:shell
        ;button#help(type "button", aria-expanded "false"): Help
      ==
  ==
::
++  dialogs
  ::  Upload and confirmation dialogs, and the file input Upload uses.
  ^-  marl
  :~  ;aside#hc-upload.help-panel
        =hidden           ""
        =role             "dialog"
        =aria-modal       "true"
        =aria-labelledby  "hc-upload-title"
        ;div.help-card.hc-dialog-card
          ;div.pane-header
            ;h2#hc-upload-title: Upload
          ==
          ;div#hc-upload-body.hc-dialog-body;
          ;div.dialog-actions
            ;button#hc-upload-cancel(type "button"): Cancel
            ;button#hc-upload-confirm.primary(type "button"): Upload
          ==
        ==
      ==
      ;aside#hc-tomb.help-panel
        =hidden           ""
        =role             "alertdialog"
        =aria-modal       "true"
        =aria-labelledby  "hc-tomb-title"
        =aria-describedby  "hc-tomb-message"
        ;div.help-card.hc-dialog-card
          ;div.pane-header
            ;h2#hc-tomb-title: Delete from history
          ==
          ;p#hc-tomb-message;
          ;div.dialog-actions
            ;button#hc-tomb-cancel(type "button"): Cancel
            ;button#hc-tomb-ok.danger-button(type "button"): Delete
          ==
        ==
      ==
      ;aside#hc-revision.help-panel
        =hidden           ""
        =role             "dialog"
        =aria-modal       "true"
        =aria-labelledby  "hc-revision-title"
        ;div.help-card.hc-dialog-card
          ;div.pane-header
            ;h2#hc-revision-title: Revision
          ==
          ;p#hc-revision-help.file-dialog-help;
          ;label.settings-field
            ;span.settings-label: Revision
            ;input#hc-revision-input
              =type          "text"
              =inputmode     "numeric"
              =autocomplete  "off";
          ==
          ;p#hc-revision-error.file-dialog-error(role "alert", hidden "");
          ;div.dialog-actions
            ;button#hc-revision-cancel(type "button"): Cancel
            ;button#hc-revision-ok.primary(type "button"): Browse
          ==
        ==
      ==
      ;input#hc-upload-input.hc-hidden
        =type         "file"
        =tabindex     "-1"
        =aria-hidden  "true";
  ==
::
++  help
  ^-  marl
  :~  ;div#fallback-help-content
        ;p
          ; Apps shows every desk and its whole Clay tree; Data shows
          ; each desk's /data directory only.
        ==
        ;p
          ; Open a file to edit it.  Text formats edit in the source
          ; pane; every other format opens read-only and previews in the
          ; result pane.
        ==
        ;p
          ; A desk's revision box browses older revisions. Saving an
          ; edited historical text file creates a new current version.
        ==
        ;p
          ; Right-click an item, or use its … button, for Download,
          ; Attributes…, Permissions…, Upload… and Delete.
        ==
        ;h3: Keyboard
        ;ul.shortcut-list
          ;li: Ctrl/Cmd + S: save the active file
          ;li: Shift + F10 or the context-menu key: item actions
        ==
      ==
      ;div#docs-help-content.docs-help-content(hidden "")
        ;nav#docs-help-nav.docs-help-nav(aria-label "Heathcliff documentation");
      ==
  ==
::
::  +|  Assets
::
++  css
  ^-  @t
  %+  rap  3
  :~  %-  compose:ucss
      :~  %tokens  %controls  %shell  %explorer
          %tabs  %dialogs  %responsive
      ==
      app-css
  ==
::
++  javascript
  ^-  @t
  %+  rap  3
  :~  (emit:ucfg spec)
      core:ujs
      app-js
  ==
::
++  app-css
  ^-  @t
  '''
  .hc-hidden { display: none; }
  #hc-upload-path { box-sizing: border-box; width: 100%; }
  .hc-upload-tree { max-height: 16rem; overflow: auto; margin: 0.5rem 0; }
  .hc-upload-tree summary { cursor: pointer; padding: 0.2rem; }
  .hc-upload-tree .hc-file { display: block; width: 100%; }
  .hc-tree { display: grid; gap: 0.1rem; padding: 0.25rem 0; }
  .hc-row {
    display: flex;
    align-items: center;
    gap: 0.25rem;
    min-width: 0;
  }
  .hc-row:hover { background: var(--surface-muted, rgba(127, 127, 127, 0.1)); }
  .hc-toggle, .hc-file {
    flex: 1 1 auto;
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    text-align: left;
    border: 0;
    background: transparent;
    color: inherit;
    font: inherit;
    padding: 0.15rem 0.25rem;
    cursor: pointer;
  }
  .hc-toggle::before {
    content: '▸';
    display: inline-block;
    width: 1em;
  }
  .hc-toggle[aria-expanded="true"]::before { content: '▾'; }
  .hc-file { padding-left: 1.25rem; }
  .hc-kids { padding-left: 0.85rem; }
  .hc-kids[hidden] { display: none; }
  .hc-root > .hc-row .hc-toggle { font-weight: 600; }
  .hc-desk { color: var(--muted); font-size: 0.85em; }
  .hc-case {
    display: inline-flex;
    flex: 0 0 auto;
    align-items: stretch;
    font-size: 0.85em;
  }
  .hc-case-field {
    display: inline-flex;
    align-items: center;
    box-sizing: border-box;
    border: 1px solid var(--line, #ccc);
    border-radius: 3px;
    padding: 0 0.25ch;
    font-variant-numeric: tabular-nums;
  }
  .hc-case-field:focus-within { outline: 1px solid var(--accent, #4a6da7); }
  .hc-now { color: #16a34a; flex: 0 0 auto; }
  :root[data-effective-theme='dark'] .hc-now { color: #4ade80; }
  .hc-case input {
    flex: 1 1 auto;
    min-width: 0;
    width: 0;
    border: 0;
    padding: 0;
    background: transparent;
    color: inherit;
    font: inherit;
    text-align: right;
    outline: none;
  }
  .hc-case button {
    font: inherit;
    padding: 0 0.15rem;
    min-width: 0;
    line-height: 1;
  }
  .hc-selected > .hc-toggle, .hc-file.hc-active {
    outline: 1px solid var(--accent, #4a6da7);
    border-radius: 3px;
  }
  .hc-file.hc-tomb { color: var(--muted); font-style: italic; }
  .hc-note { color: var(--muted); margin: 0.25rem 0.5rem; }
  .hc-error { color: var(--danger, #b42318); }
  .hc-result { display: grid; gap: 0.5rem; padding: 0.5rem; min-width: 0; }
  .hc-result-head {
    display: flex;
    gap: 0.5rem;
    align-items: center;
    color: var(--muted);
    font-size: 0.9em;
  }
  .hc-result-path {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 0.5rem;
    min-width: 0;
    overflow-wrap: anywhere;
  }
  #hc-result-fullscreen { margin-left: auto; flex: 0 0 auto; }
  .hc-badge {
    border: 1px solid currentColor;
    border-radius: 999px;
    padding: 0 0.5rem;
  }
  .hc-result pre {
    margin: 0;
    white-space: pre-wrap;
    word-break: break-word;
    font-family: var(--mono, monospace);
    font-size: 0.85rem;
  }
  .hc-result img, .hc-result video { max-width: 100%; height: auto; }
  .is-fullscreen .hc-result.hc-video-result {
    flex: 1;
    min-height: 0;
    grid-template-rows: auto minmax(0, 1fr);
  }
  .is-fullscreen .hc-video-result .hc-result-body {
    display: flex;
    flex-direction: column;
    min-height: 0;
  }
  .is-fullscreen .hc-video-result video {
    flex: 1;
    min-height: 0;
    width: 100%;
    height: 0;
    object-fit: contain;
  }
  /* as graph-viz does: dark-theme SVG is inverted, hues kept */
  :root[data-effective-theme='dark'] .hc-result .hc-svg {
    filter: invert(1) hue-rotate(180deg);
  }
  .hc-result iframe {
    width: 100%;
    min-height: 60vh;
    border: 1px solid var(--line, #ccc);
    background: #fff;
  }
  .hc-table-wrap { overflow: auto; max-height: 70vh; }
  .hc-table { border-collapse: collapse; font-size: 0.85rem; }
  .hc-table th, .hc-table td {
    border: 1px solid var(--line, #ccc);
    padding: 0.15rem 0.4rem;
    text-align: left;
    vertical-align: top;
  }
  .hc-json details { margin-left: 1rem; }
  .hc-json summary { cursor: pointer; }
  .hc-specimen { font-size: 2rem; line-height: 1.3; word-break: break-word; }
  .hc-dialog-card {
    max-width: min(48rem, 94vw);
    max-height: 90vh;
    overflow: auto;
  }
  .hc-attributes { overflow: auto; padding: 0.75rem; }
  .hc-attributes h2 { font-size: 1rem; overflow-wrap: anywhere; }
  .hc-attributes .hc-attributes-body dl { grid-template-columns: minmax(0, 1fr); }
  .hc-attributes .hc-attributes-body dd { margin-bottom: 0.4rem; }
  .hc-attributes input, .hc-attributes textarea, .hc-attributes select {
    min-width: 0; max-width: 100%; box-sizing: border-box;
  }
  .hc-dialog-body { display: grid; gap: 0.75rem; }
  .hc-dialog-body section { display: grid; gap: 0.4rem; }
  .hc-dialog-body h3 { margin: 0.25rem 0 0; font-size: 1rem; }
  .hc-dialog-body dl {
    display: grid;
    grid-template-columns: max-content 1fr;
    gap: 0.15rem 0.75rem;
    margin: 0;
  }
  .hc-dialog-body dt { color: var(--muted); }
  .hc-dialog-body dd { margin: 0; word-break: break-word; }
  .hc-form { display: grid; gap: 0.4rem; }
  .hc-form label { display: grid; gap: 0.15rem; }
  .hc-form textarea { font: inherit; min-height: 2.5rem; }
  .hc-warn {
    border-left: 3px solid var(--danger, #b42318);
    padding-left: 0.5rem;
    margin: 0;
  }
  .hc-actions { display: flex; gap: 0.5rem; flex-wrap: wrap; }
  '''
::
++  app-js
  ^-  @t
  '''
  (() => {
    'use strict';
    const NL = String.fromCharCode(10);
    const TAB = String.fromCharCode(9);
    const QUOTE = String.fromCharCode(34);
    const base = '/heathcliff';
    const store = 'clay';
    const views = ['apps', 'data'];
    const limits = {text: 200000, rows: 500, cols: 60, nodes: 2000};
    const el = (id) => document.getElementById(id);

    function make(tag, props = {}, ...kids) {
      const node = document.createElement(tag);
      for (const [key, value] of Object.entries(props)) {
        if (value === undefined || value === null || value === false) continue;
        if (key === 'class') node.className = value;
        else if (key === 'text') node.textContent = value;
        else if (key === 'hidden') node.hidden = true;
        else node.setAttribute(key, value === true ? '' : String(value));
      }
      for (const kid of kids) {
        if (kid === undefined || kid === null || kid === false) continue;
        node.append(typeof kid === 'string'
          ? document.createTextNode(kid) : kid);
      }
      return node;
    }

    // ---- the server ----------------------------------------------------
    async function api(op, body = {}, url = `${base}/api`) {
      const response = await fetch(url, {
        method: 'POST',
        credentials: 'same-origin',
        headers: {'content-type': 'application/json'},
        body: JSON.stringify({op, ...body})
      });
      return reply(response);
    }

    async function reply(response) {
      let parsed = null;
      try {
        parsed = JSON.parse(await response.text());
      } catch (_) {
        parsed = null;
      }
      if (!response.ok || !parsed || parsed.ok === false) {
        const error = new Error(
          parsed?.error?.message || `Request failed (${response.status})`
        );
        error.code = parsed?.error?.code || null;
        error.details = parsed?.error?.details || [];
        throw error;
      }
      return parsed;
    }

    const rawUrl = (path, download) => {
      const tail = path.map((part) => encodeURIComponent(part)).join('/');
      return `${base}/raw/${tail}${download ? '?download' : ''}`;
    };

    const markOf = (path) => path?.[path.length - 1];
    const isNow = (path) => path?.[1] === 'now';
    const clayText = (path) => '/' + path.slice(2).join('/');

    // ---- trees -------------------------------------------------------------
    //  Per view: the case each desk is browsed at and the open
    //  directories, persisted; and the listing of each desk and case.
    let trees = {apps: {cases: {}, open: {}}, data: {cases: {}, open: {}}};
    let appsUploadRoot = 'data';
    const listings = {apps: new Map(), data: new Map()};
    //  wire paths, joined, of files whose data is tombstoned
    const tombstones = new Set();
    const selected = {apps: null, data: null};
    let roots = [];
    //  per view and desk: the revision box's `pick` and its head
    const revisions = {apps: new Map(), data: new Map()};

    function validTrees(raw) {
      const clean = {apps: {cases: {}, open: {}}, data: {cases: {}, open: {}}};
      if (!raw || typeof raw !== 'object') return clean;
      for (const view of views) {
        const part = raw[view];
        if (!part || typeof part !== 'object') continue;
        for (const [desk, value] of Object.entries(part.cases || {})) {
          if (typeof value === 'string' && /^([0-9]+|now)$/.test(value)) {
            clean[view].cases[desk] = value;
          }
        }
        for (const [key, value] of Object.entries(part.open || {})) {
          if (value === true && key.length <= 1024) {
            clean[view].open[key] = true;
          }
        }
      }
      return clean;
    }

    const caseOf = (view, desk) => trees[view].cases[desk] || 'now';
    const scopeOf = (view) => (view === 'data' ? ['data'] : []);

    function setSelected(view, target) {
      selected[view] = target;
      const old = document.querySelectorAll(`#${view}-tree .hc-selected`);
      for (const node of old) node.classList.remove('hc-selected');
      target?.row?.classList.add('hc-selected');
    }

    function currentView() {
      return runtime.explorer.view() === 'data' ? 'data' : 'apps';
    }

    function openMenu(view, source, event, target) {
      runtime.explorer.context.open(store, target.path, source, event, {
        entry: target.entry, view, tomb: Boolean(target.tomb)
      });
    }

    function menuKeys(view, source, target) {
      return (event) => {
        const menu = event.key === 'ContextMenu'
          || (event.shiftKey && event.key === 'F10');
        if (menu) {
          event.preventDefault();
          openMenu(view, source, undefined, target);
        }
      };
    }

    function actionsButton(view, target, label) {
      const button = make('button', {
        type: 'button',
        class: 'file-tree-actions',
        'aria-label': `Actions for ${label}`,
        'aria-haspopup': 'menu',
        'aria-expanded': 'false',
        title: 'Item actions',
        text: '…'
      });
      button.addEventListener('click', (event) => {
        openMenu(view, button, event, target);
      });
      return button;
    }

    //  A disclosure: a toggle button and its children, built on first
    //  open.
    function disclosure(view, {label, title, key, target, extra, fill, root}) {
      const wrap = make('div', {class: root ? 'hc-dir hc-root' : 'hc-dir'});
      const row = make('div', {class: 'hc-row'});
      const toggle = make('button', {
        type: 'button', class: 'hc-toggle', text: label, title: title || label,
        'aria-expanded': 'false'
      });
      const kids = make('div', {class: 'hc-kids', role: 'group', hidden: true});
      let built = false;
      target.row = row;
      const show = (open) => {
        toggle.setAttribute('aria-expanded', String(open));
        kids.hidden = !open;
        if (open) trees[view].open[key] = true;
        else delete trees[view].open[key];
        if (open && !built) {
          built = true;
          fill(kids);
        }
      };
      toggle.addEventListener('click', () => {
        runtime.explorer.context.close();
        setSelected(view, target);
        show(kids.hidden);
        runtime.session.queue();
      });
      toggle.addEventListener('keydown', menuKeys(view, toggle, target));
      row.addEventListener('contextmenu', (event) => {
        setSelected(view, target);
        openMenu(view, toggle, event, target);
      });
      row.append(toggle, ...(extra || []), actionsButton(view, target, label));
      wrap.append(row, kids);
      wrap.refill = () => {
        built = false;
        kids.replaceChildren();
        if (!kids.hidden) show(true);
      };
      if (trees[view].open[key]) show(true);
      return wrap;
    }

    const byName = (left, right) => {
      const order = left.localeCompare(right, undefined, {sensitivity: 'base'});
      return order || (left < right ? -1 : left > right ? 1 : 0);
    };

    function treeNodes(view, desk, cas, scope, paths) {
      const top = {dirs: new Map(), files: []};
      for (const path of paths) {
        if (path.length < 2) continue;
        let branch = top;
        const dirs = path.slice(0, -2);
        dirs.forEach((part, index) => {
          if (!branch.dirs.has(part)) {
            branch.dirs.set(part, {
              path: dirs.slice(0, index + 1), dirs: new Map(), files: []
            });
          }
          branch = branch.dirs.get(part);
        });
        branch.files.push(path);
      }
      //  the Data view starts below /data, and below /data/<desk> too
      //  when that folder is all /data holds, as an app's file root is
      let start = top;
      for (const part of scope) {
        start = start.dirs.get(part) || {dirs: new Map(), files: []};
      }
      const own = start.dirs.get(desk);
      if (scope.length && own && start.dirs.size === 1 && !start.files.length) {
        start = own;
      }
      const build = (branch) => {
        const nodes = [];
        const names = [...branch.dirs.keys()].sort(byName);
        for (const name of names) {
          const folder = branch.dirs.get(name);
          const wire = [desk, cas, ...folder.path];
          nodes.push(disclosure(view, {
            label: name,
            title: '/' + folder.path.join('/'),
            key: `${desk}:${cas}:${folder.path.join('/')}`,
            target: {path: wire, entry: 'directory'},
            fill: (kids) => kids.append(...build(folder))
          }));
        }
        const files = branch.files.slice().sort((left, right) => {
          return byName(fileLabel(left), fileLabel(right));
        });
        for (const path of files) {
          nodes.push(fileRow(view, [desk, cas, ...path]));
        }
        return nodes;
      };
      return {nodes: build(start), root: start.path || scope};
    }

    const fileLabel = (path) => {
      return `${path[path.length - 2]}.${path[path.length - 1]}`;
    };

    const fileTabLabel = (path) => {
      const label = fileLabel(path);
      return isNow(path) ? label : `${label} version ${path[1]}`;
    };

    //  a tombstoned file is listed, marked, and cannot be opened
    function fileRow(view, wire) {
      const tomb = tombstones.has(wire.join('/'));
      const label = fileLabel(wire);
      const target = {path: wire, entry: 'file', tomb};
      const row = make('div', {class: 'hc-row explorer-file-row'});
      const button = make('button', {
        type: 'button',
        class: tomb ? 'hc-file hc-tomb' : 'hc-file',
        text: tomb ? `${label} (tombstoned)` : label,
        title: tomb
          ? `${clayText(wire)}: its data has been tombstoned`
          : clayText(wire)
      });
      button.dataset.path = wire.join('/');
      target.row = row;
      button.addEventListener('click', () => {
        runtime.explorer.context.close();
        setSelected(view, target);
        if (!tomb) openFile(wire);
      });
      button.addEventListener('keydown', menuKeys(view, button, target));
      row.addEventListener('contextmenu', (event) => {
        setSelected(view, target);
        openMenu(view, button, event, target);
      });
      row.append(button, actionsButton(view, target, label));
      return row;
    }

    async function listing(view, desk, cas, force) {
      const key = `${desk}:${cas}`;
      if (!force && listings[view].has(key)) return listings[view].get(key);
      const answer = await api('tree', {desk, case: cas, scope: scopeOf(view)});
      for (const path of answer.tombs || []) {
        tombstones.add([desk, cas, ...path].join('/'));
      }
      listings[view].set(key, answer.paths);
      return answer.paths;
    }

    //  The revision a desk is browsed at: `now N` at its head, else a
    //  revision number.  Up and Down step; reaching the head is now.
    function caseInput(view, root, refill) {
      const head = root.rev || 1;
      //  a saved revision that is now the head is now
      if (Number(trees[view].cases[root.desk]) >= head) {
        delete trees[view].cases[root.desk];
      }
      const wrap = make('span', {class: 'hc-case'});
      //  `now` sits left in the box, green, while the number sits right
      const field = make('span', {class: 'hc-case-field'});
      const label = make('span', {
        class: 'hc-now', text: 'now', 'aria-hidden': 'true'
      });
      const input = make('input', {
        type: 'text',
        inputmode: 'numeric',
        title: `Revision of %${root.desk}: 1 to ${head}; ${head} is now`,
        'aria-label': `Revision of ${root.title}`
      });
      const down = make('button', {
        type: 'button', text: '▾', 'aria-label': 'Older revision',
        title: 'Older revision'
      });
      const up = make('button', {
        type: 'button', text: '▴', 'aria-label': 'Newer revision',
        title: 'Newer revision'
      });
      const current = () => {
        const cas = caseOf(view, root.desk);
        return cas === 'now' ? head : Number(cas);
      };
      const show = () => {
        const number = current();
        input.value = String(number);
        label.style.visibility = number >= head ? 'visible' : 'hidden';
        //  one width for every desk, so the numbers line up in a column
        const widest = Math.max(1, ...roots.map((item) => item.rev || 1));
        field.style.width = `${String(widest).length + 5}ch`;
        up.disabled = number >= head;
        down.disabled = number <= 1;
      };
      const pick = (number, typed = number) => {
        if (!Number.isInteger(number) || number < 1 || number > head) {
          runtime.notify(`%${root.desk} has no revision ${typed}; ` +
            `its revisions run from 1 to ${head} (now).`, {kind: 'error'});
          show();
          return;
        }
        const next = number;
        if (next >= head) delete trees[view].cases[root.desk];
        else trees[view].cases[root.desk] = String(next);
        show();
        runtime.session.queue();
        refill();
      };
      input.addEventListener('change', () => {
        const text = input.value.trim().replace(/^now */, '');
        const number = Number(text);
        if (text === '') pick(head);
        else pick(number, text);
      });
      const step = (by) => {
        const next = current() + by;
        if (next >= 1 && next <= head) pick(next);
      };
      input.addEventListener('keydown', (event) => {
        if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return;
        event.preventDefault();
        step(event.key === 'ArrowUp' ? 1 : -1);
      });
      up.addEventListener('click', () => step(1));
      down.addEventListener('click', () => step(-1));
      revisions[view].set(root.desk, {pick, head, current});
      show();
      field.append(label, input);
      wrap.append(field, up, down);
      return wrap;
    }

    function rootNode(view, root) {
      let node;
      const target = {entry: 'root'};
      const refill = () => {
        target.path = [root.desk, caseOf(view, root.desk), ...scopeOf(view)];
        node.refill();
      };
      target.path = [root.desk, caseOf(view, root.desk), ...scopeOf(view)];
      const fill = async (kids) => {
        const cas = caseOf(view, root.desk);
        kids.replaceChildren(make('p', {class: 'hc-note', text: 'Loading…'}));
        let paths;
        try {
          paths = await listing(view, root.desk, cas);
        } catch (cause) {
          kids.replaceChildren(make('p', {
            class: 'hc-note hc-error', text: `Unable to list: ${cause.message}`
          }));
          return;
        }
        if (caseOf(view, root.desk) !== cas) return;
        const built = treeNodes(view, root.desk, cas, scopeOf(view), paths);
        const nodes = built.nodes;
        //  menus on the root act on the folder it shows
        target.path = [root.desk, cas, ...built.root];
        if (!nodes.length) {
          kids.replaceChildren(make('p', {
            class: 'hc-note',
            text: view === 'data'
              ? 'No /data on this desk.' : 'This desk is empty.'
          }));
          return;
        }
        kids.replaceChildren(...nodes);
        markActive();
      };
      //  Data shows each desk's data directory itself as the root
      const data = view === 'data';
      const extra = [];
      if (!data && root.title !== root.desk) {
        extra.push(make('span', {class: 'hc-desk', text: `%${root.desk}`}));
      }
      extra.push(caseInput(view, root, () => refill()));
      node = disclosure(view, {
        label: data ? `%${root.desk}` : root.title,
        title: `${root.title} (%${root.desk})`,
        key: `${root.desk}:root`,
        target,
        extra,
        fill,
        root: true
      });
      return node;
    }

    //  Apps by title; Data, labelled by desk, by desk name.
    function ordered(view) {
      if (view !== 'data') return roots;
      return roots.slice().sort((left, right) => byName(left.desk, right.desk));
    }

    function renderView(view) {
      const host = el(`${view}-tree`);
      if (!host) return;
      host.setAttribute('aria-busy', 'false');
      host.replaceChildren(make('div', {class: 'hc-tree'},
        ...ordered(view).map((root) => rootNode(view, root))));
      markActive();
    }

    async function loadRoots() {
      for (const view of views) {
        const host = el(`${view}-tree`);
        host?.setAttribute('aria-busy', 'true');
      }
      try {
        roots = (await api('roots')).roots;
      } catch (cause) {
        for (const view of views) {
          el(`${view}-tree`)?.replaceChildren(make('p', {
            class: 'hc-note hc-error',
            text: `Unable to list desks: ${cause.message}`
          }));
        }
        return;
      }
      for (const view of views) {
        listings[view].clear();
        renderView(view);
      }
    }

    //  After a save, delete, or upload on a desk, its listings are stale.
    function refreshDesk(desk) {
      for (const key of [...tombstones]) {
        if (key.startsWith(`${desk}/`)) tombstones.delete(key);
      }
      for (const view of views) {
        for (const key of [...listings[view].keys()]) {
          if (key.startsWith(`${desk}:`)) listings[view].delete(key);
        }
      }
      loadRoots();
    }

    function markActive() {
      const tab = runtime.documents.active(store);
      const wanted = tab?.path ? tab.path.join('/') : null;
      for (const button of document.querySelectorAll('.hc-file')) {
        const on = button.dataset.path === wanted;
        button.classList.toggle('hc-active', on);
        if (on) button.setAttribute('aria-current', 'true');
        else button.removeAttribute('aria-current');
      }
    }

    function openFile(path) {
      return runtime.documents.open(store, path);
    }

    function download(path) {
      const link = make('a', {href: rawUrl(path, true), download: ''});
      link.hidden = true;
      document.body.append(link);
      link.click();
      link.remove();
    }

    // ---- the result pane -------------------------------------------------
    let renderToken = 0;
    let renderTimer;
    let fontFace;
    let objectUrl;
    let markdownRequest;
    const resultFullscreen = el('hc-result-fullscreen');

    function cleanResult() {
      markdownRequest?.abort();
      markdownRequest = undefined;
      if (objectUrl) URL.revokeObjectURL(objectUrl);
      objectUrl = undefined;
      if (fontFace) document.fonts?.delete?.(fontFace);
      fontFace = undefined;
    }

    function queueResult() {
      clearTimeout(renderTimer);
      const wait = config.limits?.renderDebounce || 250;
      renderTimer = setTimeout(renderResult, wait);
    }

    const textual = new Set([
      'txt', 'csv', 'tab', 'md', 'pem', 'hoon', 'css', 'js', 'html', 'svg',
      'xml', 'udon', 'umd', 'map', 'json', 'bill', 'docket-0', 'kelvin', 'ship'
    ]);
    const images = new Set([
      'png', 'jpg', 'jpeg', 'gif', 'bmp', 'ico', 'tiff', 'webp'
    ]);
    const audio = new Set(['mp3', 'wav', 'ogg', 'oga', 'flac', 'aac', 'weba']);
    const video = new Set(['mov', 'mp4', 'webm', 'ogv', 'mpeg', 'avi']);
    const fonts = new Set(['otf', 'ttf', 'woff2']);
    const framed = new Set(['hymn', 'urb', 'snip']);

    function renderResult() {
      clearTimeout(renderTimer);
      const token = ++renderToken;
      const live = () => token === renderToken;
      cleanResult();
      const host = el('result-view');
      if (!host) return;
      const tab = runtime.documents.active(store);
      host.classList.toggle('hc-video-result',
        Boolean(tab?.path && video.has(markOf(tab.path))));
      el('hc-download-button').disabled = !tab?.path;
      if (!tab) {
        host.replaceChildren(
          make('div', {class: 'hc-result-head'}, resultFullscreen),
          make('p', {
            class: 'hc-note', text: 'Open a file from Apps or Data.'
          }));
        return;
      }
      const path = tab.path;
      const mark = path ? markOf(path) : null;
      const dirty = tab.text !== tab.clean;
      const head = make('div', {class: 'hc-result-path'});
      if (path) {
        head.append(make('span', {text: `%${path[0]} ${clayText(path)}`}));
        head.append(make('span', {class: 'hc-badge',
          text: isNow(path) ? 'current' : `revision ${path[1]}`}));
      } else {
        head.append(make('span', {
          text: 'Draft: Save asks for desk/now/folder/name.mark'
        }));
      }
      if (tab.readonly) {
        head.append(make('span', {class: 'hc-badge', text: 'read-only'}));
      }
      if (dirty) {
        head.append(make('span', {class: 'hc-badge', text: 'unsaved buffer'}));
      }
      const body = make('div', {class: 'hc-result-body'});
      host.replaceChildren(
        make('div', {class: 'hc-result-head'}, head, resultFullscreen), body);
      const bytes = !textual.has(mark) || tab.readonly;
      if (bytes && path && dirty) {
        noted(body, 'Showing the committed file.');
      }
      try {
        const done = (renderers[mark] || renderers.fallback)(tab, body, live);
        done?.catch?.((cause) => live() && failed(body, cause));
      } catch (cause) {
        failed(body, cause);
      }
    }

    function failed(body, cause) {
      body.append(make('p', {class: 'hc-note hc-error',
        text: `Unable to show this file: ${cause?.message || cause}`}));
    }

    function source(body, text) {
      const shown = text.length > limits.text
        ? text.slice(0, limits.text) + NL + '… truncated' : text;
      body.append(make('pre', {text: shown}));
    }

    function plural(count, noun) {
      return `${count} ${noun}${count === 1 ? '' : 's'}`;
    }

    function lines(text) {
      return text === '' ? 0 : text.split(NL).length;
    }

    function noted(body, text) {
      body.append(make('p', {class: 'hc-note', text}));
    }

    function table(body, rows) {
      const shown = rows.slice(0, limits.rows);
      const width = Math.min(limits.cols,
        Math.max(0, ...shown.map((row) => row.length)));
      const grid = make('table', {class: 'hc-table'});
      shown.forEach((row, index) => {
        const tr = make('tr');
        for (let column = 0; column < width; column += 1) {
          tr.append(make(index === 0 ? 'th' : 'td', {text: row[column] ?? ''}));
        }
        grid.append(tr);
      });
      body.append(make('div', {class: 'hc-table-wrap'}, grid));
      if (rows.length > shown.length) {
        noted(body, `First ${shown.length} of ${rows.length} rows.`);
      }
    }

    //  RFC 4180: quoted fields may hold commas, quotes ("") and newlines.
    function parseCsv(text) {
      const rows = [];
      let row = [];
      let field = '';
      let quoted = false;
      for (let at = 0; at < text.length; at += 1) {
        const char = text[at];
        if (quoted) {
          if (char === QUOTE && text[at + 1] === QUOTE) {
            field += QUOTE;
            at += 1;
          } else if (char === QUOTE) {
            quoted = false;
          } else {
            field += char;
          }
        } else if (char === QUOTE && field === '') {
          quoted = true;
        } else if (char === ',') {
          row.push(field);
          field = '';
        } else if (char === NL) {
          const cr = field.endsWith(String.fromCharCode(13));
          row.push(cr ? field.slice(0, -1) : field);
          rows.push(row);
          row = [];
          field = '';
          if (rows.length > limits.rows) break;
        } else {
          field += char;
        }
      }
      if (field !== '' || row.length) {
        row.push(field);
        rows.push(row);
      }
      return rows;
    }

    function jsonNode(value, depth = 0) {
      if (value === null || typeof value !== 'object') {
        return make('span', {text: JSON.stringify(value)});
      }
      const entries = Array.isArray(value)
        ? value.map((item, index) => [index, item]) : Object.entries(value);
      const node = make('details', {open: depth < 2});
      node.append(make('summary', {
        text: Array.isArray(value)
          ? `[${entries.length}]` : `{${entries.length}}`
      }));
      for (const [key, item] of entries.slice(0, limits.nodes)) {
        const line = make('div');
        line.append(make('span', {text: `${key}: `}),
          jsonNode(item, depth + 1));
        node.append(line);
      }
      return node;
    }

    function xmlNode(node, budget) {
      if (budget.left <= 0) return null;
      budget.left -= 1;
      if (node.nodeType === 3) {
        const text = node.textContent.trim();
        return text ? make('div', {text: JSON.stringify(text)}) : null;
      }
      if (node.nodeType !== 1) return null;
      const attrs = [...node.attributes].map((attr) => {
        return ` ${attr.name}=${JSON.stringify(attr.value)}`;
      }).join('');
      const item = make('details', {open: budget.left > limits.nodes - 50});
      item.append(make('summary', {text: `<${node.nodeName}${attrs}>`}));
      for (const child of node.childNodes) {
        const built = xmlNode(child, budget);
        if (built) item.append(built);
      }
      return item;
    }

    function framedRaw(body, path, title) {
      const frame = make('iframe', {
        sandbox: '', referrerpolicy: 'no-referrer', title, src: rawUrl(path)
      });
      body.append(frame);
    }

    function media(body, tab, tag) {
      const node = make(tag, {
        controls: true, preload: 'metadata', src: rawUrl(tab.path)
      });
      if (tag === 'video') {
        node.addEventListener('fullscreenchange', async () => {
          const pane = node.closest('#result-pane');
          if (document.fullscreenElement !== node ||
              !pane?.matches(':fullscreen')) return;
          // The native control stacks video fullscreen over the pane.
          // Treat that click as a return to the normal pane instead.
          try {
            await document.exitFullscreen();
            if (document.fullscreenElement === pane) {
              await document.exitFullscreen();
            }
          } catch (_) {
            runtime.notify('Unable to leave fullscreen mode.',
              {kind: 'error'});
          }
        });
      }
      node.addEventListener('error', () => {
        node.remove();
        noted(body, 'This browser cannot play this file.');
      });
      body.append(node);
    }

    async function specimen(body, tab, live) {
      const response = await fetch(rawUrl(tab.path), {
        credentials: 'same-origin'
      });
      if (!response.ok) throw new Error(`Request failed (${response.status})`);
      const buffer = await response.arrayBuffer();
      if (!live()) return;
      const family = `hc-specimen-${renderToken}`;
      const face = new FontFace(family, buffer);
      await face.load();
      if (!live()) return;
      document.fonts.add(face);
      fontFace = face;
      const sample = make('div', {class: 'hc-specimen',
        text: 'The quick brown fox jumps over the lazy dog 0123456789'});
      sample.style.fontFamily = family;
      body.append(sample);
    }

    const renderers = {
      txt: (tab, body) => source(body, tab.text),
      hoon: (tab, body) => {
        noted(body, `${lines(tab.text)} lines of Hoon; nothing is run.`);
        source(body, tab.text);
      },
      css: (tab, body) => {
        noted(body,
          `${lines(tab.text)} lines of CSS; never applied to this page.`);
        source(body, tab.text);
      },
      js: (tab, body) => {
        noted(body, `${lines(tab.text)} lines of JavaScript; never run.`);
        source(body, tab.text);
      },
      udon: (tab, body) => {
        noted(body, 'UdON source; no UdON renderer runs in the browser.');
        source(body, tab.text);
      },
      pem: (tab, body) => {
        const blocks = tab.text.split(NL)
          .filter((line) => line.startsWith('-----BEGIN '))
          .map((line) => line.replace(/-/g, '').replace('BEGIN ', '').trim());
        noted(body, blocks.length
          ? `PEM blocks: ${blocks.join(', ')}.  Nothing is parsed or sent.`
          : 'No PEM blocks found.');
        source(body, tab.text);
      },
      csv: (tab, body) => table(body, parseCsv(tab.text)),
      tab: (tab, body) => table(body, tab.text.split(NL)
        .filter((line, index, all) => line !== '' || index < all.length - 1)
        .map((line) => line.split(TAB))),
      md: async (tab, body, live) => {
        const controller = new AbortController();
        markdownRequest = controller;
        const status = make('p', {class: 'hc-note', text: 'Rendering…'});
        body.append(status);
        try {
          let text = tab.text;
          if (tab.readonly && tab.path) {
            const stored = await fetch(rawUrl(tab.path), {
              credentials: 'same-origin', signal: controller.signal
            });
            if (!stored.ok) throw new Error('Unable to read Markdown source');
            text = await stored.text();
            if (!live()) return;
          }
          const response = await fetch(`${base}/api`, {
            method: 'POST', credentials: 'same-origin',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({op: 'markdown', text}),
            signal: controller.signal
          });
          const answer = await response.json();
          if (!live()) return;
          if (!response.ok || !answer.ok) {
            throw new Error(answer.error?.message || 'Markdown render failed');
          }
          const view = make('div', {class: 'markdown-view'});
          // The server restricts the Sail tree before serializing it.
          view.innerHTML = answer.html;
          body.replaceChildren(view);
        } catch (cause) {
          if (!live() || controller.signal.aborted) return;
          status.remove();
          failed(body, cause);
          source(body, tab.text);
        }
      },
      html: (tab, body) => {
        const previewer = runtime.documents.previews.get('html');
        if (previewer?.render) previewer.render(body, tab.text);
        else source(body, tab.text);
      },
      svg: (tab, body) => {
        const blob = new Blob([tab.text], {type: 'image/svg+xml'});
        objectUrl = URL.createObjectURL(blob);
        const image = make('img', {
          class: 'hc-svg', alt: 'SVG preview', src: objectUrl
        });
        image.addEventListener('error', () => {
          image.remove();
          noted(body, 'This SVG does not render.');
        });
        body.append(image);
      },
      xml: (tab, body) => {
        const doc = new DOMParser()
          .parseFromString(tab.text, 'application/xml');
        const error = doc.getElementsByTagName('parsererror')[0];
        if (error) {
          body.append(make('p', {class: 'hc-note hc-error',
            text: `XML does not parse: ${error.textContent.trim()}`}));
          source(body, tab.text);
          return;
        }
        const tree = xmlNode(doc.documentElement, {left: limits.nodes});
        if (tree) body.append(tree);
      },
      json: (tab, body) => {
        let value;
        try {
          value = JSON.parse(tab.text);
        } catch (cause) {
          body.append(make('p', {class: 'hc-note hc-error',
            text: `Invalid JSON, which saving refuses: ${cause.message}`}));
          return;
        }
        body.append(make('div', {class: 'hc-json'}, jsonNode(value)));
      },
      map: (tab, body) => {
        try {
          const value = JSON.parse(tab.text);
          noted(body, 'JavaScript source map.');
          body.append(make('div', {class: 'hc-json'}, jsonNode(value)));
        } catch (_) {
          noted(body, 'Not valid source-map JSON; showing the source.');
          source(body, tab.text);
        }
      },
      bill: (tab, body) => {
        const found = tab.text.match(/%[a-z0-9-]+/g) || [];
        const agents = found.map((item) => item.slice(1));
        noted(body, agents.length
          ? 'Agents this desk starts (none are started from here):'
          : 'This bill starts no agents.');
        if (agents.length) {
          const items = agents.map((name) => make('li', {text: `%${name}`}));
          body.append(make('ul', {}, ...items));
        }
      },
      'docket-0': (tab, body) => {
        const rows = [['clause', 'value']];
        for (const line of tab.text.split(NL)) {
          const at = line.indexOf('+');
          if (at <= 0) continue;
          rows.push([line.slice(0, at).trim(), line.slice(at + 1).trim()]);
        }
        noted(body, 'Docket clauses; nothing is installed or launched.');
        table(body, rows);
      },
      kelvin: (tab, body) => {
        const rows = [['kernel', 'version']];
        for (const found of tab.text.matchAll(/%([a-z]+) ([0-9]+)/g)) {
          rows.push([found[1], found[2]]);
        }
        table(body, rows);
      },
      ship: (tab, body) => {
        const name = tab.text.trim().split(NL)[0] || '';
        noted(body, /^~[a-z-]+$/.test(name)
          ? `${name} is a well-formed @p.`
          : `${JSON.stringify(name)} is not an @p.`);
      },
      pdf: (tab, body) => {
        body.append(make('iframe', {
          title: 'PDF preview',
          referrerpolicy: 'no-referrer',
          src: rawUrl(tab.path)
        }));
      },
      mid: (tab, body) => {
        noted(body,
          'Browsers have no native MIDI playback; download it to play.');
      },
      mime: (tab, body) => {
        const type = (tab.text.split(NL)[0] || '').replace('type: ', '').trim();
        if (type.startsWith('image/')) {
          body.append(make('img', {
            alt: 'Stored image', src: rawUrl(tab.path)
          }));
        } else if (type.startsWith('audio/')) {
          media(body, tab, 'audio');
        } else if (type.startsWith('video/')) {
          media(body, tab, 'video');
        } else if (type.startsWith('text/') || type.includes('xml')
          || type.includes('json')) {
          framedRaw(body, tab.path, `Stored ${type}`);
        } else {
          noted(body, `No preview for ${type || 'this type'}.`);
          source(body, tab.text);
        }
      },
      fallback: (tab, body) => source(body, tab.text)
    };
    renderers.umd = renderers.udon;
    for (const mark of images) {
      renderers[mark] = (tab, body) => {
        const image = make('img', {
          alt: fileLabel(tab.path), src: rawUrl(tab.path)
        });
        image.addEventListener('error', () => {
          image.remove();
          noted(body, 'This browser cannot display this image.');
        });
        body.append(image);
      };
    }
    for (const mark of audio) {
      renderers[mark] = (tab, body) => media(body, tab, 'audio');
    }
    for (const mark of video) {
      renderers[mark] = (tab, body) => media(body, tab, 'video');
    }
    for (const mark of fonts) renderers[mark] = specimen;
    for (const mark of framed) {
      renderers[mark] = (tab, body) => {
        framedRaw(body, tab.path, `Rendered %${mark}`);
      };
    }

    // ---- file attributes -------------------------------------------------
    const attributeTargets = new Map();

    function disposeAttributes(ref) {
      const target = attributeTargets.get(ref.id);
      if (!target) return;
      target.stop();
      const tab = el(`${ref.id}-tab`);
      if (tab) tab.ondblclick = null;
      attributeTargets.delete(ref.id);
    }

    async function openAttributes(path, entry, kind = 'attributes') {
      const ref = runtime.explorer.refs.open({
        kind, parentId: JSON.stringify(path), path, entry
      });
      await attributeTargets.get(ref.id)?.pending;
    }

    function mountAttributes(panel, ref) {
      disposeAttributes(ref);
      panel.classList.add('hc-attributes');
      panel.dataset.details = ref.kind;
      const heading = ref.kind === 'permissions' ? 'Permissions' : 'Attributes';
      el(`${ref.id}-tab`).title = `${heading}: ${ref.label}`;
      const title = make('h2', {text: heading});
      const body = make('div', {class: 'hc-dialog-body hc-attributes-body'});
      panel.append(title, body);
      const target = {
        ...ref.data, ref, title, body, generation: 0, stop: () => {}
      };
      attributeTargets.set(ref.id, target);
      el(`${ref.id}-tab`).ondblclick = async () => {
        await target.pending;
        if (attributeTargets.get(ref.id) === target && target.openable) {
          openFile(target.path);
        }
      };
      body.append(make('p', {class: 'hc-note', text: 'Loading…'}));
      target.pending = loadAttributes(target);
    }

    async function loadAttributes(target) {
      if (attributeTargets.get(target.ref.id) !== target) return;
      const generation = ++target.generation;
      target.openable = false;
      target.stop();
      const live = () => attributeTargets.get(target.ref.id) === target
        && generation === target.generation;
      let answer;
      try {
        answer = await api('attributes', {path: target.path});
      } catch (cause) {
        if (!live()) return;
        target.body.replaceChildren(make('p', {
          class: 'hc-note hc-error', text: cause.message
        }));
        return;
      }
      if (!live()) return;
      renderAttributes(target, answer);
    }

    function mediaAttributes(target, answer, body) {
      if (!answer.file || answer.file.tombstoned) return;
      const mark = answer.target.mark;
      const type = answer.file.type || '';
      const image = images.has(mark) || mark === 'svg' || type.startsWith('image/');
      if (!image && !audio.has(mark) && !video.has(mark)
        && mark !== 'mid' && mark !== 'mime') return;
      const section = make('section');
      section.append(make('h3', {
        text: image ? 'Image attributes (read-only)' : 'Codec attributes (read-only)'
      }));
      const status = make('p', {class: 'hc-note', text: 'Reading file metadata…'});
      section.append(status);
      body.append(section);
      let worker;
      let picture;
      let timer;
      let stopped = false;
      const stop = () => {
        stopped = true;
        clearTimeout(timer);
        worker?.terminate();
        if (picture) {
          picture.onload = picture.onerror = null;
          picture.removeAttribute('src');
        }
      };
      target.stop = stop;
      const finish = (groups, error) => {
        if (stopped || attributeTargets.get(target.ref.id) !== target || !section.isConnected) return;
        stop();
        status.remove();
        for (const group of groups) {
          section.append(make('h4', {text: group.title}), facts(group.fields));
        }
        if (error) noted(section, error);
        if (!groups.length && !error) {
          noted(section, 'No readable metadata was found for this format.');
        }
      };
      timer = setTimeout(() => finish([], 'Metadata inspection timed out.'), 20000);
      // SVG is decoded as an image, never inserted as active markup.
      if (mark === 'svg' || type.split(';')[0] === 'image/svg+xml') {
        picture = new Image();
        picture.onload = () => finish([{title: 'SVG', fields: [
          ['Width', `${picture.naturalWidth} px`],
          ['Height', `${picture.naturalHeight} px`]
        ]}]);
        picture.onerror = () => finish([], 'This image could not be decoded.');
        picture.src = rawUrl(target.path);
        return;
      }
      try {
        worker = new Worker(`${base}/media-worker.js`, {type: 'module'});
        worker.onmessage = ({data}) => finish(data.groups || [], data.error);
        worker.onerror = () => finish([], 'Unable to read this file’s metadata.');
        worker.postMessage({url: rawUrl(target.path)});
      } catch (cause) {
        finish([], 'Metadata inspection is unavailable in this browser.');
      }
    }

    function facts(pairs) {
      const list = make('dl');
      for (const [term, value] of pairs) {
        if (value === undefined || value === null) continue;
        list.append(make('dt', {text: term}),
          make('dd', {text: String(value)}));
      }
      return list;
    }

    function ruleSection(target, name, rule, side, current, enforced) {
      const section = make('section');
      section.append(make('h3', {text: `${name}: ${rule.gist}`}));
      const origins = {
        here: 'set on this item',
        default: 'clay default; no rule is set anywhere on this desk'
      };
      const origin = origins[rule.origin] || `inherited from ${rule.from}`;
      const modes = {
        black: 'blacklist: all but these', white: 'whitelist: only these'
      };
      section.append(facts([
        ['Mode', modes[rule.mode]],
        ['Origin', origin],
        ['Ships', rule.ships.join(', ') || 'none'],
        ['Crews', rule.crews.map((crew) => {
          const who = crew.members.join(', ') || 'empty, admits no one';
          return `%${crew.name} (${who})`;
        }).join('; ') || 'none']
      ]));
      if (!enforced) {
        section.append(make('p', {class: 'hc-warn', text:
          'Clay stores and inherits write rules but never consults them ' +
          '(+may-write has no callers in this kernel).  This rule is a ' +
          'record, not a control.'}));
      }
      if (!current) return section;
      const form = make('form', {class: 'hc-form'});
      const mode = make('select', {name: 'mode'},
        make('option', {value: 'white', text: 'whitelist: only these'}),
        make('option', {value: 'black', text: 'blacklist: all but these'}));
      mode.value = rule.mode;
      const ships = make('textarea', {name: 'ships', placeholder: '~zod ~nec'});
      ships.value = rule.ships.join(' ');
      const crews = make('textarea', {name: 'crews', placeholder: 'friends'});
      crews.value = rule.crews.map((crew) => crew.name).join(' ');
      const set = make('button', {
        type: 'submit', class: 'primary', text: `Set ${name.toLowerCase()} here`
      });
      const clear = make('button', {
        type: 'button', text: 'Clear: inherit from parent'
      });
      form.append(
        make('label', {}, 'Mode', mode),
        make('label', {}, 'Ships', ships),
        make('label', {}, 'Crews', crews),
        make('div', {class: 'hc-actions'}, set, clear)
      );
      const send = (cleared) => change('rule', {
        path: target.path, side, clear: cleared,
        mode: mode.value, ships: ships.value, crews: crews.value
      }, target);
      form.addEventListener('submit', (event) => {
        event.preventDefault();
        send(false);
      });
      clear.addEventListener('click', () => send(true));
      section.append(form);
      return section;
    }

    function crewsSection(target, perms, current) {
      const section = make('section');
      section.append(make('h3', {text: 'Crews'}));
      section.append(make('p', {class: 'hc-note', text:
        'Crews belong to the ship, not to a desk.  Deleting one strips it ' +
        'from every rule naming it: that tightens a whitelist, but loosens ' +
        'a blacklist, since the ships it excluded are excluded no longer.'}));
      if (!perms.crews.length) {
        noted(section, 'No crews yet.');
      } else {
        const grid = make('table', {class: 'hc-table'});
        grid.append(make('tr', {},
          make('th', {text: 'Name'}), make('th', {text: 'Members'}),
          make('th', {text: 'Named by'}), make('th', {text: ''})));
        for (const crew of perms.crews) {
          const cell = make('td');
          if (current) {
            const kill = make('button', {
              type: 'button', class: 'danger-button', text: 'Delete'
            });
            kill.addEventListener('click', async () => {
              const ok = await runtime.confirm('delete', {
                path: `crew %${crew.name}`
              });
              if (ok) change('crew-kill', {name: crew.name}, target);
            });
            cell.append(kill);
          }
          grid.append(make('tr', {},
            make('td', {text: `%${crew.name}`}),
            make('td', {
              text: crew.members.join(', ') || 'empty, admits no one'
            }),
            make('td', {text: `${plural(crew.rules, 'rule')} on ` +
              plural(crew.desks, 'desk')}),
            cell));
        }
        section.append(make('div', {class: 'hc-table-wrap'}, grid));
      }
      if (current) {
        const form = make('form', {class: 'hc-form'});
        const name = make('input', {
          name: 'name', placeholder: 'friends', autocomplete: 'off'
        });
        const members = make('textarea', {
          name: 'members', placeholder: '~zod ~nec'
        });
        form.append(
          make('label', {}, 'Crew name', name),
          make('label', {}, 'Members', members),
          make('div', {class: 'hc-actions'},
            make('button', {type: 'submit', text: 'Save crew'}))
        );
        form.addEventListener('submit', (event) => {
          event.preventDefault();
          change('crew-save', {
            name: name.value.trim(), members: members.value
          }, target);
        });
        section.append(form);
      }
      const reload = make('button', {
        type: 'button', text: 'Reload crews from clay'
      });
      reload.addEventListener('click', () => change('reload', {}, target));
      section.append(make('div', {class: 'hc-actions'}, reload));
      return section;
    }

    function explicitSection(perms) {
      const section = make('section');
      section.append(make('h3', {text: 'Explicit rules here and below'}));
      const rows = perms.explicit.rows;
      if (!rows.length) {
        noted(section, 'None: everything here inherits.');
      } else {
        const grid = make('table', {class: 'hc-table'});
        grid.append(make('tr', {}, make('th', {text: 'Path'}),
          make('th', {text: 'Read'}), make('th', {text: 'Write'})));
        for (const row of rows) {
          grid.append(make('tr', {}, make('td', {text: row.path}),
            make('td', {text: row.read ?? '-'}),
            make('td', {text: row.write ?? '-'})));
        }
        section.append(make('div', {class: 'hc-table-wrap'}, grid));
      }
      if (perms.explicit.more) {
        section.append(make('p', {class: 'hc-warn', text:
          `More than ${perms.explicit.walk} paths sit here; only the first ` +
          `${perms.explicit.walk} were checked, so rules below may be ` +
          'missing.  ' +
          'Open Permissions further down to see them.'}));
      }
      noted(section,
        'A rule on a path with no files under it cannot be discovered.');
      return section;
    }

    function renderAttributes(target, answer) {
      const body = target.body;
      const t = answer.target;
      target.openable = t.kind === 'file' && !answer.file?.tombstoned;
      const current = answer.current;
      const noun = t.kind === 'file' ? 'File' : 'Path';
      const permissions = target.ref.kind === 'permissions';
      target.title.textContent = permissions
        ? `Permissions: ${t.label}` : `${noun} attributes: ${t.label}`;
      const identity = make('section');
      identity.append(make('h3', {text: 'Identity'}));
      identity.append(facts([
        ['Ship', t.ship],
        ['App', `${t.title} (%${t.desk})`],
        ['Revision', current
          ? `now (revision ${answer.head})`
          : `${t.case} of ${answer.head}, committed ${answer.date}`],
        ['Path', t.clay],
        ['Kind', t.kind],
        ['Mark', t.mark ? `%${t.mark}` : null]
      ]));
      const parts = [identity];
      if (permissions) {
        const perms = answer.permissions;
        const header = make('section');
        header.append(make('h3', {text: 'Permissions'}));
        noted(header, current
          ? 'Clay keeps current rules only.'
          : 'Clay keeps current rules only: these are as of now, not of this ' +
            'revision, and cannot be changed from a historical revision.');
        parts.push(header,
          ruleSection(target, 'Read', perms.read, 'read', current, perms.enforced.read),
          ruleSection(target, 'Write', perms.write, 'write', current,
            perms.enforced.write),
          explicitSection(perms),
          crewsSection(target, perms, current));
        body.replaceChildren(...parts);
        return;
      }
      if (answer.file) {
        const file = make('section');
        file.append(make('h3', {text: 'File'}));
        file.append(facts([
          ['Size', answer.file.size === null
            ? 'unknown' : `${answer.file.size} bytes`],
          ['Type', answer.file.type],
          ['Data', answer.file.tombstoned
            ? 'tombstoned: no longer stored' : 'stored']
        ]));
        parts.push(file);
      }
      if (answer.items !== undefined && answer.items !== null) {
        parts.push(make('section', {}, facts([['Items', answer.items]])));
      }
      body.replaceChildren(...parts);
      mediaAttributes(target, answer, body);
    }

    async function change(op, body, target) {
      try {
        await api(op, body);
      } catch (cause) {
        runtime.notify(cause.message, {kind: 'error', sticky: true});
        return;
      }
      runtime.notify(op === 'reload' ? 'Reloading crews.' : 'Sent to clay.');
      //  crews come back as a gift a moment later
      setTimeout(() => {
        for (const opened of attributeTargets.values()) {
          if (opened.ref.kind === 'permissions'
            && (op !== 'rule' || opened.path[0] === target.path[0])) {
            loadAttributes(opened);
          }
        }
      }, op === 'rule' ? 50 : 400);
    }

    // ---- upload -------------------------------------------------------------
    const uploadInput = el('hc-upload-input');
    let uploadDir = null;
    let uploadFile = null;
    let uploadPlan = null;
    let uploadName = null;
    let uploadPicker = null;
    let uploadCheck = 0;
    let uploadTimer;

    function uploadDestination(value) {
      const parts = value.trim().split('/');
      if (parts[0] === '') parts.shift();
      const leaf = parts.pop() || '';
      const dot = leaf.lastIndexOf('.');
      const mark = dot < 0 ? leaf : leaf.slice(dot + 1);
      const name = dot < 0 ? parts.pop() : leaf.slice(0, dot);
      if (!parts.length || !name || !/^[a-z0-9-]+$/.test(name)
        || !/^[a-z][a-z0-9-]*$/.test(mark)
        || parts.some(part => !/^[a-z0-9_~-]+$/.test(part))) {
        throw new Error('Enter /desk/folder/name.mark with a valid mark.');
      }
      return {dir: [parts[0], 'now', ...parts.slice(1)],
        filename: `${name}.${mark}`};
    }

    function uploadFilename(name) {
      const dot = name.lastIndexOf('.');
      if (dot < 0) return name.toLowerCase().replace(/[^a-z0-9-]/g, '-');
      return name.slice(0, dot).toLowerCase().replace(/[^a-z0-9-]/g, '-')
        + '.' + name.slice(dot + 1).toLowerCase();
    }

    function queueUploadCheck() {
      uploadCheck += 1;
      clearTimeout(uploadTimer);
      uploadPlan = null;
      el('hc-upload-confirm').disabled = true;
      uploadPicker.details.replaceChildren();
      uploadTimer = setTimeout(checkUpload, 250);
    }

    async function startUploadPicker() {
      closeUpload();
      uploadDir = null;
      uploadName = null;
      const field = make('input', {id: 'hc-upload-path', type: 'text',
        placeholder: '/base/data/notes/readme.md', autocomplete: 'off',
        spellcheck: 'false', 'aria-describedby': 'hc-upload-path-help'});
      const choose = make('button', {type: 'button',
        id: 'hc-upload-choose', text: 'Choose file…'});
      const selectedFile = make('p', {class: 'hc-note', text: 'No file chosen.'});
      const details = make('div');
      const tree = make('div', {class: 'hc-upload-tree',
        'aria-label': 'Upload destinations'});
      const picker = {field, selectedFile, details};
      uploadPicker = picker;
      el('hc-upload-body').replaceChildren(
        make('label', {for: field.id, text: 'Destination path'}), field,
        make('p', {id: 'hc-upload-path-help', class: 'hc-note', text:
          'Enter /desk/folder/name.mark or /desk/folder/name/mark. ' +
          'Select a desk, folders, or a file below to fill the path.'}),
        tree, choose, selectedFile, details);
      el('hc-upload-confirm').disabled = true;
      field.addEventListener('input', queueUploadCheck);
      choose.addEventListener('click', () => {
        uploadInput.value = '';
        uploadInput.click();
      });
      uploadDialog.open(field);
      const select = (path, filename) => {
        let leaf = filename;
        if (leaf === undefined) {
          try { leaf = uploadDestination(field.value).filename; }
          catch (_) { leaf = uploadFile ? uploadFilename(uploadFile.name) : ''; }
        }
        field.value = '/' + [...path, leaf].join('/');
        queueUploadCheck();
      };
      const folder = (label, path, fill) => {
        const node = make('details');
        const summary = make('summary', {text: label});
        const kids = make('div', {class: 'hc-kids'});
        let built = false;
        summary.addEventListener('click', () => select(path));
        node.addEventListener('toggle', async () => {
          if (!node.open || built) return;
          built = true;
          try { await fill(kids); }
          catch (cause) {
            built = false;
            kids.replaceChildren(make('p', {class: 'hc-error', text: cause.message}));
          }
        });
        node.append(summary, kids);
        return node;
      };
      const branches = (host, desk, prefix, paths) => {
        const dirs = new Set();
        const leaves = [];
        for (const path of paths) {
          if (!prefix.every((part, i) => path[i] === part)) continue;
          const rest = path.slice(prefix.length);
          if (rest.length > 2) dirs.add(rest[0]);
          else if (rest.length === 2) leaves.push(rest);
        }
        host.replaceChildren();
        for (const dir of [...dirs].sort(byName)) {
          const next = [...prefix, dir];
          host.append(folder(dir, [desk, ...next], kids =>
            branches(kids, desk, next, paths)));
        }
        for (const [name, mark] of leaves.sort((a, b) =>
          byName(a.join('.'), b.join('.')))) {
          const file = make('button', {type: 'button', class: 'hc-file',
            text: `${name}.${mark}`});
          file.addEventListener('click', () =>
            select([desk, ...prefix], `${name}.${mark}`));
          host.append(file);
        }
        if (!dirs.size && !leaves.length) {
          host.append(make('p', {class: 'hc-note', text: 'Empty folder.'}));
        }
      };
      const scope = appsUploadRoot === 'data' ? ['data'] : [];
      try {
        const answer = await api('roots');
        if (uploadPicker !== picker) return;
        for (const root of answer.roots) {
          tree.append(folder(`%${root.desk} /${scope.join('/')}`,
            [root.desk, ...scope], async kids => {
              const listing = await api('tree', {
                desk: root.desk, case: 'now', scope
              });
              if (uploadPicker === picker) {
                branches(kids, root.desk, scope, listing.paths);
              }
            }));
        }
        if (!answer.roots.length) {
          tree.append(make('p', {class: 'hc-note', text: 'No desks available.'}));
        }
      } catch (cause) {
        if (uploadPicker === picker) {
          tree.append(make('p', {class: 'hc-error', text: cause.message}));
        }
      }
    }

    function startUpload(dir, view = currentView()) {
      if (!dir || !isNow(dir)) return;
      closeUpload();
      uploadDir = view === 'apps' && appsUploadRoot === 'data'
        && dir[2] !== 'data'
        ? [...dir.slice(0, 2), 'data', ...dir.slice(2)] : [...dir];
      uploadInput.value = '';
      uploadInput.click();
    }

    async function trailingNuls(file) {
      const end = file.slice(Math.max(0, file.size - 65536));
      const tail = new Uint8Array(await end.arrayBuffer());
      let count = 0;
      for (let at = tail.length - 1; at >= 0 && tail[at] === 0; at -= 1) {
        count += 1;
      }
      return count;
    }

    uploadInput.addEventListener('change', () => {
      const file = uploadInput.files?.[0];
      if (!file) return;
      uploadFile = file;
      if (uploadPicker) {
        uploadPicker.selectedFile.textContent = `${file.name}, ${file.size} bytes`;
        if (uploadPicker.field.value.endsWith('/')) {
          uploadPicker.field.value += uploadFilename(file.name);
        }
        queueUploadCheck();
      } else {
        uploadName = file.name;
        checkUpload();
      }
    });

    async function checkUpload() {
      const check = ++uploadCheck;
      const file = uploadFile;
      uploadPlan = null;
      el('hc-upload-confirm').disabled = true;
      let plan;
      try {
        if (uploadPicker) {
          const target = uploadDestination(uploadPicker.field.value);
          uploadDir = target.dir;
          uploadName = target.filename;
          uploadPicker.field.setAttribute('aria-invalid', 'false');
        }
        if (!file || !uploadDir) return;
        plan = await api('upload-check', {
          path: uploadDir, filename: uploadName, size: file.size,
          nul: await trailingNuls(file)
        });
      } catch (cause) {
        if (check !== uploadCheck) return;
        if (uploadPicker) {
          uploadPicker.field.setAttribute('aria-invalid', 'true');
          uploadPicker.details.replaceChildren(make('p', {
            class: 'hc-error', text: cause.message
          }));
        } else {
          runtime.notify(cause.message, {kind: 'error', sticky: true});
        }
        return;
      }
      if (check !== uploadCheck) return;
      uploadPlan = plan;
      showUpload(file, plan);
    }

    function showUpload(file, plan) {
      const body = uploadPicker?.details || el('hc-upload-body');
      const parts = [facts([
        ['File', `${file.name}, ${file.size} bytes`],
        ['Into', `%${uploadDir[0]} /${uploadDir.slice(2).join('/')}`],
        ['As', `${plan.clay} (mark %${plan.mark})`]
      ])];
      for (const problem of plan.problems) {
        parts.push(make('p', {class: 'hc-warn', text: problem}));
      }
      if (plan.exists) {
        parts.push(make('label', {},
          make('input', {type: 'checkbox', id: 'hc-upload-overwrite'}),
          ' Replace the existing file at this path'));
      }
      if (plan.install.length) {
        parts.push(make('p', {class: 'hc-warn', text:
          `%${uploadDir[0]} lacks marks this file needs.  ` +
          'Heathcliff can copy ' +
          'their source into the desk, in the same commit as the file: ' +
          plan.install.map((item) => `%${item.mark} from %${item.from}`)
            .join(', ') +
          '.  A mark %base has is copied from %base; any other from ' +
          'Heathcliff’s own desk.  Marks the desk already has are never ' +
          'replaced.'}));
        parts.push(make('label', {},
          make('input', {type: 'checkbox', id: 'hc-upload-install'}),
          ' Install these marks into the desk'));
      }
      body.replaceChildren(...parts);
      el('hc-upload-confirm').disabled = plan.problems.length > 0;
      if (!uploadPicker) {
        uploadDialog.open(el(plan.problems.length
          ? 'hc-upload-cancel' : 'hc-upload-confirm'));
      }
    }

    function closeUpload() {
      uploadCheck += 1;
      clearTimeout(uploadTimer);
      uploadPicker = null;
      uploadName = null;
      el('hc-upload-body').inert = false;
      uploadDialog.close();
      uploadFile = null;
      uploadPlan = null;
    }

    el('hc-upload-cancel').addEventListener('click', closeUpload);
    el('hc-upload-confirm').addEventListener('click', async () => {
      if (!uploadFile || !uploadPlan || uploadPlan.problems.length) return;
      const install = el('hc-upload-install')?.checked;
      const overwrite = el('hc-upload-overwrite')?.checked;
      if (uploadPlan.install.length && !install) {
        runtime.notify('Tick “Install these marks” to upload this file.',
          {kind: 'error'});
        return;
      }
      if (uploadPlan.exists && !overwrite) {
        runtime.notify('Tick “Replace the existing file” to overwrite it.',
          {kind: 'error'});
        return;
      }
      const form = new FormData();
      form.append('file', uploadFile, uploadName);
      if (install) form.append('marks', '1');
      if (overwrite) form.append('overwrite', '1');
      const dir = uploadDir;
      const check = uploadCheck;
      const button = el('hc-upload-confirm');
      button.disabled = true;
      el('hc-upload-body').inert = true;
      let answer;
      try {
        const tail = dir.map((part) => encodeURIComponent(part)).join('/');
        const response = await fetch(`${base}/upload/${tail}`, {
          method: 'POST', credentials: 'same-origin', body: form
        });
        answer = await reply(response);
      } catch (cause) {
        if (check !== uploadCheck) return;
        button.disabled = false;
        el('hc-upload-body').inert = false;
        runtime.notify(cause.message, {
          kind: 'error', sticky: true, details: cause.details
        });
        return;
      }
      if (check !== uploadCheck) return;
      closeUpload();
      runtime.notify(
        `Uploaded ${clayText(answer.path)} to %${answer.path[0]}.`);
      refreshDesk(answer.path[0]);
      openFile(answer.path);
    });

    // ---- deleting a version from history ------------------------------
    let tombTarget = null;

    function openTomb(path) {
      if (!path || isNow(path)) return;
      tombTarget = path;
      el('hc-tomb-message').textContent =
        `Delete ${clayText(path)} as of revision ${path[1]} of ` +
        `%${path[0]}?  Clay discards the stored content of this version ` +
        'wherever it is kept, so every revision and path holding the ' +
        'same content shows it as tombstoned.  This cannot be undone.  ' +
        'Clay refuses if any desk still uses this content now.';
      tombDialog.open(el('hc-tomb-cancel'));
    }

    function closeTomb() {
      tombTarget = null;
      tombDialog.close();
    }

    async function acceptTomb() {
      const path = tombTarget;
      if (!path) return;
      closeTomb();
      try {
        await api('tomb', {path}, `${base}/tomb`);
      } catch (cause) {
        runtime.notify(cause.message, {kind: 'error', sticky: true});
        return;
      }
      runtime.notify(`Deleted ${clayText(path)} at revision ${path[1]}.`);
      refreshDesk(path[0]);
    }

    // ---- choosing a revision -----------------------------------------
    let revisionTarget = null;

    function openRevision(view, desk) {
      const control = revisions[view]?.get(desk);
      if (!control) return;
      revisionTarget = {view, desk, control};
      el('hc-revision-title').textContent = `Revision of %${desk}`;
      el('hc-revision-help').textContent =
        `Revisions run from 1 to ${control.head}; ${control.head} is now.`;
      const input = el('hc-revision-input');
      const at = control.current();
      input.value = at >= control.head ? '' : String(at);
      input.placeholder = `now (${control.head})`;
      el('hc-revision-error').hidden = true;
      revisionDialog.open(input);
    }

    function closeRevision() {
      revisionTarget = null;
      revisionDialog.close();
    }

    function acceptRevision() {
      if (!revisionTarget) return;
      const {control, desk} = revisionTarget;
      const text = el('hc-revision-input').value.trim();
      const number = text === '' || text === 'now'
        ? control.head : Number(text);
      const error = el('hc-revision-error');
      if (!Number.isInteger(number) || number < 1 || number > control.head) {
        error.textContent = `%${desk} has no revision ${text}; ` +
          `enter 1 to ${control.head}.`;
        error.hidden = false;
        el('hc-revision-input').focus();
        return;
      }
      closeRevision();
      control.pick(number);
    }

    // ---- the runtime ---------------------------------------------------
    const config = window.urui.config;
    let uploadDialog;
    let revisionDialog;
    let tombDialog;
    const detailHooks = {
      persist: false,
      create: ({path, entry}) => ({
        label: entry === 'file' ? fileTabLabel(path)
          : `${path.slice(2).join('/') || '%' + path[0]}${isNow(path) ? '' : ' rev ' + path[1]}`,
        data: {path: [...path], entry}
      }),
      render: mountAttributes,
      dispose: disposeAttributes
    };
    const runtime = window.urui.runtime({
      refs: {attributes: detailHooks, permissions: detailHooks},
      session: {
        read: (key) => {
          if (key === 'heathcliffTrees') return trees;
          if (key === 'preferences.appsUploadRoot') return appsUploadRoot;
        },
        validate: (key, value) => {
          if (key === 'heathcliffTrees') return validTrees(value);
          if (key === 'preferences.appsUploadRoot') {
            return value === 'root' ? 'root' : 'data';
          }
        }
      },
      contextMenu: {
        items: [
          {id: 'download', label: 'Download',
            title: 'Save this file to this computer'},
          {id: 'attributes', label: 'Attributes…',
            title: 'File or path attributes'},
          {id: 'permissions', label: 'Permissions…',
            title: 'Read and write rules and crews'},
          {id: 'upload', label: 'Upload…',
            title: 'Upload a file into this directory'},
          {id: 'tomb', label: 'Delete', danger: true,
            title: 'Delete this version of the file from history'},
          {id: 'now', label: 'Now',
            title: 'Browse this desk at its current revision'},
          {id: 'revision', label: 'Revision…',
            title: 'Browse this desk at a revision you choose'}
        ],
        state: (target) => {
          const file = target.entry === 'file';
          const current = isNow(target.path);
          const desk = revisions[target.view]?.get(target.path?.[0]);
          const many = (desk?.head || 1) > 1;
          return {
            open: {hidden: !file, disabled: target.tomb},
            download: {hidden: !file, disabled: target.tomb},
            upload: {hidden: file || !current},
            //  history is the only place a file is deleted from here
            delete: {hidden: true},
            tomb: {hidden: !file, disabled: current || target.tomb},
            now: {disabled: !many || desk.current() >= desk.head},
            revision: {disabled: !many}
          };
        },
        select: (id, target) => {
          if (id === 'download') download(target.path);
          else if (id === 'attributes' || id === 'permissions') {
            openAttributes(target.path, target.entry, id);
          }
          else if (id === 'upload') startUpload(target.path, target.view);
          else if (id === 'tomb') openTomb(target.path);
          else if (id === 'now') {
            const desk = revisions[target.view]?.get(target.path[0]);
            desk?.pick(desk.head);
          } else if (id === 'revision') {
            openRevision(target.view, target.path[0]);
          }
        }
      },
      onFile: ({op, phase, path}) => {
        if (phase === 'done' && (op === 'save' || op === 'delete') && path) {
          refreshDesk(path[0]);
        }
      },
      documents: {
        clay: {
          label: (tab) => tab.path ? fileTabLabel(tab.path) : tab.draft,
          beforeSave: async (tab, {path}) => {
            if (isNow(path)) return;
            const current = [path[0], 'now', ...path.slice(2)];
            let head;
            try {
              head = await reply(await fetch(config.files.url, {
                method: 'POST', credentials: 'same-origin',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({op: 'load', path: current})
              }));
            } catch (cause) {
              if (cause.code !== 'not-found') throw cause;
            }
            const accepted = await runtime.confirm('historical-save', {
              message: `Saving ${fileLabel(path)} version ${path[1]} ` +
                'will create a new current version of this file. ' +
                'The historical version will remain unchanged. Continue?'
            });
            return accepted ? {path: current, base: head?.hash ?? null}
              : false;
          },
          afterActivate: () => {
            markActive();
            renderResult();
          },
          loaded: () => renderResult(),
          saved: () => renderResult()
        }
      }
    });
    const uploadSettings = make('fieldset', {class: 'settings-field'},
      make('legend', {class: 'settings-label', text: 'Apps uploads'}));
    const uploadChoices = new Map();
    for (const [value, label] of [
      ['data', 'Apps upload to /data/'],
      ['root', 'Apps upload to /']
    ]) {
      const radio = make('input', {
        type: 'radio', name: 'hc-apps-upload-path', value,
        id: `hc-apps-upload-${value}`
      });
      uploadChoices.set(value, radio);
      radio.addEventListener('change', () => {
        if (!radio.checked) return;
        appsUploadRoot = value;
        runtime.session.queue();
      });
      uploadSettings.append(make('label', {class: 'preference'},
        radio, make('span', {text: label})));
    }
    el('settings-modal').querySelector('.settings-card')
      .append(uploadSettings);
    el('clay-copy').title = 'Copy to clipboard';
    el('clay-copy').setAttribute('aria-label', 'Copy to clipboard');
    uploadDialog = runtime.dialogs.modal(el('hc-upload'), {close: closeUpload});
    revisionDialog = runtime.dialogs.modal(el('hc-revision'), {
      close: closeRevision
    });
    tombDialog = runtime.dialogs.modal(el('hc-tomb'), {close: closeTomb});
    el('hc-tomb-cancel').addEventListener('click', closeTomb);
    el('hc-tomb-ok').addEventListener('click', acceptTomb);
    el('hc-revision-cancel').addEventListener('click', closeRevision);
    el('hc-revision-ok').addEventListener('click', acceptRevision);
    el('hc-revision-input').addEventListener('keydown', (event) => {
      if (event.key !== 'Enter') return;
      event.preventDefault();
      acceptRevision();
    });
    el('hc-download-button').addEventListener('click', () => {
      const path = runtime.documents.active(store)?.path;
      if (path) download(path);
    });
    el('hc-upload-button').addEventListener('click', startUploadPicker);
    runtime.start((saved) => {
      trees = validTrees(saved?.heathcliffTrees);
      appsUploadRoot = saved?.['preferences.appsUploadRoot'] === 'root'
        ? 'root' : 'data';
      uploadChoices.get(appsUploadRoot).checked = true;
    });
    runtime.documents.editor(store)?.onChange?.(() => queueResult());
    window.urui.boot({});
    loadRoots();
    renderResult();
  })();
  '''
--
