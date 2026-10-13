const assert = require('node:assert/strict');
const path = require('node:path');
const urui = process.env.URUI_ROOT || path.resolve(__dirname, '../../urui');
const {assemble} = require(path.join(urui, 'tests/browser/serve-app.js'));
const {evaluate, parseCords} = require(path.join(urui, 'tests/browser/eval-assets.js'));

const program = assemble([
  ['heic', 'desk/mar/heic.hoon'], ['png', 'desk/mar/png.hoon'],
  ['sh', 'desk/mar/sh.hoon']
], `
=/  samples=(list @)  ~[0 0x1.0002.0300 'image-bytes']
?>  %+  levy  samples
    |=  bytes=@
    =/  codec  heic(dat bytes)
    =/  original  png(dat bytes)
    =/  actual=mime  mime:grow:codec
    =/  expected=mime  mime:grow:original
    ?&  =(bytes (mime:grab:codec [/image/heic (as-octs:mimes:html bytes)]))
        =(bytes (noun:grab:codec bytes))
        =([/image/heic (as-octs:mimes:html bytes)] mime:grow:codec)
        =(q.expected q.actual)
        =(%mime grad:codec)
    ==
=/  samples=(list wain)  ~[~ ~['#!/bin/sh' 'echo hello'] ~['a' '' 'b']]
?>  %+  levy  samples
    |=  lines=wain
    =/  codec  sh(dat lines)
    =/  actual=mime  mime:grow:codec
    ?&  =(lines (mime:grab:codec mime:grow:codec))
        =(lines (noun:grab:codec lines))
        =(lines (txt:grab:codec txt:grow:codec))
        =(%txt grad:codec)
        =(/text/plain p.actual)
    ==
'HEIC and SH marks passed'
`, path.resolve(__dirname, '..'));
evaluate(program).then(output => {
  let result;
  try { result = parseCords(output, 1)[0]; }
  catch (error) { throw new Error(`${error.message}\n${output}`); }
  assert.equal(result, 'HEIC and SH marks passed');
  console.log('PASS HEIC atom/PNG parity and SH text/MIME round trips and diff delegation');
}).catch(error => { console.error(error); process.exitCode = 1; });
