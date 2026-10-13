const assert = require('node:assert/strict');
const path = require('node:path');
const urui = process.env.URUI_ROOT || path.resolve(__dirname, '../../urui');
const {assemble} = require(path.join(urui, 'tests/browser/serve-app.js'));
const {evaluate, parseCords} = require(path.join(urui, 'tests/browser/eval-assets.js'));
const program = assemble([
  ['m4a', 'desk/mar/m4a.hoon'], ['mp4', 'desk/mar/mp4.hoon']
], `
=/  samples=(list @)  ~[0 0x1.0002.0300 'audio-bytes']
?>  %+  levy  samples
    |=  bytes=@
    =/  codec  m4a(dat bytes)
    =/  original  mp4(dat bytes)
    =/  actual=mime  mime:grow:codec
    =/  expected=mime  mime:grow:original
    ?&  =(bytes (mime:grab:codec actual))
        =(bytes (noun:grab:codec bytes))
        =(/audio/mp4 p.actual)
        =(q.expected q.actual)
        =(%mime grad:codec)
    ==
'm4a mark passed'
`, path.resolve(__dirname, '..'));
evaluate(program).then(output => {
  let result;
  try { result = parseCords(output, 1)[0]; }
  catch (error) { throw new Error(`${error.message}\n${output}`); }
  assert.equal(result, 'm4a mark passed');
  console.log('PASS M4A mark: MP4 byte parity, MIME round trips, internal zeros and empty data');
}).catch(error => { console.error(error); process.exitCode = 1; });
