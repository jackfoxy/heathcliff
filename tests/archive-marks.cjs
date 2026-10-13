const assert = require('node:assert/strict');
const path = require('node:path');
const urui = process.env.URUI_ROOT || path.resolve(__dirname, '../../urui');
const {assemble} = require(path.join(urui, 'tests/browser/serve-app.js'));
const {evaluate, parseCords} = require(path.join(urui, 'tests/browser/eval-assets.js'));

async function main() {
  for (const [mark, mime] of [['zip', '/application/zip'], ['rar', "~['application' 'vnd.rar']"]]) {
    const program = assemble([['urui', 'desk/sur/urui.hoon'],
      ['dock', 'desk/sur/docket.hoon'], ['uhttp', 'desk/lib/urui-http.hoon'],
      ['ufiles', 'desk/lib/urui-files.hoon'],
      ['hc', 'desk/lib/heathcliff-clay.hoon'], ['archive', `desk/mar/${mark}.hoon`],
      ['ht', 'desk/lib/heathcliff-transfer.hoon']], `
=/  samples=(list octs)  ~[[6.648 'abc'] [6.645 0] [0 0] [3 'abc']]
?>  %+  levy  samples
    |=  bytes=octs
    =/  codec  archive(dat bytes)
    ?&  =(bytes (mime:grab:codec [${mime} bytes]))
        =(bytes (noun:grab:codec bytes))
        =([${mime} bytes] mime:grow:codec)
        =([~ ${mime} bytes] (raw:ht %${mark} bytes))
        =([~ %${mark}] (extension:ht ${mime}))
        =('${mark === 'zip' ? 'file.zip' : 'file.rar'}' (filename:ht /file/mime [${mime} bytes]))
    ==
'archive round trip passed'
`, path.resolve(__dirname, '..'));
    const output = await evaluate(program);
    let result;
    try { result = parseCords(output, 1)[0]; }
    catch (error) { throw new Error(`${error.message}\n${output}`); }
    assert.equal(result, 'archive round trip passed');
    console.log(`PASS ${mark.toUpperCase()} mark: MIME, raw downloads, extension, trailing NULs, zero and empty bytes`);
  }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
