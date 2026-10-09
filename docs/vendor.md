# Preview dependencies

- `desk/lib/markdown.hoon`, `desk/sur/markdown.hoon`: unchanged from
  [tinnus-napbus/urbit-markdown](https://github.com/tinnus-napbus/urbit-markdown),
  commit `75f6922e7d` (2026-07-23). Heathcliff keeps its existing `%md` mark;
  previewing does not rewrite file contents. `heathcliff-markdown` restricts
  the rendered HTML tags, attributes, and URL schemes.
- `desk/web/mediainfo/`: [mediainfo.js](https://mediainfo.js.org/) 0.3.8,
  npm package `mediainfo.js-0.3.8.tgz`. `index.js` is the ESM minified bundle;
  `module.atom` is the unmodified `MediaInfoModule.wasm`, stored with the
  existing atom mark. License: adjacent `license.txt`. Both assets are served
  by Heathcliff; no CDN or external service is used at runtime.

Metadata inspection runs in a disposable browser worker, on demand when
opening file attributes. It reports fields present in the file, not codecs
guessed from filename extensions. Each reference tab owns its inspection;
closing the tab cancels it. Unknown formats retain their ordinary attributes
and permissions.
Markdown previews accept up to 64 KiB of source; larger documents remain
editable and show their source with a preview-limit message. Media metadata
inspection accepts up to 64 MiB and times out after 20 seconds.
