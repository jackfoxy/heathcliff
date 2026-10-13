const assert = require('node:assert/strict');

module.exports = async function checkFolderUpload(browser, origin) {
  const page = await browser.newPage();
  const checks = [], uploads = [], errors = [];
  let releaseUpload;
  page.on('pageerror', error => errors.push(error.message));
  await page.route('**/heathcliff/{api,files,upload/**}', async route => {
    const reply = (body, status = 200) => route.fulfill({status,
      contentType: 'application/json', body: JSON.stringify(body)});
    if (route.request().url().includes('/upload/')) {
      const body = route.request().postDataBuffer().toString();
      uploads.push({url: route.request().url(), body});
      if (body.includes('filename="hold.txt"')) {
        await new Promise(resolve => { releaseUpload = resolve; });
      }
      if (body.includes('filename="fail.txt"')) {
        return reply({ok: false, error: {message: 'Fixture failure'}}, 500);
      }
      return reply({ok: true, path: ['base', 'now', 'data', 'uploaded', 'txt']});
    }
    const data = route.request().postDataJSON();
    if (data.op === 'roots') return reply({ok: true,
      roots: [{desk: 'base', title: 'Base', rev: 3}]});
    if (data.op === 'tree') return reply({ok: true, paths: [], tombs: []});
    if (data.op === 'upload-check') {
      checks.push(data);
      if (data.filename === 'slow.txt') await new Promise(resolve => setTimeout(resolve, 500));
      return reply({ok: true, clay: '/' + [...data.path.slice(2), data.filename].join('/'),
        mark: data.filename.split('.').at(-1), exists: data.filename === 'old.txt',
        install: data.filename.endsWith('.zip') ? [{mark: 'zip', from: 'heathcliff'}] : [],
        problems: data.filename.endsWith('.bad') ? ['Unsupported mark'] : []});
    }
    return reply({ok: true, entries: []});
  });
  const select = files => page.evaluate(files => {
    const input = document.getElementById('hc-upload-folder-input');
    const transfer = new DataTransfer();
    for (const [relative, bytes = [65]] of files) {
      const file = new File([new Uint8Array(bytes)], relative.split('/').at(-1));
      Object.defineProperty(file, 'webkitRelativePath', {value: relative});
      transfer.items.add(file);
    }
    input.files = transfer.files;
    input.dispatchEvent(new Event('change', {bubbles: true}));
  }, files);
  const ready = () => page.waitForFunction(() => !document.getElementById('hc-upload-confirm').disabled);
  const open = async () => {
    await page.locator('#hc-upload-button').click();
    await page.locator('#hc-upload-path').fill('/base/data/target/');
  };
  try {
    await page.goto(origin + '/heathcliff');
    await page.waitForFunction(() => window.hcTest);
    await open();
    assert.equal(await page.locator('#hc-upload-choose + #hc-upload-choose-folder').count(), 1);
    const fileBox = await page.locator('#hc-upload-choose').boundingBox();
    const folderBox = await page.locator('#hc-upload-choose-folder').boundingBox();
    assert(folderBox.y >= fileBox.y + fileBox.height);
    assert.equal(await page.locator('#hc-upload-folder-input').getAttribute('webkitdirectory'), '');
    await select([['local/old.txt'], ['local/Sub_Folder/De😀p/archive.zip', [80, 75, 0, 0]],
      ['local/archive.rar', [82, 97, 114, 0]]]);
    await ready();
    assert.deepEqual(checks.slice(-3).map(item => [item.path, item.filename, item.nul]), [
      [['base', 'now', 'data', 'target'], 'old.txt', 0],
      [['base', 'now', 'data', 'target', 'sub-folder', 'de-p'], 'archive.zip', 2],
      [['base', 'now', 'data', 'target'], 'archive.rar', 1]
    ]);
    await page.locator('#hc-upload-confirm').click();
    assert.equal(uploads.length, 0);
    await page.locator('#hc-upload-install').check();
    await page.locator('#hc-upload-confirm').click();
    assert.equal(uploads.length, 0);
    await page.locator('#hc-upload-overwrite').check();
    await page.locator('#hc-upload-confirm').click();
    await page.locator('#hc-upload').waitFor({state: 'hidden'});
    assert.equal(uploads.length, 3);
    assert(uploads[1].url.endsWith('/base/now/data/target/sub-folder/de-p'));
    assert(uploads[1].body.includes('filename="archive.zip"'));
    assert(uploads[0].body.includes('name="overwrite"'));
    assert(!uploads[1].body.includes('name="overwrite"'));
    assert(uploads[1].body.includes('name="marks"'));

    await open();
    await select([['local/a.txt'], ['local/blocked.bad']]);
    await page.locator('#hc-upload-body').getByText(/Unsupported mark/).waitFor();
    assert(await page.locator('#hc-upload-confirm').isDisabled());
    assert.equal(uploads.length, 3);
    await select([['local/A B.txt'], ['local/a-b.txt']]);
    await page.locator('#hc-upload-body').getByText(/same destination/).waitFor();
    assert(await page.locator('#hc-upload-confirm').isDisabled());
    await select([['local/../escape.txt']]);
    await page.locator('#hc-upload-body').getByText(/Invalid relative path/).waitFor();
    await select([['local/a.txt']]);
    await page.locator('#hc-upload-path').fill('/base/../escape/');
    await page.locator('#hc-upload-body').getByText(/partial folder path/).waitFor();
    assert(await page.locator('#hc-upload-confirm').isDisabled());
    await page.locator('#hc-upload-path').fill('/base/data/target/');
    await ready();
    await page.locator('#hc-upload-cancel').click();
    assert.equal(uploads.length, 3);

    await open();
    await select([['local/first.txt'], ['local/fail.txt'], ['local/not-sent.txt']]);
    await ready();
    await page.locator('#hc-upload-confirm').click();
    await page.locator('#hc-upload-body').getByText(/Stopped after 1\/3 confirmed uploads/).waitFor();
    assert.equal(uploads.length, 5);
    assert(await page.locator('#hc-upload-confirm').isDisabled());
    await page.locator('#hc-upload-cancel').click();

    await open();
    const slow = page.waitForResponse(response => response.url().endsWith('/api')
      && response.request().postDataJSON()?.filename === 'slow.txt');
    const started = page.waitForRequest(request => request.url().endsWith('/api')
      && request.postDataJSON()?.filename === 'slow.txt');
    await select([['local/slow.txt']]);
    await started;
    await page.locator('#hc-upload-path').fill('/base/../invalid/');
    await slow;
    assert(await page.locator('#hc-upload-confirm').isDisabled());
    await page.locator('#hc-upload-cancel').click();
    await open();
    await select([['local/hold.txt'], ['local/not-sent.txt']]);
    await ready();
    const holding = page.waitForRequest(request => request.url().includes('/upload/'));
    await page.locator('#hc-upload-confirm').click();
    await holding;
    const progress = page.locator('#hc-upload-body .hc-upload-progress');
    for (const [theme, color] of [['light', 'rgb(21, 128, 61)'],
      ['dark', 'rgb(74, 222, 128)']]) {
      await page.evaluate(theme => {
        document.documentElement.dataset.effectiveTheme = theme;
      }, theme);
      assert.match(await progress.innerText(), /Uploading 1\/2/);
      assert.equal(await progress.evaluate(node => getComputedStyle(node).color), color);
    }
    await page.locator('#hc-upload-cancel').click();
    releaseUpload();
    await page.locator('#urui-toast-message').getByText('Uploaded 1/2 files.', {exact: true}).waitFor();
    assert.equal(await page.locator('#urui-toast-message')
      .evaluate(node => getComputedStyle(node).color), 'rgb(74, 222, 128)');
    assert.equal(uploads.length, 6);
    assert.deepEqual(errors, []);
    console.log('PASS folder uploads: hierarchy, archive bytes, consent, validation, cancellation, stale checks and partial failure');
  } finally { await page.close(); }
};
