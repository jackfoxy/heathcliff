const assert = require('node:assert/strict');

module.exports = async function checkShell(browser, origin) {
  const page = await browser.newPage({viewport: {width: 1440, height: 900}});
  try {
    await page.goto(origin + '/heathcliff');
    await page.waitForFunction(() => window.hcTest?.runtime.documents.editor('clay'));
    assert.equal(await page.locator('#explorer-pane-ship').innerText(), '~zod');
    const aligned = async () => {
      await page.waitForFunction(() => Math.abs(
        document.querySelector('#explorer-pane-ship').getBoundingClientRect().bottom -
        document.querySelector('#editor-pane-head').getBoundingClientRect().bottom
      ) < 1);
    };
    await aligned();
    assert.equal(await page.locator('#clay-save .save-icon').count(), 1);
    assert.equal(await page.locator('#clay-save').getAttribute('aria-label'), 'Save this File');
    const heights = await page.locator('.toolbar > button').evaluateAll(buttons =>
      buttons.map(button => button.getBoundingClientRect().height));
    assert.deepEqual(heights, [36, 36, 36]);
    await page.locator('#settings').click();
    assert(await page.locator('#settings-modal .settings-card > .settings-field')
      .evaluateAll(fields => fields.length === 4 && fields.every(field =>
        getComputedStyle(field).marginTop === '16px')));
    await page.keyboard.press('Escape');
    await page.setViewportSize({width: 900, height: 700});
    await aligned();
    await page.setViewportSize({width: 1440, height: 900});

    // Native drag over the ship label, tab strip, blank body and an iframe.
    for (const target of ['#explorer-pane-ship', '#apps-tab', '#apps-panel',
      '.ref-explorer-panel:not([hidden]) iframe']) {
      const id = await page.evaluate(withFrame => {
        const {documents: docs, explorer} = window.hcTest.runtime;
        if (withFrame) {
          const html = docs.create('clay', {path: ['base', 'now', 'preview', 'html'],
            text: '<h1>Reference preview</h1>'});
          docs.addRef('clay', html.id);
        } else explorer.setView('apps');
        return docs.create('clay', {text: 'Drop target: ' + withFrame}).id;
      }, target.includes('iframe'));
      const count = await page.evaluate(() => window.hcTest.runtime.explorer.refs.list().length);
      await page.locator(`[data-document-tab="${id}"]`).dragTo(page.locator(target));
      await page.waitForFunction(expected =>
        window.hcTest.runtime.explorer.refs.list().length === expected, count + 1);
      assert.equal(await page.locator('.is-ref-drop-target').count(), 0);
    }
    // End a drag without a drop: frames must become interactive again.
    const source = page.locator('[data-document-tab]').last();
    const box = await source.boundingBox();
    await page.mouse.move(box.x + 5, box.y + 5);
    await page.mouse.down();
    await page.mouse.move(box.x + 30, box.y + 35, {steps: 5});
    await page.keyboard.press('Escape');
    await page.mouse.up();
    assert.equal(await page.locator('.is-ref-drop-target').count(), 0);
    console.log('PASS ship/header alignment, controls, and whole-pane native reference drops');
  } finally {
    await page.close();
  }
};
