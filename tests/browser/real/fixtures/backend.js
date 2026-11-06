'use strict';

// Playwright double for the %heathcliff HTTP surface.
//
// `installBackend(page, options)` answers `/heathcliff/files` and
// `/heathcliff/api`, which share one json envelope.  Heathcliff's wire
// is wider than urui's four file ops: the page cannot finish booting
// without `roots` and `tree`, so those are answered by default and a
// spec overrides only what it cares about.
//
// Paths on this wire are `[desk, case, ...clay-path]`, with the case
// `now` or a revision number, and the last segment the mark.
//
// `calls` collects every request as `{op, path, body}` in order, so a
// spec can assert what the page sent rather than reaching into the
// runtime's internals.

function json(status, body) {
  return {status, contentType: 'application/json', body: JSON.stringify(body)};
}

function failure(status, code, message) {
  return json(status, {
    ok: false,
    error: {code, message, retryable: false, details: []}
  });
}

//  what the agent would hash; any stable token will do here
function hashOf(text) {
  let hash = 0;
  for (const char of String(text)) {
    hash = (hash * 31 + char.codePointAt(0)) | 0;
  }
  return `0v${(hash >>> 0).toString(32)}`;
}

async function call(handler, argument) {
  return typeof handler === 'function' ? await handler(argument) : handler;
}

const defaultRoots = [{desk: 'base', title: 'Base', rev: 10}];

async function installBackend(page, options = {}) {
  const {
    roots = defaultRoots,
    tree = [],
    load,
    save,
    remove,
    files = {}
  } = options;
  const calls = [];

  await page.route('**/heathcliff/{files,api}', async (route) => {
    const request = route.request();
    const body = JSON.parse(request.postData() || '{}');
    const path = Array.isArray(body.path) ? body.path : [];
    calls.push({op: body.op, path, body});

    if (body.op === 'roots') {
      return route.fulfill(json(200, {
        ok: true, roots: await call(roots, body)
      }));
    }
    if (body.op === 'tree') {
      //  `paths` are desk-relative and filtered by the request's scope;
      //  the desk and case are already in `body`
      const scope = Array.isArray(body.scope) ? body.scope : [];
      const found = (await call(tree, body)) || [];
      const paths = found.filter((entry) => {
        return scope.every((part, index) => entry[index] === part);
      });
      return route.fulfill(json(200, {ok: true, paths, tombs: []}));
    }
    if (body.op === 'browse') {
      const found = (await call(tree, body)) || [];
      const entries = found.map((entry) => {
        return Array.isArray(entry) ? {path: entry, kind: 'file'} : entry;
      });
      return route.fulfill(json(200, {ok: true, entries}));
    }
    if (body.op === 'load') {
      const joined = path.join('/');
      const text = joined in files
        ? files[joined]
        : await call(load, {path, joined, body});
      if (text === undefined) {
        return route.fulfill(failure(404, 'not-found', `${joined} not found`));
      }
      if (typeof text !== 'string') return route.fulfill(text);
      return route.fulfill(json(200, {
        ok: true, text, hash: hashOf(text)
      }));
    }
    if (body.op === 'save') {
      const result = await call(save, {path, body, text: body.text});
      if (result?.status >= 400) {
        return route.fulfill(failure(
          result.status, result.code || 'internal', 'save refused'
        ));
      }
      return route.fulfill(json(200, {ok: true, hash: hashOf(body.text)}));
    }
    if (body.op === 'delete') {
      const result = await call(remove, {path, body});
      if (result?.status >= 400) {
        return route.fulfill(failure(
          result.status, result.code || 'internal', 'delete refused'
        ));
      }
      return route.fulfill(json(200, {ok: true}));
    }
    //  markdown, attributes, rule, upload-check and the rest are only
    //  reached by a spec that asks for them
    return route.fulfill(json(200, {ok: true}));
  });

  return {
    calls,
    sent: (op) => calls.filter((entry) => entry.op === op)
  };
}

module.exports = {installBackend, hashOf};
