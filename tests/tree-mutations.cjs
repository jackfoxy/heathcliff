const assert = require('node:assert/strict');

module.exports = async function checkTreeMutations(browser, origin) {
  const page = await browser.newPage();
  const errors = [], deletes = [], tombRequests = [], treeRequests = [];
  let head = 7, current, historical, tombs, invalidPaths, failListing = false;
  let hold = false, release;
  const reset = () => {
    current = new Map([
      ['notes/a/txt', 'current-a'], ['notes/blocked/txt', 'blocked'],
      ['notes/sub/b/png', 'current-b'], ['notes/sub/unknown/weird', 'unknown'],
      ['other/stay/txt', 'protected']
    ]);
    historical = new Map([
      ['notes/a/txt', 'old-a'], ['notes/sub/b/png', 'current-b'],
      ['notes/shared-one/txt', 'shared-old'], ['notes/shared-two/txt', 'shared-old'],
      ['notes/protected/txt', 'protected'], ['notes/gone/txt', 'gone']
    ]);
    tombs = new Set(['gone']);
    invalidPaths = undefined;
    deletes.length = tombRequests.length = 0;
  };
  reset();
  page.on('pageerror', error => errors.push(error.message));
  await page.route('**/heathcliff/{api,files,tomb,delete-tree}', async route => {
    const data = route.request().postDataJSON();
    const reply = (body, status = 200) => route.fulfill({status,
      contentType: 'application/json', body: JSON.stringify(body)});
    const fail = (message, status = 409) => reply({ok: false,
      error: {code: 'refused', message}}, status);
    const key = data.path?.slice(2).join('/');
    if (data.op === 'roots') return reply({ok: true,
      roots: [{desk: 'base', title: 'Base', rev: head}]});
    if (data.op === 'tree') {
      treeRequests.push(data);
      if (failListing) return fail('Cannot list selected path', 500);
      const source = data.case === 'now' ? current : historical;
      const paths = invalidPaths || [...source.keys()].map(path => path.split('/'))
        .filter(path => data.scope.every((part, i) => path[i] === part));
      return reply({ok: true, paths,
        tombs: paths.filter(path => tombs.has(source.get(path.join('/'))))});
    }
    if (data.op === 'load') {
      const source = data.path[1] === 'now' ? current : historical;
      if (!source.has(key)) return fail('Not found', 404);
      return reply({ok: true, text: source.get(key), hash: source.get(key)});
    }
    if (data.op === 'delete') throw new Error('Tree deletion must not issue single-file deletes');
    if (data.op === 'delete-tree') {
      deletes.push(data);
      if (hold) {
        hold = false;
        await new Promise(resolve => { release = resolve; });
      }
      if (data.path[1] !== 'now') return fail('Historical delete forbidden');
      if (data.paths.some(path => path.includes('uncertain'))) return route.abort('failed');
      const deleted = [], skipped = [];
      for (const path of data.paths) {
        assert(data.path.every((part, i) => path[i] === part));
        const key = path.slice(2).join('/');
        if (key.includes('blocked')) skipped.push({path, message: 'Cannot delete blocked file'});
        else if (!current.has(key)) skipped.push({path, message: 'file no longer exists'});
        else deleted.push(path);
      }
      for (const path of deleted) current.delete(path.slice(2).join('/'));
      if (deleted.length) head += 1;
      return reply({ok: true, deleted, skipped, revision: head});
    }
    if (data.op === 'tomb') {
      tombRequests.push(data.path);
      if (data.path[1] !== '2') return fail('Only historical revisions');
      const value = historical.get(key);
      if (tombs.has(value)) return fail('that version is already tombstoned', 400);
      if (current.get(key) === value) return fail('Same content as the current file');
      if ([...current.values()].includes(value)) return fail('Still used by another current file');
      tombs.add(value);
      return reply({ok: true});
    }
    return reply({ok: true, entries: []});
  });
  const menu = async (revision = 'now', scope = ['notes'], entry = 'directory') => {
    await page.evaluate(({revision, scope, entry}) => {
      window.hcTest.runtime.explorer.context.open('clay', ['base', revision, ...scope],
        document.getElementById('apps-tab'), undefined, {entry, view: 'apps'});
    }, {revision, scope, entry});
  };
  const item = label => page.getByRole('menuitem', {name: label, exact: true});
  const start = async (revision = 'now', scope = ['notes'], entry) => {
    await menu(revision, scope, entry);
    await item(revision === 'now' ? 'Delete' : 'Tombstone').click();
  };
  const toast = text => page.locator('#urui-toast-message').getByText(text).waitFor();
  try {
    await page.goto(origin + '/heathcliff');
    await page.waitForFunction(() => window.hcTest);
    await start();
    await page.locator('#urui-confirm').waitFor({state: 'visible'});
    const warning = await page.locator('#urui-confirm-message').innerText();
    assert.match(warning, /Delete 4 files under \/base\/notes\//);
    assert.match(warning, /may be partially successful/);
    assert.match(warning, /cannot be deleted will be left as is/);
    assert.match(warning, /one new revision/);
    assert.match(warning, /If the commit fails, none/);
    await page.locator('#urui-confirm-cancel').click();
    assert.equal(deletes.length, 0);

    await page.evaluate(async () => {
      const docs = window.hcTest.runtime.documents;
      await docs.open('clay', ['base', '2', 'notes', 'a', 'txt']);
      await docs.open('clay', ['base', 'now', 'notes', 'blocked', 'txt']);
      await docs.open('clay', ['base', 'now', 'notes', 'a', 'txt']);
      docs.editor('clay').setSource('unsaved edits');
    });
    await start();
    await page.locator('#urui-confirm').waitFor({state: 'visible'});
    current.set('notes/new/txt', 'added after listing');
    hold = true;
    await page.locator('#urui-confirm-ok').click();
    await toast(/Deleting 4 files in one revision/);
    await menu();
    assert(await item('Delete').isDisabled());
    await page.evaluate(() => window.hcTest.runtime.explorer.context.close());
    release();
    await toast('Delete finished: 3 succeeded, 1 failed or unconfirmed, 0 already tombstoned. Successful changes remain. Check the listed files before retrying.');
    assert.equal(head, 8);
    assert.equal(deletes.length, 1);
    assert.equal(deletes[0].paths.length, 4);
    assert(deletes[0].paths.every(path => path[1] === 'now' && path[2] === 'notes'));
    assert.deepEqual([...current.keys()], ['notes/blocked/txt', 'other/stay/txt', 'notes/new/txt']);
    assert.equal(historical.get('notes/a/txt'), 'old-a');
    assert.match(await page.locator('#urui-toast-details').innerText(), /notes\/blocked\/txt: Cannot delete/);
    const tabs = await page.evaluate(() => window.hcTest.runtime.documents.list('clay'));
    assert(tabs.some(tab => tab.path === null && tab.text === 'unsaved edits'));
    assert(tabs.some(tab => tab.path?.join('/') === 'base/now/notes/blocked/txt'));
    assert(tabs.some(tab => tab.path?.join('/') === 'base/2/notes/a/txt'));

    reset();
    await start('2');
    await page.locator('#urui-confirm').waitFor({state: 'visible'});
    const tombWarning = await page.locator('#urui-confirm-message').innerText();
    assert.match(tombWarning, /Tombstone 5 files/);
    assert.match(tombWarning, /cannot be tombstoned will be left as is/);
    assert.match(tombWarning, /cannot be undone/);
    assert.match(tombWarning, /other historical paths/);
    assert.match(tombWarning, /1 already-tombstoned/);
    await page.locator('#urui-confirm-cancel').click();
    assert.equal(tombRequests.length, 0);
    await start('2');
    await page.locator('#urui-confirm-ok').click();
    await toast(/Tombstone finished: 2 succeeded, 2 failed or unconfirmed, 2 already tombstoned/);
    assert.equal(head, 8);
    assert.equal(tombRequests.length, 5);
    assert(tombRequests.every(path => path[1] === '2' && path[2] === 'notes'));
    assert(tombs.has('old-a') && tombs.has('shared-old'));
    assert(!tombs.has('current-b') && !tombs.has('protected'));
    assert.equal(current.get('notes/a/txt'), 'current-a');
    assert.equal(historical.size, 6);
    const failures = await page.locator('#urui-toast-details').innerText();
    assert.match(failures, /Same content/);
    assert.match(failures, /Still used/);

    await start('2', ['notes', 'sub']);
    await page.locator('#urui-confirm-ok').click();
    await toast(/Tombstone finished: 0 succeeded, 1 failed or unconfirmed/);
    assert(!tombs.has('current-b'));
    historical = new Map([['old/txt', 'old-a']]);
    await start('2', [], 'root');
    await toast(/No files to tomb.*1 already tombstoned/);
    assert(await page.locator('#urui-confirm').isHidden());
    historical = new Map([['old/txt', 'other-old'], ['sub/file/txt', 'also-old']]);
    await start('2', [], 'root');
    await page.locator('#urui-confirm-ok').click();
    await toast(/Tombstone finished: 2 succeeded, 0 failed or unconfirmed/);
    assert(tombs.has('other-old') && tombs.has('also-old'));
    assert.equal(head, 8);

    await start('now', ['missing']);
    await toast(/No files to delete/);
    await start('2', ['missing']);
    await toast(/No files to tomb/);
    assert(await page.locator('#urui-confirm').isHidden());
    const before = deletes.length;
    for (const path of [['other', 'stay', 'txt'], ['notes', '..', 'bad', 'txt']]) {
      invalidPaths = [path];
      await start();
      await toast(/Invalid file path.*nothing was changed/);
      assert.equal(deletes.length, before);
    }
    invalidPaths = undefined;
    failListing = true;
    await start();
    await toast('Cannot list selected path');
    assert.equal(deletes.length, before);
    failListing = false;

    current = new Map([['blocked', 'no']].map(([name, value]) => [`${name}/txt`, value]));
    await start('now', [], 'root');
    await page.locator('#urui-confirm-ok').click();
    await toast(/Delete finished: 0 succeeded, 1 failed or unconfirmed/);
    assert(current.has('blocked/txt'));
    assert.equal(head, 8);
    current = new Map([['one/txt', '1'], ['uncertain/txt', '?'], ['two/txt', '2']]);
    await start('now', [], 'root');
    await page.locator('#urui-confirm-ok').click();
    await toast(/Failed to fetch/);
    assert.match(await page.locator('#urui-toast-message').innerText(), /refresh the tree before retrying/);
    assert.deepEqual([...current.keys()], ['one/txt', 'uncertain/txt', 'two/txt']);
    assert.equal(head, 8);
    current = new Map([['one/txt', '1'], ['sub/two/txt', '2']]);
    await start('now', [], 'root');
    await page.locator('#urui-confirm-ok').click();
    await toast(/Delete finished: 2 succeeded, 0 failed or unconfirmed/);
    assert.equal(current.size, 0);
    assert.equal(head, 9);
    assert(treeRequests.some(request => request.scope.length === 0));
    assert.deepEqual(errors, []);
    console.log('PASS tree Delete/Tombstone: recursive scope, warnings, cancel, mixed/all/no success, shared/protected content, revisions, drafts, frozen listing and failures');
  } finally { await page.close(); }
};
