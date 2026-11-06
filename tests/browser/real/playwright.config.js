//  Heathcliff vendors no node_modules: like tests/previews.cjs, it uses
//  the sibling urui checkout's Playwright install.  See tests/README.md.
const path = require('node:path');

const urui = process.env.URUI_ROOT
  || path.resolve(__dirname, '../../../../urui');
const {defineConfig, devices} =
  require(path.join(urui, 'node_modules/@playwright/test'));

const externalServer = Boolean(process.env.HEATHCLIFF_URL);
const baseURL = process.env.HEATHCLIFF_URL || 'http://127.0.0.1:4175';

module.exports = defineConfig({
  testDir: __dirname,
  testMatch: '*.spec.js',
  fullyParallel: false,
  forbidOnly: true,
  retries: 0,
  workers: 1,
  reporter: 'line',
  metadata: {
    acePlatform: 'win',
    keyboardLayout: 'en-US'
  },
  webServer: externalServer ? undefined : {
    command: 'node serve-app.js',
    cwd: __dirname,
    url: `${baseURL}/heathcliff/`,
    reuseExistingServer: false,
    //  `vere eval` compiles the whole desk's web layer on boot
    timeout: 300_000
  },
  use: {
    ...devices['Desktop Chrome'],
    baseURL,
    locale: 'en-US',
    timezoneId: 'UTC',
    colorScheme: 'light',
    trace: 'off',
    screenshot: 'off',
    video: 'off'
  },
  projects: [{
    name: 'chromium-linux-win-keys',
    use: {browserName: 'chromium'}
  }]
});
