# Preview checks

The browser check uses the sibling `urui` checkout's existing `vere eval`
helpers and Playwright installation. Set `URUI_ROOT` to use another checkout,
and `VERE` if the Urbit binary is not at `~/piers/urbit`.

```sh
node tests/previews.cjs
node tests/mov-mark.cjs
node ../urui/bin/hoon-test.js . desk/tests/lib/heathcliff-markdown.hoon
node ../urui/bin/hoon-test.js . desk/tests/lib/heathcliff-api.hoon
node ../urui/bin/hoon-test.js . desk/tests/lib/heathcliff-clay.hoon
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
