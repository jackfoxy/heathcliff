# Preview checks

The browser check uses the sibling `urui` checkout's existing `vere eval`
helpers and Playwright installation. Set `URUI_ROOT` to use another checkout,
and `VERE` if the Urbit binary is not at `~/piers/urbit`.
The ZIP-fallback checks also require `unzip` for independent CRC and content
validation of browser-generated downloads.
Set `HOON_EVAL_TIMEOUT_MS` above 180000 if compiling the browser assets
needs more time on the test machine.

```sh
node tests/previews.cjs
node tests/batch-delete-agent.cjs
node tests/mov-mark.cjs
node tests/archive-marks.cjs
node tests/heic-sh-marks.cjs
node tests/m4a-mark.cjs
node ../urui/bin/hoon-test.js . desk/tests/lib/heathcliff-markdown.hoon
node ../urui/bin/hoon-test.js . desk/tests/lib/heathcliff-api.hoon
node ../urui/bin/hoon-test.js . desk/tests/lib/heathcliff-clay.hoon
node ../urui/bin/hoon-test.js . desk/tests/lib/heathcliff-delete.hoon
node ../urui/bin/hoon-test.js . desk/tests/lib/heathcliff-batch-delete.hoon
node ../urui/bin/hoon-test.js . desk/tests/lib/heathcliff-transfer.hoon
node ../urui/bin/hoon-test.js . desk/tests/lib/urui-files.hoon
```

The browser check compiles the actual page and script, serves them on a
temporary localhost port with fixture API responses, and uses real MediaInfo
workers. It checks full metadata output and duplicate filtering for WAV, MOV, WebM
(VP8/Opus), PNG, SVG, `%mime`, tombstones, reference
tabs, current/historical file labels, read-only metadata, separate Attributes
and Permissions menus/tabs, rule submission targets, and Markdown display and
error fallback. Historical-file checks cover double-click opening, version
labels, editable text, save confirmation/cancellation, writing to `now`,
and concurrent-write conflicts. Upload checks cover the Apps prefix setting, defaults,
persistence, unchanged context-menu/Data destinations, and the toolbar's
destination tree, typed paths, mark validation, stale checks, and renamed
multipart uploads.
Folder-upload checks cover recursive destination paths, normalized-name
collisions, invalid paths, archive bytes, mark/replacement consent, stale
checks, cancellation, and stopping after a partial failure. Archive-mark
checks compile the actual ZIP/RAR marks and verify MIME/raw download
round trips, filename extensions, empty files, and trailing NUL bytes.
Tree-transfer checks cover frozen context-menu destinations for single-file
and folder uploads, Download button placement, unchanged single downloads,
and recursive directory downloads at pinned current or historical revisions.
An in-memory directory-picker fixture verifies byte preservation, nested
paths, external filenames, tombstone exclusion, overwrite consent, picker
cancellation/permissions/support, invalid paths, collisions, disk/network
failures, and retained partial results. The native operating-system picker
itself is not automated.
ZIP-fallback checks use a non-localhost HTTP origin with the directory picker
genuinely unavailable. They verify downloaded ZIPs with `unzip`, covering
nested paths, exact binary bytes, empty files/trees, current/historical
revisions, tombstone filtering, light/dark green progress, archive limits,
and no partial archive on fetch, path, or collision errors.
HEIC/SH checks compile their marks and verify PNG-compatible byte handling,
text/MIME round trips, and text diff delegation. Filename checks cover
spaces, underscores, punctuation, Unicode, uppercase extensions, typed
destinations, and nested-folder names in both Hoon and browser flows.
M4A checks cover MP4-compatible storage, audio MIME round trips, downloads,
upload validation, and the browser's audio-preview controls.
New-file checks cover button placement, preserving other drafts, empty-file
saves, desk/folder navigation, partial and newly typed nested paths,
cancellation, and confirmed replacement of an existing file.
Delete/tombstone checks cover current versus historical menu availability,
directories, confirmation and cancellation, failed requests, binary deletion,
unsaved drafts, advancing the displayed revision, preserving historical files,
unchanged current content, shared content, and already-tombstoned files.
Recursive Delete/Tombstone checks cover desk and nested-folder scope,
partial-success warnings and cancellation, continued processing after
Tombstone refusals, all-success/all-failure/empty batches, protected
and shared historical content, already-tombstoned skips, one revision per
Delete batch, no revision for an empty eligible set, unconfirmed batch failures,
preserved dirty drafts and failed-file tabs, captured file
lists, invalid paths, listing failures, and batch reentry protection.
The browser uses a versioned API fixture. Hoon tests exercise the real delete
and tombstone code against virtual Clay reads, assert the exact commit cards,
and check success, verification failures, timeouts, missing files/desks,
invalid/current revision numbers, stale hashes, and pending changes.
The batch suite checks one multi-delete Clay commit, deduplication, skipped
missing files, scope validation, all-file verification, timeouts, and late
responses. The Gall check compiles the real agent with empty static assets
and checks batch-route authentication, validation, and saved-state compatibility.
Help checks load the real `doc.toc`, open each documentation topic, restore
documentation tabs after reload, and verify fallback help without `/docs`.
Hoon suites check real Markdown parsing, sanitization, and
the API contract. No ship is changed.

The MOV mark check loads `desk/mar/mov.hoon` directly and verifies MIME
round trips with 6,645 trailing NUL bytes, all-zero data, and empty files.
`fixtures/sample.mov` is a generated 32×24 red H.264 QuickTime movie:

```sh
ffmpeg -f lavfi -i color=c=red:s=32x24:d=0.2 -an \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart -f mov tests/fixtures/sample.mov
```

`fixtures/sample.webm` is a generated 32×24 red video with silent stereo audio:

```sh
ffmpeg -f lavfi -i color=c=red:s=32x24:d=0.2 \
  -f lavfi -i anullsrc=r=48000:cl=stereo -shortest \
  -c:v libvpx -c:a libopus tests/fixtures/sample.webm
```
