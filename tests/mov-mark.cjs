// Exercise the actual mark without a ship, including 6645 trailing NULs.
const assert = require('node:assert/strict');
const path = require('node:path');
const urui = process.env.URUI_ROOT || path.resolve(__dirname, '../../urui');
const {assemble} = require(path.join(urui, 'tests/browser/serve-app.js'));
const {evaluate, parseCords} = require(path.join(urui, 'tests/browser/eval-assets.js'));
const program = assemble([['mov', 'desk/mar/mov.hoon']], `
=/  samples=(list octs)  ~[[6.648 'abc'] [6.645 0] [0 0] [3 'abc']]
?>  %+  levy  samples
    |=  bytes=octs
    =/  codec  mov(dat bytes)
    ?&  =(bytes (mime:grab:codec [/video/quicktime bytes]))
        =(bytes (noun:grab:codec bytes))
        =([/video/quicktime bytes] mime:grow:codec)
    ==
'mov mark round trip passed'
`, path.resolve(__dirname, '..'));
evaluate(program).then(output => {
  assert.equal(parseCords(output, 1)[0], 'mov mark round trip passed');
  console.log('PASS MOV mark: trailing NULs, all-zero bytes, empty file, and MIME round trips');
}).catch(error => { console.error(error); process.exitCode = 1; });
