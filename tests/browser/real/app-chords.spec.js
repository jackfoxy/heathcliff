'use strict';

// Heathcliff's application chord table, in the shared shape.
//
// This is the landing pad the cross-app conflict gate extends: it reads
// the chords the page declares rather than a hand-written list, so a new
// row cannot be added without a test seeing it.
//
// It records today's divergence deliberately. Heathcliff declares one
// chord, Ctrl-S, and leaves F1 and F2 to Ace's command palette and fold
// widget, while obelisk and graph-viz override both. Plan Phase 3 adds
// F1/F2 here; until it does, the assertions below are the proof that the
// divergence is a state of the code and not an accident of the docs.
//
// Everything here goes through `window.urui`, the frozen public facade.
// tests/previews.cjs reaches further in, but only by rewriting the
// compiled app.js to publish its internals; a shared-shape spec must
// not depend on that.

//  the sibling urui checkout's install; see tests/README.md
const path = require('node:path');
const urui = process.env.URUI_ROOT
  || path.resolve(__dirname, '../../../../urui');
const {test, expect} =
  require(path.join(urui, 'node_modules/@playwright/test'));

const {installBackend} = require('./fixtures/backend.js');

async function open(page, options = {}) {
  const backend = await installBackend(page, options);
  await page.goto('/heathcliff');
  await page.waitForFunction(() => Boolean(window.urui?.config));
  return backend;
}

test('the page declares exactly the chords heathcliff binds', async ({page}) => {
  await open(page);
  const chords = await page.evaluate(() => window.urui.config.shortcuts);
  expect(chords).toEqual([
    {binding: 'Ctrl-S', command: 'save:clay', when: 'always'}
  ]);
});

test('every declared chord names a store urui registers', async ({page}) => {
  await open(page);
  //  urui auto-registers open:/save:/save-as: per store, so a chord
  //  naming a store that does not exist is a silent no-op on a ship
  const resolved = await page.evaluate(() => {
    const stores = window.urui.config.files.stores.map((store) => store.name);
    return window.urui.config.shortcuts.map((chord) => {
      const [verb, store] = chord.command.split(':');
      return {verb, store, known: stores.includes(store)};
    });
  });
  expect(resolved).toEqual([{verb: 'save', store: 'clay', known: true}]);
});

test('a declared chord is captured before Ace and the browser', async ({page}) => {
  await open(page);
  //  What the conflict gate needs to know is that the chord is claimed,
  //  not what it then does.  Saving end to end -- the historical-save
  //  warning, the current destination, concurrent writes -- is covered
  //  in tests/previews.cjs, which can drive heathcliff's own tree.
  //  dispatchEvent answers false when a listener called preventDefault.
  //  A bubble-phase listener cannot be used to observe this: the
  //  capture-phase dispatcher also calls stopPropagation, so a claimed
  //  chord never reaches one.
  const prevented = await page.evaluate(() => {
    return !document.dispatchEvent(new KeyboardEvent('keydown', {
      key: 's', ctrlKey: true, bubbles: true, cancelable: true
    }));
  });
  expect(prevented).toBe(true);
});

test('an undeclared chord is left alone', async ({page}) => {
  await open(page);
  //  Ctrl-Shift-S is Save As in obelisk and Save SVG in graph-viz;
  //  heathcliff declares neither, so nothing may claim it here
  const prevented = await page.evaluate(() => {
    return !document.dispatchEvent(new KeyboardEvent('keydown', {
      key: 's', ctrlKey: true, shiftKey: true,
      bubbles: true, cancelable: true
    }));
  });
  expect(prevented).toBe(false);
});

test('F1 and F2 are left to Ace, unlike obelisk and graph-viz', async ({page}) => {
  await open(page);
  const bindings = await page.evaluate(() => {
    return window.urui.config.shortcuts.map((chord) => chord.binding);
  });
  expect(bindings).not.toContain('F1');
  expect(bindings).not.toContain('F2');
  //  so pressing them must not open urui's dialogs
  await page.keyboard.press('F1');
  await page.keyboard.press('F2');
  await expect(page.locator('#help-panel')).toBeHidden();
  await expect(page.locator('#settings-modal')).toBeHidden();
});

test('Settings carries heathcliff\'s own preferences', async ({page}) => {
  await open(page);
  await page.locator('#settings').click();
  await expect(page.locator('#settings-modal')).toBeVisible();
  //  declared in ++settings, not appended by javascript at boot
  await expect(page.locator('#hc-apps-upload-data')).toHaveCount(1);
  await expect(page.locator('#hc-apps-upload-root')).toHaveCount(1);
  await expect(
    page.locator('#settings-modal .settings-card > .settings-field')
  ).toHaveCount(4);
  await page.keyboard.press('Escape');
  await expect(page.locator('#settings-modal')).toBeHidden();
});
