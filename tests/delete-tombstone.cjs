const assert = require('node:assert/strict');

// Browser behavior against a versioned fixture; real backend cards and
// refusals are checked in heathcliff-delete/transfer.hoon and urui-files.hoon.
module.exports = async function checkDeletion(browser, origin) {
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  let head = 3;
  const versions = new Map([
    ['2', new Map([['note.txt', 'old'], ['same.txt', 'same'],
      ['shared.txt', 'shared'], ['gone.txt', 'gone']])],
    ['3', new Map([['note.txt', 'current'], ['same.txt', 'same'],
      ['picture.png', 'image'], ['keep.txt', 'keep']])]
  ]);
  const tombs = new Set(['gone']);
  const deletes = [], tombRequests = [];
  let refuseDelete = false;
  await page.route('**/heathcliff/{api,files,tomb}', async route => {
    const data = route.request().postDataJSON();
    const reply = (body, status = 200) => route.fulfill({
      status, contentType: 'application/json', body: JSON.stringify(body)
    });
    const fail = (message, status = 409) =>
      reply({ok: false, error: {code: 'in-use', message}}, status);
    const latest = versions.get(String(head));
    const key = data.path?.slice(2).join('.');
    if (data.op === 'roots') return reply({ok: true,
      roots: [{desk: 'base', title: 'Base', rev: head}]});
    if (data.op === 'tree') {
      const files = versions.get(data.case === 'now' ? String(head) : data.case);
      const paths = [...files.keys()].map(key => key.split('.'));
      return reply({ok: true, rev: head, case: data.case, paths,
        tombs: paths.filter(path => tombs.has(files.get(path.join('.'))))});
    }
    if (data.op === 'load') {
      const files = versions.get(data.path[1] === 'now' ? String(head) : data.path[1]);
      const text = files?.get(key);
      if (text === undefined || tombs.has(text)) return fail('File not found', 404);
      return reply({ok: true, text, hash: text, readonly: key.endsWith('.png')});
    }
    if (data.op === 'delete') {
      deletes.push(data);
      if (refuseDelete) return fail('Delete verification failed', 500);
      if (data.path[1] !== 'now') return fail('Historical revision', 403);
      if (!latest.has(key)) return fail('File not found', 404);
      const next = new Map(latest);
      next.delete(key);
      versions.set(String(++head), next);
      return reply({ok: true});
    }
    if (data.op === 'tomb') {
      tombRequests.push(data);
      if (data.path[1] === 'now' || Number(data.path[1]) >= head)
        return fail('Only prior revisions can be tombstoned', 400);
      const content = versions.get(data.path[1])?.get(key);
      if (content === undefined) return fail('No file at that revision', 400);
      if (tombs.has(content)) return fail('Already tombstoned', 400);
      if ([...latest.values()].includes(content))
        return fail('This version has the same content as the current file');
      if (content === 'shared') return fail('Content is still used by another desk');
      tombs.add(content);
      return reply({ok: true});
    }
    return route.fallback();
  });
  try {
    await page.goto(origin + '/heathcliff');
    await page.waitForFunction(() => window.hcTest);
    const menu = (revision, name = 'note.txt', entry = 'file', tomb = false) =>
      page.evaluate(({revision, name, entry, tomb}) => {
        window.hcTest.runtime.explorer.context.open('clay',
          ['base', revision, ...name.split('.')],
          document.getElementById('apps-tab'), undefined,
          {entry, tomb, view: 'apps'});
      }, {revision, name, entry, tomb});
    const item = name => page.getByRole('menuitem', {name, exact: true});
    for (const entry of ['root', 'directory']) {
      for (const rev of ['now', '2']) {
        await menu(rev, 'note.txt', entry);
        assert.equal(await item('Delete').count(), rev === 'now' ? 1 : 0);
        assert.equal(await item('Tombstone').count(), rev === 'now' ? 0 : 1);
      }
    }
    await menu('now');
    assert(await item('Delete').isEnabled());
    assert.equal(await item('Tombstone').count(), 0);
    assert.equal(await item('Open').innerText(), 'Open');
    await item('Delete').click();
    assert.match(await page.locator('#urui-confirm-message').innerText(), /new revision/);
    await page.locator('#urui-confirm-cancel').click();
    assert.equal(deletes.length, 0);
    assert.equal(head, 3);

    await page.evaluate(async () => {
      await window.hcTest.runtime.documents.open('clay', ['base', '2', 'note', 'txt']);
      await window.hcTest.runtime.documents.open('clay', ['base', 'now', 'note', 'txt']);
      window.hcTest.runtime.documents.editor('clay').setSource('unsaved note');
    });
    refuseDelete = true;
    await menu('now');
    await item('Delete').click();
    await page.locator('#urui-confirm-ok').click();
    await page.getByText('Delete verification failed', {exact: true}).waitFor();
    assert.equal(head, 3);
    assert.deepEqual(await page.evaluate(() =>
      window.hcTest.runtime.documents.active('clay').path), ['base', 'now', 'note', 'txt']);
    refuseDelete = false;
    await menu('now');
    await item('Delete').click();
    await page.locator('#urui-confirm-ok').click();
    await page.waitForFunction(() => window.hcTest.runtime.documents.active('clay').path === null);
    assert.equal(await page.evaluate(() => window.hcTest.runtime.documents.active('clay').text), 'unsaved note');
    assert.deepEqual(await page.evaluate(() =>
      window.hcTest.runtime.documents.list('clay').find(tab => tab.path?.[1] === '2').path),
    ['base', '2', 'note', 'txt']);
    assert.equal(head, 4);
    assert(versions.get('3').has('note.txt'));
    assert(!versions.get('4').has('note.txt'));
    assert.equal(versions.get('4').get('keep.txt'), 'keep');
    await page.waitForFunction(() => document.querySelector('#apps-tree input')?.value === '4');

    // A stale menu can target a file removed elsewhere or just deleted.
    await menu('now');
    await item('Delete').click();
    await page.locator('#urui-confirm-ok').click();
    await page.getByText('File not found', {exact: true}).waitFor();
    assert.equal(head, 4);

    await page.evaluate(() => window.hcTest.runtime.documents.open(
      'clay', ['base', 'now', 'picture', 'png']));
    assert.equal(await page.evaluate(() =>
      window.hcTest.runtime.documents.active('clay').readonly), true);
    await menu('now', 'picture.png');
    assert(await item('Delete').isEnabled());
    await item('Delete').click();
    await page.locator('#urui-confirm-ok').click();
    await page.waitForFunction(() => document.querySelector('#apps-tree input')?.value === '5');
    assert.equal(head, 5);
    assert(!versions.get('5').has('picture.png'));

    await menu('2');
    assert.equal(await item('Delete').count(), 0);
    assert(await item('Tombstone').isEnabled());
    await item('Tombstone').click();
    await page.locator('#hc-tomb-cancel').click();
    assert.equal(tombRequests.length, 0);
    for (const [name, message] of [
      ['same.txt', 'This version has the same content as the current file'],
      ['shared.txt', 'Content is still used by another desk'],
      ['missing.txt', 'No file at that revision']
    ]) {
      await menu('2', name);
      await item('Tombstone').click();
      await page.locator('#hc-tomb-ok').click();
      await page.getByText(message, {exact: true}).waitFor();
      assert.equal(head, 5);
    }
    await menu('2', 'gone.txt', 'file', true);
    assert(await item('Tombstone').isDisabled());
    assert(await item('Open').isDisabled());
    assert(await item('Download…').isDisabled());
    for (const revision of ['2', '3']) {
      await menu(revision);
      await item('Tombstone').click();
      await page.locator('#hc-tomb-ok').click();
      await page.getByText(`Tombstoned /note/txt at revision ${revision}.`, {exact: true}).waitFor();
      assert.equal(head, 5);
      assert(versions.get(revision).has('note.txt'));
      assert(tombs.has(versions.get(revision).get('note.txt')));
    }
    await menu('now', 'keep.txt');
    assert(await item('Delete').isEnabled());
    assert.equal(await item('Open').innerText(), 'Open');
    assert.equal(await item('Tombstone').count(), 0);
    assert.deepEqual(errors, []);
    console.log('PASS Delete/Tombstone menus, cancel, failure, binary delete, drafts, revisions, and content protection');
  } finally {
    await page.close();
  }
};
