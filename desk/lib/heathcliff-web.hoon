::  heathcliff-web: the page, its styles, and its script
::
::    urui owns the frame, panes, tabs, editor, file lifecycle, menus and
::    dialogs.  Heathcliff draws the Apps and Data trees into the views
::    urui seeds, renders the result pane, and runs the attributes and
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
      docs-root=~
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
    codecs     codecs:hc
    fallback   `%view
    locate     `locate:hc
    view       `inspect:hc
    max-bytes  (add limit:hc 65.536)
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
      ['clayTabs' %urui %tabs `%clay]
      ['activeClayTabId' %urui %active `%clay]
      ['nextClayTab' %urui %next `%clay]
      ['heathcliffTrees' %app %record ~]
      ['preferences.theme' %urui %scalar ~]
      ['preferences.layout' %urui %scalar ~]
      ['preferences.keybindings' %urui %scalar ~]
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
      :~  (pinned %head [%heading `'Result' `'result-status' ~])
          %+  pinned  %body
          :^  %panel  'result-body'  ~
          :~  ;div#result-view.hc-result(aria-live "polite");
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
  ^-  marl
  ::  Upload… sits left of Settings, so the toolbar places urui's
  ::  Settings button itself.
  :~  ;nav.toolbar(aria-label "Heathcliff controls")
        ;button#hc-upload-button
          =type   "button"
          =title
            "Upload a file from this computer into the selected ".
            "directory"
          Upload…
        ==
        ;+  settings-button:shell
        ;button#help(type "button", aria-expanded "false"): Help
      ==
  ==
::
++  dialogs
  ::  The attributes and upload dialogs, and the file input Upload uses.
  ^-  marl
  :~  ;aside#hc-attributes.help-panel
        =hidden           ""
        =role             "dialog"
        =aria-modal       "true"
        =aria-labelledby  "hc-attributes-title"
        ;div.help-card.hc-dialog-card
          ;div.pane-header
            ;h2#hc-attributes-title: Attributes
            ;button#hc-attributes-close
              =type        "button"
              =title       "Close file attributes"
              =aria-label  "Close file attributes"
              ; ×
            ==
          ==
          ;div#hc-attributes-body.hc-dialog-body;
        ==
      ==
      ;aside#hc-upload.help-panel
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
        ;p: A desk's revision box browses an older revision, read-only.
        ;p
          ; Right-click an item, or use its … button, for Download,
          ; File or Path attributes…, Upload… and Delete.
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
    flex-wrap: wrap;
    gap: 0.5rem;
    align-items: center;
    color: var(--muted);
    font-size: 0.9em;
  }
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

    //  The selected folder or desk; for a selected file, its folder;
    //  with nothing selected, the active file's folder.  Only at now.
    function uploadTarget() {
      const target = selected[currentView()];
      const tab = runtime.documents.active(store);
      const dir = target
        ? (target.entry === 'file' ? target.path.slice(0, -2) : target.path)
        : tab?.path?.slice(0, -2);
      return dir && isNow(dir) ? dir : null;
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

    function cleanResult() {
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
    const video = new Set(['mp4', 'webm', 'ogv', 'mpeg', 'avi']);
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
      if (!tab) {
        host.replaceChildren(make('p', {
          class: 'hc-note', text: 'Open a file from Apps or Data.'
        }));
        return;
      }
      const path = tab.path;
      const mark = path ? markOf(path) : null;
      const dirty = tab.text !== tab.clean;
      const head = make('div', {class: 'hc-result-head'});
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
      if (path) {
        const button = make('button', {type: 'button', text: 'Download'});
        button.addEventListener('click', () => download(path));
        head.append(button);
      }
      const body = make('div', {class: 'hc-result-body'});
      host.replaceChildren(head, body);
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

    function unavailable(body, tab, why) {
      noted(body, why);
      if (tab.path) {
        const button = make('button', {type: 'button', text: 'Download'});
        button.addEventListener('click', () => download(tab.path));
        body.append(button);
      }
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
      node.addEventListener('error', () => {
        node.remove();
        unavailable(body, tab, 'This browser cannot play this file.');
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
      md: (tab, body) => {
        const previewer = runtime.documents.previews.get('md');
        if (previewer?.render) previewer.render(body, tab.text);
        else source(body, tab.text);
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
        unavailable(body, tab,
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
          unavailable(body, tab, `No preview for ${type || 'this type'}.`);
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
          unavailable(body, tab, 'This browser cannot display this image.');
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
    let attributesTarget = null;
    const attributesModal = el('hc-attributes');

    function closeAttributes() {
      attributesTarget = null;
      attributesDialog.close();
    }

    async function openAttributes(path, entry) {
      attributesTarget = {path, entry};
      el('hc-attributes-body').replaceChildren(make('p', {
        class: 'hc-note', text: 'Loading…'
      }));
      attributesDialog.open(el('hc-attributes-close'));
      await loadAttributes();
    }

    async function loadAttributes() {
      const target = attributesTarget;
      if (!target) return;
      let answer;
      try {
        answer = await api('attributes', {path: target.path});
      } catch (cause) {
        if (attributesTarget !== target) return;
        el('hc-attributes-body').replaceChildren(make('p', {
          class: 'hc-note hc-error', text: cause.message
        }));
        return;
      }
      if (attributesTarget !== target) return;
      renderAttributes(target, answer);
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

    function ruleSection(name, rule, side, current, enforced) {
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
        path: attributesTarget.path, side, clear: cleared,
        mode: mode.value, ships: ships.value, crews: crews.value
      });
      form.addEventListener('submit', (event) => {
        event.preventDefault();
        send(false);
      });
      clear.addEventListener('click', () => send(true));
      section.append(form);
      return section;
    }

    function crewsSection(perms, current) {
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
              if (ok) change('crew-kill', {name: crew.name});
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
          });
        });
        section.append(form);
      }
      const reload = make('button', {
        type: 'button', text: 'Reload crews from clay'
      });
      reload.addEventListener('click', () => change('reload', {}));
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
          'Open attributes further down to see them.'}));
      }
      noted(section,
        'A rule on a path with no files under it cannot be discovered.');
      return section;
    }

    function renderAttributes(target, answer) {
      const body = el('hc-attributes-body');
      const t = answer.target;
      const current = answer.current;
      const noun = t.kind === 'file' ? 'File' : 'Path';
      el('hc-attributes-title').textContent = `${noun} attributes: ${t.label}`;
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
      const perms = answer.permissions;
      const header = make('section');
      header.append(make('h3', {text: 'Permissions'}));
      noted(header, current
        ? 'Clay keeps current rules only.'
        : 'Clay keeps current rules only: these are as of now, not of this ' +
          'revision, and cannot be changed from a historical revision.');
      parts.push(header,
        ruleSection('Read', perms.read, 'read', current, perms.enforced.read),
        ruleSection('Write', perms.write, 'write', current,
          perms.enforced.write),
        explicitSection(perms),
        crewsSection(perms, current));
      body.replaceChildren(...parts);
    }

    async function change(op, body) {
      try {
        await api(op, body);
      } catch (cause) {
        runtime.notify(cause.message, {kind: 'error', sticky: true});
        return;
      }
      runtime.notify(op === 'reload' ? 'Reloading crews.' : 'Sent to clay.');
      //  crews come back as a gift a moment later
      setTimeout(loadAttributes, op === 'rule' ? 50 : 400);
    }

    // ---- upload -------------------------------------------------------------
    const uploadInput = el('hc-upload-input');
    let uploadDir = null;
    let uploadFile = null;
    let uploadPlan = null;

    function startUpload(dir) {
      if (!dir || !isNow(dir)) return;
      uploadDir = dir;
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

    uploadInput.addEventListener('change', async () => {
      const file = uploadInput.files?.[0];
      if (!file || !uploadDir) return;
      uploadFile = file;
      let plan;
      try {
        plan = await api('upload-check', {
          path: uploadDir, filename: file.name, size: file.size,
          nul: await trailingNuls(file)
        });
      } catch (cause) {
        runtime.notify(cause.message, {kind: 'error', sticky: true});
        return;
      }
      uploadPlan = plan;
      showUpload(file, plan);
    });

    function showUpload(file, plan) {
      const body = el('hc-upload-body');
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
      uploadDialog.open(el(plan.problems.length
        ? 'hc-upload-cancel' : 'hc-upload-confirm'));
    }

    function closeUpload() {
      uploadDialog.close();
      uploadFile = null;
      uploadPlan = null;
    }

    el('hc-upload-cancel').addEventListener('click', closeUpload);
    el('hc-upload-confirm').addEventListener('click', async () => {
      if (!uploadFile || !uploadPlan) return;
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
      form.append('file', uploadFile, uploadFile.name);
      if (install) form.append('marks', '1');
      if (overwrite) form.append('overwrite', '1');
      const dir = uploadDir;
      const button = el('hc-upload-confirm');
      button.disabled = true;
      let answer;
      try {
        const tail = dir.map((part) => encodeURIComponent(part)).join('/');
        const response = await fetch(`${base}/upload/${tail}`, {
          method: 'POST', credentials: 'same-origin', body: form
        });
        answer = await reply(response);
      } catch (cause) {
        button.disabled = false;
        runtime.notify(cause.message, {
          kind: 'error', sticky: true, details: cause.details
        });
        return;
      }
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
    let attributesDialog;
    let uploadDialog;
    let revisionDialog;
    let tombDialog;
    const runtime = window.urui.runtime({
      session: {
        read: (key) => (key === 'heathcliffTrees' ? trees : undefined),
        validate: (key, value) => {
          return key === 'heathcliffTrees' ? validTrees(value) : undefined;
        }
      },
      contextMenu: {
        items: [
          {id: 'download', label: 'Download',
            title: 'Save this file to this computer'},
          {id: 'attributes', label: 'File attributes…',
            title: 'Attributes and permissions of this file'},
          {id: 'path-attributes', label: 'Path attributes…',
            title: 'Attributes and permissions of this path'},
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
            attributes: {hidden: !file},
            'path-attributes': {hidden: file},
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
          else if (id === 'attributes' || id === 'path-attributes') {
            openAttributes(target.path, target.entry);
          }
          else if (id === 'upload') startUpload(target.path);
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
          afterActivate: () => {
            markActive();
            renderResult();
          },
          loaded: () => renderResult(),
          saved: () => renderResult()
        }
      }
    });
    attributesDialog = runtime.dialogs.modal(attributesModal, {
      close: closeAttributes
    });
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
    el('hc-attributes-close').addEventListener('click', closeAttributes);
    el('hc-upload-button').addEventListener('click', () => {
      const dir = uploadTarget();
      if (dir) {
        startUpload(dir);
        return;
      }
      runtime.notify('Select a folder or desk at now to upload into.', {
        kind: 'error'
      });
    });
    runtime.start((saved) => {
      trees = validTrees(saved?.heathcliffTrees);
    });
    runtime.documents.editor(store)?.onChange?.(() => queueResult());
    window.urui.boot({});
    loadRoots();
    renderResult();
  })();
  '''
--
