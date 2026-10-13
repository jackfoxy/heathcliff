const assert = require('node:assert/strict');

module.exports = async function checkNewFile(browser, origin) {
  const page = await browser.newPage();
  const errors = [], saves = [], trees = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.route('**/heathcliff/{api,files}', async route => {
    const data = route.request().postDataJSON();
    const reply = (body, status = 200) => route.fulfill({status,
      contentType: 'application/json', body: JSON.stringify(body)});
    if (data.op === 'roots') return reply({ok: true, roots:
      ['base', 'other'].map(desk => ({desk, title: desk, rev: 3}))});
    if (data.op === 'tree') {
      trees.push(data);
      return reply({ok: true, paths: [['data', 'notes', 'old', 'txt']], tombs: []});
    }
    if (data.op === 'save') {
      saves.push(data);
      if (data.path.at(-2) === 'old' && !data.overwrite) {
        return reply({ok: false, error: {code: 'exists', message: 'Already exists'}}, 409);
      }
      return reply({ok: true, hash: 'saved-' + saves.length});
    }
    return reply({ok: true, entries: []});
  });
  try {
    await page.goto(origin + '/heathcliff');
    await page.waitForFunction(() => window.hcTest?.runtime.documents.editor('clay'));
    assert.equal(await page.locator('#clay-new + #clay-save').count(), 1);
    assert.equal(await page.locator('#clay-new').innerText(), 'New File');
    const before = await page.evaluate(() => {
      const docs = window.hcTest.runtime.documents;
      docs.editor('clay').setSource('keep this draft');
      return docs.active('clay').id;
    });
    await page.locator('#clay-new').click();
    assert.equal(await page.evaluate(() => window.hcTest.runtime.documents.active('clay').text), '');
    await page.locator('#clay-save').click();
    const tree = page.getByLabel('Save destinations');
    const field = page.locator('#urui-file-dialog-path');
    await tree.locator('summary', {hasText: '%base /'}).click();
    assert.equal(await field.inputValue(), '/base/now/');
    await tree.locator('summary', {hasText: /^data$/}).click();
    assert.equal(await field.inputValue(), '/base/now/data/');
    await tree.locator('summary', {hasText: /^notes$/}).click();
    assert.equal(await field.inputValue(), '/base/now/data/notes/');
    await page.locator('#urui-file-dialog-confirm').click();
    assert.equal(saves.length, 0);
    assert(await page.locator('#urui-file-dialog-error').isVisible());
    await field.fill('/base/now/data/notes/new/nested/empty.txt');
    await page.locator('#urui-file-dialog-cancel').click();
    assert.equal(saves.length, 0);
    assert.equal(await page.evaluate(() => window.hcTest.runtime.documents.active('clay').path), null);
    await page.locator('#clay-save').click();
    await tree.locator('summary', {hasText: '%other /'}).click();
    assert.equal(await field.inputValue(), '/other/now/');
    await field.fill('/other/now/new/nested/empty.txt');
    await page.locator('#urui-file-dialog-confirm').click();
    await page.waitForFunction(() => window.hcTest.runtime.documents.active('clay').path);
    assert.deepEqual(saves[0].path, ['other', 'now', 'new', 'nested', 'empty', 'txt']);
    assert.equal(saves[0].text, '');
    assert.equal(await page.evaluate(id => window.hcTest.runtime.documents.get('clay', id).text, before), 'keep this draft');
    await page.locator('#clay-new').click();
    await page.evaluate(() => window.hcTest.runtime.documents.editor('clay').setSource('replacement'));
    await page.locator('#clay-save').click();
    await tree.locator('summary', {hasText: '%base /'}).click();
    await tree.locator('summary', {hasText: /^data$/}).click();
    await tree.locator('summary', {hasText: /^notes$/}).click();
    await tree.getByRole('button', {name: 'old.txt', exact: true}).click();
    assert.equal(await field.inputValue(), '/base/now/data/notes/old.txt');
    await page.locator('#urui-file-dialog-confirm').click();
    await page.locator('#urui-confirm-ok').click();
    await page.waitForFunction(() => window.hcTest.runtime.documents.active('clay').path);
    assert.equal(saves.at(-1).overwrite, true);
    assert.equal(saves.at(-1).text, 'replacement');
    assert(trees.every(query => query.case === 'now'));
    assert.deepEqual(errors, []);
    console.log('PASS New File, empty drafts, destination tree, partial/new paths, cancellation and replacement');
  } finally {
    await page.close();
  }
};
