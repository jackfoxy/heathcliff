// Compile the real Gall boundary, with empty static assets (tested by previews).
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const urui = process.env.URUI_ROOT || path.resolve(__dirname, '../../urui');
const {evaluate} = require(path.join(urui, 'tests/browser/eval-assets.js'));
const root = path.resolve(__dirname, '../desk');
const lines = [], seen = new Map();
function source(file) {
  const text = fs.readFileSync(file, 'utf8');
  const stars = [];
  for (const match of text.matchAll(/^\/([-+])\s+(.+)$/gm)) {
    for (const token of match[2].split(',').map(item => item.trim())) {
      const [alias, name = alias] = token.replace(/^\*/, '').split('=');
      const dependency = path.join(root, match[1] === '-' ? 'sur' : 'lib', name + '.hoon');
      if (token.startsWith('*')) { stars.push(source(dependency)); continue; }
      if (!seen.has(dependency)) {
        const body = source(dependency);
        lines.push(`=+  ^=  ${alias}\n${body}`);
        seen.set(dependency, alias);
      } else if (seen.get(dependency) !== alias) {
        lines.push(`=+  ^=  ${alias}  ${seen.get(dependency)}`);
      }
    }
  }
  const assets = [...text.matchAll(/^\/\*\s+(\S+)\s+%(\S+).*$/gm)]
    .map(([, face, mark]) => `=+  ^=  ${face}  ${mark === 'txt' ? '*wain' : '*@t'}`);
  return [...stars.map(body => `=+\n${body}`), ...assets,
    text.replace(/^\/[+*-].*\n/gm, '')].join('\n');
}
const agent = source(path.join(root, 'app/heathcliff.hoon'));
lines.push(`=+  ^=  app\n${agent}`);
lines.push(`
=/  active  ~(. app *bowl:gall)
=/  req=inbound-request:eyre
  %*  .  *inbound-request:eyre
    authenticated  &
    request
      :*  %'POST'  '/heathcliff/delete-tree'
          ~[['content-type' 'application/json']]
          [~ (as-octs:mimes:html '{}')]
      ==
  ==
=/  unauthorized
  (on-poke:active %handle-http-request !>([~.req req(authenticated |)]))
=/  invalid
  (on-poke:active %handle-http-request !>([~.req req]))
=/  status
  |=  cards=(list card:agent:gall)
  =/  codes
    %+  murn  cards
    |=  c=card:agent:gall
    ^-  (unit @ud)
    ?.  ?=([%give %fact * %http-response-header *] c)  ~
    [~ status-code:!<(response-header:http q.cage.p.c)]
  (snag 0 codes)
?>  =(401 (status -.unauthorized))
?>  =(400 (status -.invalid))
=/  loaded  +:(on-load:active on-save:active)
?>  =(on-save:active on-save:loaded)
'batch-delete-agent-ok'
`);
evaluate(lines.join('\n')).then(output => {
  assert.match(output, /batch-delete-agent-ok/);
  console.log('PASS Gall compilation, batch route authentication/validation, saved-state compatibility');
}).catch(error => { console.error(String(error.message).slice(-5000)); process.exitCode = 1; });
