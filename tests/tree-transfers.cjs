const assert = require('node:assert/strict');

module.exports = async function checkTreeTransfers(browser, origin) {
  const page = await browser.newPage();
  const errors = [], queries = [], reads = [], checks = [], uploads = [];
  let paths = [], tombs = [], failRead = '', unsafeName = false;
  let holdRead = false, releaseRead;
  page.on('pageerror', error => errors.push(error.message));
  await page.addInitScript(() => {
    const missing = () => new DOMException('Missing file', 'NotFoundError');
    window.localDownload = {files: {}, directories: [], calls: [], aborts: 0};
    const directory = prefix => ({
      async getDirectoryHandle(name) {
        const path = prefix + name + '/';
        window.localDownload.directories.push(path);
        return directory(path);
      },
      async getFileHandle(name, options = {}) {
        const state = window.localDownload;
        const key = prefix + name;
        if (!(key in state.files)) {
          if (!options.create) throw missing();
          state.files[key] = [];
        }
        return {async createWritable() {
          let pending;
          return {
            async write(blob) {
              if (state.failWrite === key) throw new Error('Disk full');
              pending = Array.from(new Uint8Array(await blob.arrayBuffer()));
            },
            async close() { state.files[key] = pending; },
            async abort() { state.aborts += 1; }
          };
        }};
      }
    });
    window.testDirectoryPicker = async options => {
      const state = window.localDownload;
      state.calls.push(options);
      if (state.cancel) throw new DOMException('Cancelled', 'AbortError');
      if (state.denied) throw new DOMException('Permission denied', 'NotAllowedError');
      return directory('');
    };
    window.showDirectoryPicker = window.testDirectoryPicker;
  });
  await page.route('**/heathcliff/{api,files,raw/**,upload/**}', async route => {
    const request = route.request();
    const reply = body => route.fulfill({contentType: 'application/json',
      body: JSON.stringify(body)});
    if (request.url().includes('/raw/')) {
      const url = new URL(request.url());
      reads.push(url.pathname);
      const parts = url.pathname.split('/');
      const mark = parts.at(-1);
      const name = parts.at(-2);
      if (holdRead) {
        holdRead = false;
        await new Promise(resolve => { releaseRead = resolve; });
      }
      if (name === failRead) return route.fulfill({status: 500, body: 'Failure'});
      return route.fulfill({contentType: 'application/octet-stream',
        headers: {'content-disposition': 'attachment; filename="' +
          (unsafeName ? '../escape.txt' : name + '.' +
            ({noun: 'jam', mime: 'png'}[mark] || mark)) + '"'},
        body: Buffer.from([65, 0, 255, 0])});
    }
    if (request.url().includes('/upload/')) {
      uploads.push(request.url());
      return reply({ok: true, path: ['base', 'now', 'data', 'notes', 'a', 'txt']});
    }
    const data = request.postDataJSON();
    queries.push(data);
    if (data.op === 'roots') return reply({ok: true,
      roots: [{desk: 'base', title: 'Base', rev: 7}]});
    if (data.op === 'tree') return reply({ok: true, paths, tombs});
    if (data.op === 'upload-check') {
      checks.push(data);
      return reply({ok: true, clay: '/' + data.path.slice(2).join('/'),
        mark: 'txt', exists: false, install: [], problems: []});
    }
    return reply({ok: true, entries: []});
  });
  const context = async (path = ['base', 'now', 'data', 'notes'], entry = 'directory') => {
    await page.evaluate(({path, entry}) => {
      const {runtime} = window.hcTest;
      runtime.explorer.context.open('clay', path,
        document.getElementById('data-tab'), undefined,
        {path, entry, view: 'data'});
    }, {path, entry});
  };
  const download = async (path, entry) => {
    // A repeated error must come from this request, not the previous toast.
    await page.locator('#urui-toast-message').evaluate(node => {
      node.textContent = '';
    });
    await context(path, entry);
    await page.getByRole('menuitem', {name: 'Download…', exact: true}).click();
  };
  const toast = text => page.locator('#urui-toast-message').getByText(text).waitFor();
  const greenToast = async () => {
    assert.equal(await page.locator('#urui-toast').getAttribute('data-kind'), 'download');
    for (const [theme, color] of [['light', 'rgb(21, 128, 61)'],
      ['dark', 'rgb(74, 222, 128)']]) {
      await page.evaluate(theme => {
        document.documentElement.dataset.effectiveTheme = theme;
      }, theme);
      assert.equal(await page.locator('#urui-toast-message')
        .evaluate(node => getComputedStyle(node).color), color);
    }
  };
  const state = () => page.evaluate(() => window.localDownload);
  const reset = async (files = {}) => {
    await page.evaluate(files => {
      window.localDownload = {files, directories: [], calls: [], aborts: 0};
      window.showDirectoryPicker = window.testDirectoryPicker;
    }, files);
    reads.length = 0;
    queries.length = 0;
    failRead = '';
    unsafeName = false;
    paths = [];
    tombs = [];
  };
  try {
    await page.goto(origin + '/heathcliff');
    await page.waitForFunction(() => window.hcTest);
    assert.equal(await page.locator('#hc-download-button + #clay-new + #clay-save').count(), 1);
    assert.equal(await page.locator('nav.toolbar #hc-download-button').count(), 0);
    assert(await page.locator('#hc-download-button').isDisabled());

    await context();
    await page.getByRole('menuitem', {name: 'Upload…', exact: true}).click();
    const field = page.locator('#hc-upload-path');
    assert(await field.evaluate(input => input.readOnly));
    assert.equal(await field.inputValue(), '/base/data/notes/');
    assert(await page.locator('#hc-upload-body .hc-upload-tree').isHidden());
    assert(await page.locator('#hc-upload-choose-folder').isVisible());
    // Even a programmatic edit cannot redirect a fixed destination.
    await field.evaluate(input => { input.value = '/other/elsewhere/'; });
    await page.locator('#hc-upload-input').setInputFiles({name: 'My_File.TXT',
      mimeType: 'text/plain', buffer: Buffer.from('hello')});
    await page.waitForFunction(() => !document.getElementById('hc-upload-confirm').disabled);
    assert.deepEqual(checks.at(-1).path, ['base', 'now', 'data', 'notes']);
    assert.equal(checks.at(-1).filename, 'my-file.txt');
    await page.evaluate(() => {
      const transfer = new DataTransfer();
      for (const name of ['local/a.txt', 'local/Sub_Folder/b.txt']) {
        const file = new File(['hello'], name.split('/').at(-1));
        Object.defineProperty(file, 'webkitRelativePath', {value: name});
        transfer.items.add(file);
      }
      const input = document.getElementById('hc-upload-folder-input');
      input.files = transfer.files;
      input.dispatchEvent(new Event('change', {bubbles: true}));
    });
    await page.waitForFunction(() => !document.getElementById('hc-upload-confirm').disabled);
    assert.deepEqual(checks.slice(-2).map(check => check.path), [
      ['base', 'now', 'data', 'notes'], ['base', 'now', 'data', 'notes', 'sub-folder']
    ]);
    await page.locator('#hc-upload-confirm').click();
    await page.locator('#hc-upload').waitFor({state: 'hidden'});
    assert(uploads[0].endsWith('/base/now/data/notes'));
    assert(uploads[1].endsWith('/base/now/data/notes/sub-folder'));

    await reset();
    paths = [['data', 'notes', 'a', 'txt'], ['data', 'notes', 'sub', 'b', 'noun'],
      ['data', 'notes', 'image', 'mime'], ['data', 'notes', 'gone', 'txt']];
    tombs = [paths.at(-1)];
    holdRead = true;
    await download();
    await toast('Downloading 1/3 files…');
    await greenToast();
    releaseRead();
    await toast('Downloaded 3/3 files. Skipped 1 tombstoned files.');
    await greenToast();
    assert.deepEqual((await state()).files, {
      'a.txt': [65, 0, 255, 0], 'sub/b.jam': [65, 0, 255, 0], 'image.png': [65, 0, 255, 0]
    });
    assert.deepEqual((await state()).calls, [{mode: 'readwrite'}]);
    assert.deepEqual(queries.filter(query => query.op === 'tree').at(-1),
      {op: 'tree', desk: 'base', case: '7', scope: ['data', 'notes']});
    assert(reads.every(url => url.startsWith('/heathcliff/raw/base/7/')));

    await reset();
    paths = [['data', 'old', 'txt']];
    await download(['base', '2'], 'desk');
    await toast('Downloaded 1/1 files.');
    assert.deepEqual((await state()).files, {'data/old.txt': [65, 0, 255, 0]});
    assert.equal(queries.filter(query => query.op === 'roots').length, 0);
    assert.equal(reads[0], '/heathcliff/raw/base/2/data/old/txt');

    await reset();
    await page.evaluate(() => { window.localDownload.cancel = true; });
    await download();
    assert.equal(queries.length, 0);
    assert.deepEqual((await state()).files, {});
    await reset();
    await page.evaluate(() => { window.localDownload.denied = true; });
    await download();
    await toast(/Permission denied/);
    assert.equal(queries.length, 0);

    await reset({'a.txt': [9]});
    paths = [['data', 'notes', 'a', 'txt'], ['data', 'notes', 'b', 'txt']];
    await download();
    await page.locator('#urui-confirm-cancel').click();
    await toast(/Stopped after 0\/2 downloads/);
    await greenToast();
    assert.deepEqual((await state()).files, {'a.txt': [9]});
    await download();
    await page.locator('#urui-confirm-ok').click();
    await toast('Downloaded 2/2 files.');
    assert.deepEqual((await state()).files['a.txt'], [65, 0, 255, 0]);

    await reset();
    paths = [['data', 'notes', 'first', 'txt'], ['data', 'notes', 'fail', 'txt'],
      ['data', 'notes', 'last', 'txt']];
    failRead = 'fail';
    await download();
    await toast(/Stopped after 1\/3 downloads: Cannot download/);
    assert.equal(await page.locator('#urui-toast').getAttribute('data-kind'), 'error');
    assert.notEqual(await page.locator('#urui-toast-message')
      .evaluate(node => getComputedStyle(node).color), 'rgb(74, 222, 128)');
    assert.deepEqual(Object.keys((await state()).files), ['first.txt']);
    assert.equal(reads.length, 2);

    await reset({'a.txt': [9]});
    paths = [['data', 'notes', 'a', 'txt']];
    await page.evaluate(() => { window.localDownload.failWrite = 'a.txt'; });
    await download();
    await page.locator('#urui-confirm-ok').click();
    await toast(/Disk full/);
    assert.equal((await state()).aborts, 1);
    assert.deepEqual((await state()).files['a.txt'], [9]);

    for (const invalid of [
      ['data', 'elsewhere', 'a', 'txt'], ['data', 'notes', '..', 'a', 'txt']
    ]) {
      await reset();
      paths = [invalid];
      await download();
      await toast(/Invalid file path/);
      assert.equal(reads.length, 0);
      assert.deepEqual((await state()).files, {});
    }
    await reset();
    paths = [['data', 'notes', 'a', 'txt']];
    unsafeName = true;
    await download();
    await toast(/Invalid download filename/);
    assert.deepEqual((await state()).files, {});

    await reset();
    paths = [['data', 'notes', 'a', 'png'], ['data', 'notes', 'a', 'mime']];
    await download();
    await toast(/same local destination/);
    assert.deepEqual(Object.keys((await state()).files), ['a.png']);

    await reset();
    await download();
    await toast('Downloaded 0/0 files.');
    assert.deepEqual((await state()).files, {});
    const single = page.waitForEvent('download');
    await download(['base', '2', 'data', 'a', 'txt'], 'file');
    const singleFile = await single;
    assert.equal(singleFile.url(), origin + '/heathcliff/raw/base/2/data/a/txt?download');
    assert.equal(singleFile.suggestedFilename(), 'a.txt');
    assert.equal((await state()).calls.length, 1); // Only the empty-tree picker.
    assert.deepEqual(errors, []);
    console.log('PASS tree transfers: frozen upload paths, button order, recursive pinned downloads, bytes, filenames, tombs, consent, cancellation and failures');
  } finally { await page.close(); }
};
