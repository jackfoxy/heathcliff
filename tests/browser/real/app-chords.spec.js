'use strict';

// Heathcliff's application chord table, in the shared shape.
//
// This is the landing pad the cross-app conflict gate extends: it reads
// the chords the page declares rather than a hand-written list, so a new
// row cannot be added without a test seeing it.
//
// What is heathcliff-specific lives here; the generic rules -- policy
// against both keymaps, gating, duplicate bindings -- are the conflict
// gate's, and the dispatcher's behaviour under both keymaps is
// chord-policies.spec.js's.
//
// F1 and F2 open urui's dialogs here now, matching obelisk and
// graph-viz. Heathcliff had left both to Ace, and that was the one real
// cross-app break; these assertions are what keeps it closed.
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
  expect(chords.map((chord) => [chord.binding, chord.command])).toEqual([
    ['F1', 'help'],
    ['F2', 'settings'],
    ['F5', 'refresh-tree'],
    ['Ctrl-S', 'save:clay'],
    ['Ctrl-Shift-S', 'save-as:clay'],
    ['Alt-C', 'copy:clay']
  ]);
  //  F1 and F2 displace Ace; the rest are claimed by neither keymap
  expect(chords.filter((chord) => chord.policy === 'override')
    .map((chord) => chord.binding)).toEqual(['F1', 'F2']);
  expect(chords.every((chord) => chord.label)).toBe(true);
});

test('the chord puts its binding on the Save control', async ({page}) => {
  await open(page);
  //  urui badges a declared chord's control from the table, so a
  //  rebind cannot leave a stale label behind
  const save = page.locator('#clay-save');
  await expect(save).toHaveAttribute('aria-keyshortcuts', 'Ctrl-S');
  await expect(save).toHaveAttribute('title', /Ctrl-S/);
});

test('every file chord names the clay store', async ({page}) => {
  await open(page);
  const resolved = await page.evaluate(() => {
    const stores = window.urui.config.files.stores.map((store) => store.name);
    return window.urui.config.shortcuts
      .filter((chord) => chord.command.includes(':'))
      .map((chord) => {
        const [verb, store] = chord.command.split(':');
        return {verb, store, known: stores.includes(store)};
      });
  });
  expect(resolved).toEqual([
    {verb: 'save', store: 'clay', known: true},
    {verb: 'save-as', store: 'clay', known: true},
    {verb: 'copy', store: 'clay', known: true}
  ]);
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
  //  Ctrl-Shift-P is bound in no app's table, so nothing may claim it
  const prevented = await page.evaluate(() => {
    return !document.dispatchEvent(new KeyboardEvent('keydown', {
      key: 'p', ctrlKey: true, shiftKey: true,
      bubbles: true, cancelable: true
    }));
  });
  expect(prevented).toBe(false);
});

test('F1 and F2 open urui\'s dialogs, as in the other apps', async ({page}) => {
  await open(page);
  await page.keyboard.press('F1');
  await expect(page.locator('#help-panel')).toBeVisible();
  await page.keyboard.press('Escape');
  await expect(page.locator('#help-panel')).toBeHidden();
  await page.keyboard.press('F2');
  await expect(page.locator('#settings-modal')).toBeVisible();
  await page.keyboard.press('Escape');
  await expect(page.locator('#settings-modal')).toBeHidden();
});

test('F5 refreshes the tree rather than running anything', async ({page}) => {
  //  F5 runs a query in obelisk; heathcliff has nothing to run, and the
  //  two meanings are deliberate
  const backend = await open(page, {tree: [['data', 'notes', 'txt']]});
  //  `roots`, not `tree`: a desk's listing is fetched when it is
  //  expanded, but reloading the desks is what refreshing means here,
  //  and it is what heathcliff registers over urui's default.
  await expect.poll(() => backend.sent('roots').length).toBeGreaterThan(0);
  const before = backend.sent('roots').length;
  await page.keyboard.press('F5');
  await expect.poll(() => backend.sent('roots').length)
    .toBeGreaterThan(before);
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
