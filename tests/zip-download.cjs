const assert = require('node:assert/strict');
const fs = require('node:fs');
const {spawnSync} = require('node:child_process');

module.exports = async function checkZipDownload(browser, origin) {
  const page = await browser.newPage();
  const insecureOrigin = origin.replace('127.0.0.1', 'heathcliff.test');
  const errors = [], downloads = [], reads = [], trees = [];
  let paths = [], tombs = [], fail = '', unsafe = false, releaseRead;
  let hold = false;
  page.on('pageerror', error => errors.push(error.message));
  page.on('download', file => downloads.push(file));
  // A non-localhost HTTP origin: exercise the actual secure-context restriction.
  await page.route(insecureOrigin + '/**', async route => {
    const response = await route.fetch({url: route.request().url()
      .replace(insecureOrigin, origin)});
    await route.fulfill({response});
  });
  await page.route('**/heathcliff/{api,files,raw/**}', async route => {
    const request = route.request();
    const reply = body => route.fulfill({contentType: 'application/json',
      body: JSON.stringify(body)});
    if (request.url().includes('/raw/')) {
      const url = new URL(request.url());
      reads.push(url.pathname);
      const parts = url.pathname.split('/');
      const stem = parts.at(-2), mark = parts.at(-1);
      if (hold) {
        hold = false;
        await new Promise(resolve => { releaseRead = resolve; });
      }
      if (stem === fail) return route.fulfill({status: 500, body: 'Failure'});
      return route.fulfill({contentType: 'application/octet-stream',
        headers: {'content-disposition': 'attachment; filename="' +
          (unsafe ? '../escape.txt' : stem + '.' + ({noun: 'jam', mime: 'png'}[mark] || mark)) + '"'},
        body: stem === 'empty' ? Buffer.alloc(0) : Buffer.from([65, 0, 255, 0])});
    }
    const data = request.postDataJSON();
    if (data.op === 'roots') return reply({ok: true,
      roots: [{desk: 'base', title: 'Base', rev: 7}]});
    if (data.op === 'tree') {
      trees.push(data);
      return reply({ok: true, paths, tombs});
    }
    return reply({ok: true, entries: []});
  });
  const start = async (path = ['base', 'now', 'data', 'notes']) => {
    await page.evaluate(path => {
      window.hcTest.runtime.explorer.context.open('clay', path,
        document.getElementById('data-tab'), undefined,
        {path, entry: 'directory', view: 'data'});
    }, path);
    await page.getByRole('menuitem', {name: 'Download…', exact: true}).click();
  };
  const toast = text => page.locator('#urui-toast-message').getByText(text).waitFor();
  const green = async () => {
    for (const [theme, color] of [['light', 'rgb(21, 128, 61)'],
      ['dark', 'rgb(74, 222, 128)']]) {
      await page.evaluate(theme => {
        document.documentElement.dataset.effectiveTheme = theme;
      }, theme);
      assert.equal(await page.locator('#urui-toast-message')
        .evaluate(node => getComputedStyle(node).color), color);
    }
  };
  const unzip = args => {
    const result = spawnSync('unzip', args, {timeout: 10000});
    assert.equal(result.status, 0, String(result.stderr || result.error || result.stdout));
    return result.stdout;
  };
  try {
    await page.goto(insecureOrigin + '/heathcliff');
    await page.waitForFunction(() => window.hcTest);
    assert.deepEqual(await page.evaluate(() =>
      [window.isSecureContext, typeof window.showDirectoryPicker]), [false, 'undefined']);
    paths = [['data', 'notes', 'a', 'txt'], ['data', 'notes', 'sub', 'b', 'noun'],
      ['data', 'notes', 'image', 'mime'], ['data', 'notes', 'empty', 'txt'],
      ['data', 'notes', 'gone', 'txt']];
    tombs = [paths.at(-1)];
    hold = true;
    const ready = page.waitForEvent('download');
    await start();
    await toast('Preparing ZIP 1/4 files…');
    await green();
    releaseRead();
    const file = await ready;
    assert.equal(file.suggestedFilename(), 'notes-r7.zip');
    const archive = await file.path();
    unzip(['-t', archive]); // Independent ZIP parser also verifies every CRC.
    assert.deepEqual(unzip(['-Z1', archive]).toString().trim().split('\n'),
      ['a.txt', 'sub/b.jam', 'image.png', 'empty.txt']);
    for (const name of ['a.txt', 'sub/b.jam', 'image.png']) {
      assert.deepEqual(unzip(['-p', archive, name]), Buffer.from([65, 0, 255, 0]));
    }
    assert.equal(unzip(['-p', archive, 'empty.txt']).length, 0);
    await toast(/ZIP ready: 4\/4 files.*Skipped 1 tombstoned files/);
    await green();
    assert.equal(trees.at(-1).case, '7');
    assert(reads.every(url => url.startsWith('/heathcliff/raw/base/7/')));

    paths = [['data', 'old', 'txt']];
    tombs = [];
    const historical = page.waitForEvent('download');
    await start(['base', '2']);
    const older = await historical;
    assert.equal(older.suggestedFilename(), 'base-r2.zip');
    assert.equal(unzip(['-Z1', await older.path()]).toString().trim(), 'data/old.txt');
    assert.equal(trees.at(-1).case, '2');

    paths = [['data', 'notes', 'gone', 'txt']];
    tombs = [...paths];
    const empty = page.waitForEvent('download');
    await start();
    const emptyBytes = fs.readFileSync(await (await empty).path());
    assert.equal(emptyBytes.length, 22);
    assert.equal(emptyBytes.readUInt32LE(), 0x06054b50);
    await toast(/ZIP ready: 0\/0 files.*Skipped 1 tombstoned files/);

    const before = downloads.length;
    tombs = [];
    paths = [['data', 'notes', 'a', 'txt'], ['data', 'notes', 'fail', 'txt']];
    fail = 'fail';
    await start();
    await toast(/ZIP failed after collecting 1\/2 files:.*No ZIP was downloaded/);
    assert.equal(await page.locator('#urui-toast').getAttribute('data-kind'), 'error');
    fail = '';
    paths = [['data', 'notes', 'a', 'mime'], ['data', 'notes', 'a', 'png']];
    await start();
    await toast(/same local destination: a.png.*No ZIP was downloaded/);
    paths = [['data', 'notes', '..', 'a', 'txt']];
    await start();
    await toast(/Invalid file path.*No ZIP was downloaded/);
    paths = [['data', 'notes', 'a', 'txt']];
    unsafe = true;
    await start();
    await toast(/Invalid download filename.*No ZIP was downloaded/);
    assert.equal(downloads.length, before);

    assert.deepEqual(await page.evaluate(async () => {
      const {zipArchive} = window.hcTest;
      const size = zipArchive(100);
      const count = zipArchive(1024, 1);
      const errors = [];
      try { await size.add('a.txt', new Blob([new Uint8Array(100)])); }
      catch (error) { errors.push(error.message.includes('size limit')); }
      await count.add('a.txt', new Blob([]));
      try { await count.add('b.txt', new Blob([])); }
      catch (error) { errors.push(error.message.includes('entry limit')); }
      return errors;
    }), [true, true]);
    assert.deepEqual(errors, []);
    console.log('PASS ZIP fallback: real downloads, independent CRC/extraction, hierarchy, revisions, tombs, empty files, green progress, limits and failure atomicity');
  } finally { await page.close(); }
};
