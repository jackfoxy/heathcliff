# Heathcliff on urui: design record

Companion to `~/FoxyLabs/heathcliff/urui-refactor-plan.md` (steps 1.1–1.3).
Reference `%base` is `/mnt/mars/piers/newcomet/base` (`[%zuse 408]`).

## 1. Mark audit (step 1.1)

Every `desk/mar/*.hoon` (51 files) was read: sample, `grab`, `grow`, `grad`.
Marks shared with `%base` are byte-identical to it after step 0.1.

### Representation classes

| Class | Marks | Stored noun | Mime round trip |
| --- | --- | --- | --- |
| atom bytes | aac atom avi bmp flac gif ico jam jpeg jpg mid mp3 mp4 mpeg oga ogg ogv pdf png svg tiff wav weba webm webp | `@` | loses trailing NUL bytes (`met`) |
| octs bytes | otf ttf woff2 | `octs` | byte-exact |
| envelope | mime | `[mite octs]` | byte-exact; no mark build |
| cord text | hoon css js html xml udon umd map | `@t` (`js`/`map`/`svg` sample `@`) | byte-exact for UTF-8 |
| line text | txt csv tab md pem | `wain` | trailing newline needs `storage-wain` |
| json | json | `json` | canonical re-encoding |
| conversion text | bill docket-0 kelvin ship | structured noun | canonical re-printing via `grow mime` / `grab mime` |
| structured | hymn urb (`manx`), snip (`[marl marl]`), noun (`*`), txt-diff (`(urge cord)`) | noun | `grow mime` only, no `grab mime` (not editable) |

`%base` `md` is a `wain` mark (`text/plain`); Heathcliff's old `md` was `@t`.
Other desks may still carry an `@t` `md`; such files fall back to read-only
inspection (§3, `fallback`).

### Per-mark policy (implemented baseline)

Codec names are urui-files codecs (§3). Result pane is Heathcliff's renderer.

| Mark | Codec → editor | Result pane |
| --- | --- | --- |
| txt | `wain`, editable | escaped text |
| csv | `wain`, editable | bounded table, RFC 4180 quoting |
| tab | `wain`, editable | bounded table, tab-split |
| md | `wain`, editable | urui's sanitized Markdown renderer |
| pem | `wain`, editable | escaped PEM blocks with labels; nothing transmitted |
| hoon | `cord`, editable, plain text mode | escaped source |
| css | `cord`, editable | escaped source; never applied |
| js | `cord`, editable | escaped source; never evaluated |
| html | `cord`, editable | urui's sandboxed `srcdoc` iframe |
| svg | `cord`, editable | `<img>` of a `Blob` of the buffer (no script execution) |
| xml | `cord`, editable | `DOMParser` tree, parse errors shown |
| udon, umd | `cord`, editable | escaped source (no verified UdON renderer in-browser) |
| map | `cord`, editable | source-map JSON formatted when it parses, else source |
| json | `json`, editable; invalid JSON refused on save (422) | formatted, collapsible JSON |
| bill | `mime` conversion, editable | parsed agent list (no activation) |
| docket-0 | `mime` conversion, editable | docket clauses as a field list |
| kelvin | `mime` conversion, editable | parsed `[%zuse n]` lines |
| ship | `mime` conversion, editable | validated `@p` |
| png jpg jpeg gif bmp webp ico tiff | `view`, read-only placeholder | `<img>` from the raw route; tiff notes browser support |
| mp3 wav ogg oga flac aac weba | `view`, read-only placeholder | `<audio controls>` from the raw route |
| mp4 webm ogv mpeg avi | `view`, read-only placeholder | `<video controls>`; unsupported-codec fallback |
| mid | `view`, read-only placeholder | Download; states no native playback |
| otf ttf woff2 | `view`, read-only placeholder | scoped `FontFace` specimen |
| pdf | `view`, read-only placeholder | iframe of the raw route; Download fallback |
| atom | `view`, hex + escaped bytes (bounded) | same, with byte count |
| jam | `view`, hex (bounded) | hex; Download (no `cue` in browser) |
| noun | `view`, bounded pretty-print | same; Download gives jam bytes |
| mime | `view`, stored type + length + bounded hex | dispatch on stored type: image/audio/video/text, active types in a sandboxed frame |
| hymn, urb | `view`, rendered XML text | sandboxed iframe of the raw route's HTML conversion |
| snip | `view`, rendered XML text | sandboxed iframe of the raw route's HTML conversion |
| txt-diff | `view`, hunks listed | same; no base document inferred |
| any other mark | `view`, bounded noun or bytes | Download when a mime conversion is known |

## 2. Clay and transfer audit (step 1.2)

- **Write rules are not enforced.** `may-write` is defined at
  `sys/vane/clay.hoon:4055` and has no callers; `may-read` is used
  (`:4373`). Heathcliff states this in the modal; a write rule is shown as
  a record, never as a control.
- **`%info` has no success gift.** A rejected commit crashes inside Clay
  and nothing comes back. Writes are therefore verified the urui way: a
  `%warp %next %x` placed before the `%info`, a `%wait` timeout, and a
  read-back comparison.
- **Permissions are current only.** `%cp` ignores the case (`read-p` takes a
  path). Historical targets show current rules, labelled, read-only.
- **Tombstones**: `%cy` still lists a tombstoned file; `%cx`/`%cq` on it
  crash the event. Every read checks `/=//=/tomb` first.
- **Trailing NUL**: atom marks drop trailing zero bytes; `mime`, `otf`,
  `ttf`, `woff2` keep `octs`. Upload refuses trailing NULs only for atom
  marks (old code refused every non-`mime` mark).
- **Zero-byte uploads**: an empty atom round-trips as 0 bytes, and empty
  text marks decode to empty text. Allowed when the mark's `mime → mark`
  conversion accepts the empty body (checked before commit); the old blanket
  refusal is removed.
- **Mark installs**: a missing mark and its `+kin` dependencies are copied
  from `%base` when it has the mark, else from Heathcliff's `mar/`; an
  existing target mark is never replaced. Conversion is validated with the
  source desk's tube before commit.
- **Old upload/edit flows answered before Clay did** (303 redirect after
  dispatch). Replaced by verified writes.
- **Cliff** (`paldev-suite/app/cliff.hoon`, 1413 lines) is Heathcliff's
  ancestor: same `%1` state and permission arms (`pear`, `sown`, `owns`,
  `gist`, `grant`, `crew-*`). Its `dile`/`free`/`peak` are page helpers
  replaced by Heathcliff's tree. Nothing to port.

## 3. Integration (step 1.3)

### Document identity

A Heathcliff document is the urui path `[desk case ...clay-path]`, where
`case` is `now` or a revision number, and the clay path ends in name and
mark. `now` documents are live and editable; numbered ones are read-only
snapshots. A revision number only ever appears beside its own desk, so it
cannot carry to another desk. Apps and Data open the same path for the same
file, and urui's store opens one tab per path.

The desk segment is resolved by Heathcliff's `locate` gate on the server,
never by urui on Heathcliff's own desk.

### urui changes (generic, additive; Obelisk and Graph Viz unchanged)

Server, `lib/urui-files.hoon`:

1. `policy` gains `fallback=(unit codec)`, `locate=(unit $-(...))`, and
   `view=(unit $-(...))`, appended so `make-policy` callers are unaffected.
   - `locate`: wire path → `[beak rel write]` or a failure. `~` keeps the
     old behaviour (our desk, now, under `root`).
   - `fallback`: codec for marks absent from `codecs`.
   - `view`: text for a read-only `%view` file from its stored noun.
2. Codecs gain `%mime` (text through the file desk's own mark conversion,
   validated before the `%info`) and `%view` (read-only).
3. A root with `marks=~` admits any mark.
4. A file whose stored noun does not decode under its codec loads through
   `view` as read-only, when `view` is set.
5. `load` answers `readonly: true` for `%view` files and unwritable
   locations; `save`/`delete` there refuse with `read-only` (403).

Browser, `lib/urui-js.hoon`:

1. A root with no marks admits any mark (`docRootOf`).
2. `readonly` from `load` is kept on the tab, persisted, and makes that tab
   read-only exactly like a `save=|` root.
3. Context menu: `options.contextMenu = {items, state(target), select(id,
   target)}` appends consumer items to `#file-context-menu`;
   `explorer.context.open(store, path, source, event, detail)` carries
   `detail` into the target; `state` can hide or disable any item,
   built-ins included.
4. `runtime.dialogs.modal(element, {close, fallback})` puts a consumer
   dialog on urui's modal controller (focus trap, Escape, inert page,
   shortcut swallowing).
5. `runtime.documents.previews.get(mark)` returns a registered previewer so
   a consumer can draw it into its own result pane.

### Heathcliff layout

- One store `clay`: root `[~ ~ ~ &]`, actions `%save %copy`, `preview=~`,
  no drafts, no Save As. Editor pane `%read-write`; result pane `%read-only`
  with a `%panel` band Heathcliff renders.
- Reference pane: `%views` level, `fixed=~[apps data]`. Heathcliff draws
  both trees into `#apps-tree` and `#data-tree` (no urui `$tree`), using
  urui's tree classes, its context menu, and `documents.open`.
- Tree data from Heathcliff's own JSON route: desks sorted by
  case-insensitive display name (docket `title` read from
  `/desk/docket-0` with `%cq`, else desk name), desk tie-break; per desk
  `%ct` at the chosen case, lazily on first expand. Data uses scope
  `/data` and shows an empty state when it has no files.
- Context menu items: Open (files), Download (files), File attributes…
  (all), Upload… (current directories and roots), Delete (current files).
  Every row has an item-actions button.

### Routes (all under `/heathcliff`, authenticated)

| Route | Use |
| --- | --- |
| `GET /heathcliff` | the page |
| `GET /heathcliff/ace/...`, `/heathcliff/app.js`, `/heathcliff/app.css` | assets |
| `POST /heathcliff/files` | urui file wire |
| `POST /heathcliff/api` | tree, attributes, permissions, crews, upload check |
| `GET /heathcliff/raw/<desk>/<case>/<path>` | raw bytes for previews; `?download` adds attachment; `?as=html` for hymn/urb/snip |
| `POST /heathcliff/upload/<desk>/<path>` | multipart upload, verified |

Old `/heathcliff/{view,edit,perm,down,load}/...` routes are removed with no
redirect. Raw responses carry `x-content-type-options: nosniff` and
`content-security-policy: sandbox`; active types are always attachments
unless converted for a sandboxed preview.

### Libraries and state

- `lib/heathcliff-clay.hoon`: desks, titles, sorting, cases, scries, marks
  (`ctype`, `kin`, `splt`, `safe`, mark source), file policy and `view`.
- `lib/heathcliff-perm.hoon`: rules, scan, crews, ship parsing, JSON.
- `lib/heathcliff-transfer.hoon`: upload planning and download payloads.
- `lib/heathcliff-web.hoon`: shell spec, config, css, app-js.
- `app/heathcliff.hoon`: routing, auth, cards, `on-arvo`.
- State `%2` = `%1` plus non-persisted pending file and upload writes; `%0`
  and `%1` load forward keeping `cez`/`use`, then re-mirror.

## Questions

None open.
