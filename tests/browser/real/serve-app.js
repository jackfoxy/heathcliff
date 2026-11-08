// serve-app.js — compile and serve the Heathcliff page offline.
//
// The desk's own routes are reproduced here, so a spec drives the real
// Sail page and the real urui runtime with no ship: `vere eval` builds
// the four assets the agent serves, this process answers the routes
// they reference, and `fixtures/backend.js` answers the file wire from
// inside the page.
//
// Modelled on graph-viz's harness.  The one structural difference is
// that Heathcliff links its stylesheet (`styles=~['/heathcliff/app.css']`)
// rather than inlining it, so `css` is a served route, not part of the
// page.

const fs = require('node:fs');
const http = require('node:http');
const os = require('node:os');
const path = require('node:path');
const vm = require('node:vm');
const {spawn} = require('node:child_process');

const root = path.resolve(__dirname, '../../..');
const port = 4175;

function readSource(filename) {
  return fs.readFileSync(filename, 'utf8').replace(/^\/[+-].*\n/gm, '');
}

function assemble(bindings, expression) {
  const lines = [];
  for (const [face, relative] of bindings) {
    lines.push(`=+  ^=  ${face}`);
    lines.push(readSource(path.resolve(root, relative)));
  }
  lines.push(expression);
  return lines.join('\n');
}

function findVere() {
  const candidates = [
    process.env.VERE,
    path.join(os.homedir(), 'piers/urbit'),
    path.join(os.homedir(), 'piers/vere-v4.5-linux-x86_64'),
    'vere'
  ].filter(Boolean);
  for (const candidate of candidates) {
    if (!candidate.includes('/') || fs.existsSync(candidate)) return candidate;
  }
  throw new Error('set VERE to an executable that supports `eval`');
}

function decodeCord(source) {
  const chunks = [];
  for (let index = 0; index < source.length;) {
    if (source[index] !== '\\') {
      const point = source.codePointAt(index);
      const character = String.fromCodePoint(point);
      chunks.push(Buffer.from(character));
      index += character.length;
      continue;
    }
    const hex = source.slice(index + 1, index + 3);
    if (/^[0-9a-f]{2}$/i.test(hex)) {
      chunks.push(Buffer.from([Number.parseInt(hex, 16)]));
      index += 3;
      continue;
    }
    if (index + 1 >= source.length) throw new Error('invalid cord escape');
    chunks.push(Buffer.from(source[index + 1]));
    index += 2;
  }
  return Buffer.concat(chunks).toString('utf8');
}

function parseCords(output, wanted) {
  const plain = output.replace(/\x1b\[[0-9;]*m/g, '');
  const start = plain.indexOf('eval (run):');
  if (start < 0) throw new Error('vere eval returned no result');
  const cords = [];
  let index = start;
  while (index < plain.length && cords.length < wanted) {
    if (plain[index] !== "'") {
      index += 1;
      continue;
    }
    index += 1;
    let encoded = '';
    while (index < plain.length) {
      if (plain[index] === "'") {
        index += 1;
        break;
      }
      if (plain[index] === '\\') {
        encoded += plain[index];
        index += 1;
        if (index >= plain.length) throw new Error('unterminated cord');
        encoded += plain[index];
        if (/[0-9a-f]/i.test(plain[index])
          && /[0-9a-f]/i.test(plain[index + 1] || '')) {
          index += 1;
          encoded += plain[index];
        }
        index += 1;
        continue;
      }
      encoded += plain[index];
      index += 1;
    }
    cords.push(decodeCord(encoded));
  }
  if (cords.length !== wanted) {
    throw new Error(`vere eval returned ${cords.length} of ${wanted} assets`);
  }
  return cords;
}

function evaluate(source) {
  return new Promise((resolve, reject) => {
    const child = spawn(findVere(), ['eval']);
    const output = [];
    child.stdout.on('data', (chunk) => output.push(chunk));
    child.stderr.on('data', (chunk) => output.push(chunk));
    child.on('error', reject);
    child.on('close', (status) => {
      const result = Buffer.concat(output).toString('utf8');
      if (status === 0) resolve(result);
      else reject(new Error(result || 'vere eval failed'));
    });
    child.stdin.end(source);
  });
}

//  Binding order matches bin/assets-heathcliff.txt in the urui checkout.
async function compileAssetsOnce() {
  const source = assemble([
    ['urui', 'desk/sur/urui.hoon'],
    ['dock', 'desk/sur/docket.hoon'],
    ['uhttp', 'desk/lib/urui-http.hoon'],
    ['ufiles', 'desk/lib/urui-files.hoon'],
    ['hc', 'desk/lib/heathcliff-clay.hoon'],
    ['ujs', 'desk/lib/urui-js.hoon'],
    ['shell', 'desk/lib/urui-shell.hoon'],
    ['ucss', 'desk/lib/urui-css.hoon'],
    ['uace', 'desk/lib/urui-ace.hoon'],
    ['ucfg', 'desk/lib/urui-config.hoon'],
    ['web', 'desk/lib/heathcliff-web.hoon']
  ], '[(page:web ~zod) css:web (javascript:web ~zod) ace-config-js:web]');
  return parseCords(await evaluate(source), 4);
}

async function compileAssets() {
  let problem;
  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      const assets = await compileAssetsOnce();
      if (!assets[0].includes('</html>')) {
        throw new Error('vere eval returned truncated page HTML');
      }
      new vm.Script(assets[2], {filename: 'heathcliff-app.js'});
      new vm.Script(assets[3], {filename: 'heathcliff-config.js'});
      return assets;
    } catch (cause) {
      problem = cause;
    }
  }
  throw problem;
}

async function main() {
  const [page, css, javascript, aceConfig] = await compileAssets();
  const aceRoot = path.join(root, 'desk/web/ace');
  const aceAssets = new Map([
    ['/heathcliff/ace/ace.js', 'ace.js'],
    ['/heathcliff/ace/theme-github.js', 'theme-github.js'],
    ['/heathcliff/ace/theme-monokai.js', 'theme-monokai.js'],
    ['/heathcliff/ace/ext-beautify.js', 'ext-beautify.js'],
    ['/heathcliff/ace/keybinding-vim.js', 'keybinding-vim.js'],
    ['/heathcliff/ace/ext-prompt.js', 'ext-prompt.js'],
    ['/heathcliff/ace/ext-searchbox.js', 'ext-searchbox.js'],
    ['/heathcliff/ace/ext-settings_menu.js', 'ext-settings-menu.js'],
    ['/heathcliff/ace/license.txt', 'license.txt']
  ]);
  const served = new Map([
    ['/heathcliff/app.js', ['text/javascript; charset=utf-8', javascript]],
    ['/heathcliff/app.css', ['text/css; charset=utf-8', css]],
    [
      '/heathcliff/ace/heathcliff-config.js',
      ['text/javascript; charset=utf-8', aceConfig]
    ]
  ]);
  const server = http.createServer((request, response) => {
    const requestPath = new URL(request.url, 'http://127.0.0.1').pathname;
    if (request.method !== 'GET') {
      response.writeHead(405, {'content-type': 'text/plain; charset=utf-8'});
      response.end('the file wire is answered in the page');
      return;
    }
    if (requestPath === '/heathcliff' || requestPath === '/heathcliff/') {
      response.writeHead(200, {'content-type': 'text/html; charset=utf-8'});
      response.end(page);
      return;
    }
    if (served.has(requestPath)) {
      const [contentType, body] = served.get(requestPath);
      response.writeHead(200, {'content-type': contentType});
      response.end(body);
      return;
    }
    if (requestPath === '/heathcliff/doc.toc') {
      response.writeHead(200, {'content-type': 'text/plain; charset=utf-8'});
      response.end(fs.readFileSync(path.join(root, 'desk/doc.toc')));
      return;
    }
    if (aceAssets.has(requestPath)) {
      const filename = aceAssets.get(requestPath);
      const contentType = filename.endsWith('.js')
        ? 'text/javascript; charset=utf-8'
        : 'text/plain; charset=utf-8';
      response.writeHead(200, {'content-type': contentType});
      response.end(fs.readFileSync(path.join(aceRoot, filename)));
      return;
    }
    response.writeHead(404, {'content-type': 'text/plain; charset=utf-8'});
    response.end('not found');
  });
  server.listen(port, '127.0.0.1');
}

module.exports = {compileAssets, port};

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
