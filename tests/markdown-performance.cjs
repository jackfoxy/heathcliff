const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

module.exports = async function checkMarkdownPerformance(browser, origin) {
  const page = await browser.newPage();
  const guide = fs.readFileSync(path.join(__dirname,
    '../desk/doc/users-guide.md'), 'utf8');
  const calls = [];
  let failOnce = true;
  const escape = text => text.replaceAll('&', '&amp;').replaceAll('<', '&lt;');
  await page.route('**/heathcliff/{api,files}', async route => {
    const data = route.request().postDataJSON();
    const reply = (body, status = 200) => route.fulfill({status,
      contentType: 'application/json', body: JSON.stringify(body)});
    if (data.op === 'roots') return reply({ok: true, roots: []});
    if (data.op === 'load') return reply({ok: true, text: guide, hash: 'guide'});
    if (data.op === 'markdown') {
      calls.push(data.text);
      await new Promise(resolve => setTimeout(resolve,
        data.text === 'slow old text' ? 400 : 80));
      if (data.text === 'retry' && failOnce) {
        failOnce = false;
        return reply({ok: false, error: {message: 'Temporary render failure'}}, 503);
      }
      return reply({ok: true, html: '<p>' + escape(data.text) + '</p>'});
    }
    return reply({ok: true, entries: []});
  });
  const show = async text => page.evaluate(text => {
    const docs = window.hcTest.runtime.documents;
    return docs.create('clay', {
      path: ['base', 'now', 'sample', 'md'], text
    }).id;
  }, text);
  const rendered = async text => page.waitForFunction(text =>
    document.querySelector('#result-view .markdown-view')?.textContent === text,
  text);
  try {
    await page.goto(origin + '/heathcliff');
    await page.waitForFunction(() => window.hcTest?.runtime.documents.editor('clay'));
    await page.evaluate(() => window.hcTest.runtime.documents.open('clay',
      ['heathcliff', 'now', 'doc', 'users-guide', 'md']));
    await rendered(guide);
    assert.equal(calls.filter(text => text === guide).length, 1,
      'load and activation must share the in-flight guide render');
    const guideTab = await page.evaluate(() =>
      window.hcTest.runtime.documents.active('clay').id);
    await page.evaluate(() => window.hcTest.runtime.documents.create('clay'));
    await page.evaluate(id => window.hcTest.runtime.documents.select('clay', id), guideTab);
    await rendered(guide);
    assert.equal(calls.filter(text => text === guide).length, 1,
      'returning to unchanged Markdown must use its cached result');

    const slowRequest = page.waitForRequest(req =>
      req.postDataJSON()?.text === 'slow old text');
    await show('slow old text');
    await slowRequest;
    await show('new text');
    await rendered('new text');
    await page.waitForTimeout(450);
    await rendered('new text');
    await show('slow old text');
    await rendered('slow old text');
    assert.equal(calls.filter(text => text === 'slow old text').length, 1);

    await show('retry');
    await page.getByText('Unable to show this file: Temporary render failure').waitFor();
    await show('retry');
    await rendered('retry');
    assert.equal(calls.filter(text => text === 'retry').length, 2);

    const beforeLimit = calls.length;
    await show('é'.repeat(32769));
    await page.getByText('Unable to show this file: Markdown preview limit is 64 KiB').waitFor();
    assert.equal(calls.length, beforeLimit, 'oversize source must not reach the ship');
    for (let i = 0; i < 9; i++) {
      await show('cache entry ' + i);
      await rendered('cache entry ' + i);
    }
    await show(guide);
    await rendered(guide);
    assert.equal(calls.filter(text => text === guide).length, 2,
      'the cache must evict old documents');
    console.log('PASS Markdown: one render per open, cached revisits, stale replies, retries, UTF-8 limit, bounded cache');
  } finally {
    await page.close();
  }
};
