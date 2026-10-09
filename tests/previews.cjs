// Run with a sibling urui checkout, or set URUI_ROOT. See tests/README.md.
const fs=require('fs'),http=require('http'),assert=require('assert/strict');
const path = require('path'), os = require('os');
const urui = process.env.URUI_ROOT || path.resolve(__dirname, '../../urui');
const {chromium} = require(path.join(urui, 'node_modules/@playwright/test'));
const {assemble} = require(path.join(urui, 'tests/browser/serve-app.js'));
const {findVere, parseCords} = require(path.join(urui, 'tests/browser/eval-assets.js'));
const cache = fs.mkdtempSync(path.join(os.tmpdir(), 'heathcliff-preview-'));
const root = path.resolve(__dirname, '..');
const wav=Buffer.alloc(44+16000); wav.write('RIFF');wav.writeUInt32LE(wav.length-8,4);wav.write('WAVEfmt ',8);wav.writeUInt32LE(16,16);wav.writeUInt16LE(1,20);wav.writeUInt16LE(1,22);wav.writeUInt32LE(8000,24);wav.writeUInt32LE(16000,28);wav.writeUInt16LE(2,32);wav.writeUInt16LE(16,34);wav.write('data',36);wav.writeUInt32LE(16000,40);
let js;
const changes=[];
const loads=[];
const saves=[];
let fileHead={text:'current contents',hash:'head-1'};
const uploadChecks=[];
const uploadPosts=[];
const uploadBodies=[];
let pickerRoots=false;
let docsEnabled=false;
const treeQueries=[];
const rule={gist:'open',origin:'default',mode:'black',ships:[],crews:[]};
const server=http.createServer(async(req,res)=>{
 const route=req.url.split('?')[0];
 const send=(type,data,status=200)=>{res.writeHead(status,{'Content-Type':type});res.end(data)};
 if(route==='/docs')return send('text/html','<title>Docs</title>',docsEnabled?200:404);
 if(route==='/heathcliff/doc.toc')return send('text/plain',fs.readFileSync(root+'/desk/doc.toc'));
 if(route.startsWith('/docs/d/heathcliff/')){
  const slug=route.slice('/docs/d/heathcliff/'.length);
  if(!/^[a-z-]+$/.test(slug))return send('text/plain','not found',404);
  const file=path.join(root,'desk/doc',slug+'.md');
  if(!fs.existsSync(file))return send('text/plain','not found',404);
  const text=fs.readFileSync(file,'utf8').replaceAll('&','&amp;').replaceAll('<','&lt;');
  return send('text/html',`<title>${slug}</title><pre>${text}</pre>`);
 }
 const files={
  '/heathcliff':['text/html',cache+'/heathcliff-page.html'],
  '/heathcliff/app.css':['text/css',cache+'/heathcliff-app.css'],
  '/heathcliff/ace/heathcliff-config.js':['text/javascript',cache+'/heathcliff-ace.js'],
  '/heathcliff/media-worker.js':['text/javascript',root+'/desk/web/media-worker.js'],
  '/heathcliff/mediainfo.js':['text/javascript',root+'/desk/web/mediainfo/index.js'],
  '/heathcliff/mediainfo.wasm':['application/wasm',root+'/desk/web/mediainfo/module.atom']};
 if(route==='/heathcliff/app.js')return send('text/javascript',js);
 if(files[route])return send(files[route][0],fs.readFileSync(files[route][1]));
 if(route.startsWith('/heathcliff/ace/')){const file=root+'/desk/web/ace/'+route.split('/').pop();if(fs.existsSync(file))return send('text/javascript',fs.readFileSync(file));}
 if(route.startsWith('/heathcliff/raw/')) {
  const mark=route.split('/').pop();
  if(mark==='wav'||mark==='mime')return send('audio/wav',wav);
  if(mark==='png')return send('image/png',fs.readFileSync(root+'/desk/favicon.png'));
  if(mark==='webm')return send('video/webm',fs.readFileSync(path.join(__dirname, 'fixtures/sample.webm')));
  if(mark==='mov')return send('video/quicktime',fs.readFileSync(path.join(__dirname, 'fixtures/sample.mov')));
  if(mark==='svg')return send('image/svg+xml','<svg xmlns="http://www.w3.org/2000/svg" width="40" height="30"/>');
  if(mark==='bad')return send('application/octet-stream','bad');
 }
 if(route.startsWith('/heathcliff/upload/')){
  uploadPosts.push(route);
  const chunks=[];for await(const chunk of req)chunks.push(chunk);
  uploadBodies.push(Buffer.concat(chunks).toString());
  return send('application/json',JSON.stringify({ok:false,error:{message:'Fixture stops before committing'}}));
 }
 if(route==='/heathcliff/api'||route==='/heathcliff/files'){
  const chunks=[];for await(const c of req)chunks.push(c);
  const data=JSON.parse(Buffer.concat(chunks));
  if(data.op==='roots')return send('application/json',JSON.stringify({ok:true,roots:pickerRoots?[{desk:'base',title:'Base',rev:10},{desk:'other',title:'Other',rev:4}]:[]}));
  if(data.op==='tree'){
   treeQueries.push(data);
   const paths=data.desk==='base'?[['data','notes','readme','md'],['data','picture','png'],['app','demo','hoon']]:[['data','docs','other','txt']];
   return send('application/json',JSON.stringify({ok:true,paths:paths.filter(path=>data.scope.every((part,i)=>path[i]===part)),tombs:[]}));
  }
  if(data.op==='load'){
   loads.push(data.path);
   if(data.path.at(-1)==='txt')return send('application/json',JSON.stringify({ok:true,...(data.path[1]==='now'?fileHead:{text:'historical contents',hash:'old-3'})}));
   return send('application/json',JSON.stringify({ok:true,text:'',hash:'fixture',readonly:data.path[1]!=='now'}));
  }
  if(data.op==='save'){
   saves.push(data);
   if(data.path[1]!=='now')return send('application/json',JSON.stringify({ok:false,error:{code:'read-only',message:'Historical location'}}),403);
   if(data.base!==fileHead.hash&&!data.overwrite)return send('application/json',JSON.stringify({ok:false,error:{code:'changed',message:'Current file changed'}}),409);
   fileHead={text:data.text,hash:'saved-'+saves.length};
   return send('application/json',JSON.stringify({ok:true,hash:fileHead.hash}));
  }
  if(data.op==='rule'){changes.push(data);return send('application/json',JSON.stringify({ok:true}));}
  if(data.op==='upload-check'){
   uploadChecks.push(data);
   const dot=data.filename.lastIndexOf('.'),name=data.filename.slice(0,dot),mark=data.filename.slice(dot+1);
   if(name==='slow')await new Promise(resolve=>setTimeout(resolve,500));
   return send('application/json',JSON.stringify({ok:true,clay:'/'+[...data.path.slice(2),name,mark].join('/'),mark,exists:name==='existing',install:[],problems:['txt','md','png'].includes(mark)?[]:['Unsupported mark: '+mark]}));
  }
  if(data.op==='markdown'){
   if(data.text==='slow')await new Promise(r=>setTimeout(r,200));
   return send('application/json',JSON.stringify(data.text==='failure'?{ok:false,error:{message:'bad markdown'}}:{ok:true,html:`<h1>${data.text}</h1>`}));
  }
  if(data.op==='attributes'){
   const mark=data.path.at(-1),type=mark==='png'?'image/png':mark==='svg'?'image/svg+xml':mark==='webm'?'video/webm':mark==='mov'?'video/quicktime':'audio/wav';
   return send('application/json',JSON.stringify({ok:true,target:{kind:'file',label:'sample.'+mark,mark,ship:'~zod',desk:'base',title:'Base',case:data.path[1],clay:'/sample/'+mark},current:data.path[1]==='now',head:10,file:{size:100,type,tombstoned:data.path.includes('gone')},permissions:{read:rule,write:rule,enforced:{read:true,write:true},crews:[],explicit:{rows:[]}}}));
  }
 }
 send('text/plain','not found',404);
});
(async()=>{
 // Compile the actual Hoon page and script, then expose test-only entry points.
const bindings=[['urui','desk/sur/urui.hoon'],['dock','desk/sur/docket.hoon'],['uhttp','desk/lib/urui-http.hoon'],['ufiles','desk/lib/urui-files.hoon'],['hc','desk/lib/heathcliff-clay.hoon'],['ucss','desk/lib/urui-css.hoon'],['uace','desk/lib/urui-ace.hoon'],['ucfg','desk/lib/urui-config.hoon'],['ujs','desk/lib/urui-js.hoon'],['shell','desk/lib/urui-shell.hoon'],['web','desk/lib/heathcliff-web.hoon']];
 const program = assemble(bindings,
   '[page:web css:web javascript:web ace-config-js:web]', root);
 // A regular file avoids losing vere's large result on pipe shutdown.
 const outputPath=path.join(cache,'eval-output.txt');
 const outputFile=fs.openSync(outputPath,'w');
 let compiled;
 try{
   compiled=require('child_process').spawnSync(findVere(),['eval'],{
     input:program,stdio:['pipe',outputFile,outputFile],timeout:180000
   });
 }finally{fs.closeSync(outputFile)}
 const output=fs.readFileSync(outputPath,'utf8');
 if(compiled.error)throw compiled.error;
 assert.equal(compiled.status,0,output);
 const assets=parseCords(output,4);
 assert(assets[0].includes('</html>'));
 new (require('vm').Script)(assets[2]);
 new (require('vm').Script)(assets[3]);
 ['page.html', 'app.css', 'app.js', 'ace.js'].forEach((name, i) =>
   fs.writeFileSync(path.join(cache, 'heathcliff-' + name), assets[i]));
 js = assets[2].replace('  loadRoots();\n  renderResult();',
   'window.hcTest = {openAttributes, renderers, cleanResult, runtime, attributeTargets, setSelected}; loadRoots();');
 assert(js.includes('window.hcTest'));

 await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const browser=await chromium.launch({headless:true});
 try{
 const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(`http://127.0.0.1:${server.address().port}/heathcliff`);
 await page.waitForFunction(()=>window.hcTest);
 for(const [mark,expected] of [['wav','8000 Hz'],['webm','V_VP8'],['mov','AVC'],['png','32 px'],['mime','PCM'],['svg','40 px']]){
  await page.evaluate(mark=>window.hcTest.openAttributes(['base','now','sample',mark],'file'),mark);
  await page.waitForFunction(()=>!document.querySelector('.hc-attributes:not([hidden]) .hc-attributes-body').textContent.includes('Reading file metadata'),null,{timeout:30000});
  const text=await page.locator('.hc-attributes:not([hidden]) .hc-attributes-body').innerText();console.log(`PASS ${mark} metadata`);
  assert(text.includes(expected),`missing ${expected}`);
  if(mark==='png'){
   assert.match(text,/Compression method\s+Deflate/);
   assert.match(text,/Stream size\s+2\.95 KiB \(100%\)/);
   assert.match(text,/Format description\s+Portable Network Graphic/);
   assert.match(text,/Packing method\s+Linear/);
   assert.match(text,/Pixel aspect ratio\s+1/);
  }
  if(mark==='wav'||mark==='mime'){
   assert.match(text,/Stream size\s+15\.63 KiB \(99\.73%\)/);
   assert.match(text,/Endianness\s+Little/);
   assert.match(text,/Sample representation\s+Signed/);
   assert.match(text,/Sample count\s+8000/);
  }
  if(mark==='webm'){
   assert.match(text,/Encoding application\s+Lavf/);
   assert.match(text,/Frame rate mode\s+Constant/);
   assert.match(text,/Default\s+Yes/);
   assert.match(text,/Forced\s+No/);
   assert.match(text,/Video delay\s+-7 ms/);
  }
  assert(!/Stream kind|Stream count|String\d|\bCount\s+\d/.test(text));
  assert(!text.includes('Permissions'));
  assert.equal(await page.locator('.hc-attributes:not([hidden]) form').count(),0);
  assert.equal(await page.locator('.hc-attributes:not([hidden]) .hc-attributes-body section:last-child input, .hc-attributes:not([hidden]) .hc-attributes-body section:last-child select, .hc-attributes:not([hidden]) .hc-attributes-body section:last-child textarea').count(),0);
 }
 await page.evaluate(async()=>{
  const body=document.getElementById('result-view');
  body.replaceChildren();
  window.hcTest.renderers.mov({path:['base','now','sample','mov']},body);
 });
 await page.waitForFunction(()=>document.querySelector('#result-view video')?.readyState>=1);
 assert.equal(await page.locator('#result-view video').evaluate(video=>video.videoWidth),32);
 await page.evaluate(async()=>{
await window.hcTest.openAttributes(['base','now','gone','png'],'file')});
 assert(!(await page.locator('.hc-attributes:not([hidden]) .hc-attributes-body').innerText()).includes('Image attributes'));
 await page.evaluate(async()=>{
await window.hcTest.openAttributes(['base','now','sample','wav'],'file');window.hcTest.runtime.explorer.refs.close(window.hcTest.runtime.explorer.view());await window.hcTest.openAttributes(['base','now','sample','png'],'file')});
 await page.waitForFunction(()=>!document.querySelector('.hc-attributes:not([hidden]) .hc-attributes-body').textContent.includes('Reading file metadata'));
 assert(!(await page.locator('.hc-attributes:not([hidden]) .hc-attributes-body section:last-child').innerText()).includes('8000 Hz'));
 assert.equal(await page.locator('[role="dialog"][aria-modal="true"]:visible').count(), 0);
 assert.equal(await page.locator('#explorer-pane .hc-attributes:not([hidden])').count(), 1);
 assert.equal(await page.locator('.ref-tab[aria-selected="true"]').innerText(), 'sample.png');
 await page.evaluate(() => window.hcTest.openAttributes(['base', '3', 'sample', 'png'], 'file'));
 assert.equal(await page.locator('.ref-tab[aria-selected="true"]').innerText(), 'sample.png version 3');
 assert.equal(await page.locator('.hc-attributes:not([hidden]) form').count(), 0);
 const refsBefore = await page.locator('.ref-tab').count();
 await page.evaluate(() => window.hcTest.openAttributes(['base', '3', 'sample', 'png'], 'file'));
 assert.equal(await page.locator('.ref-tab').count(), refsBefore);
 // Both menu actions are available and open distinct tabs for the same file.
 const openMenu = () => page.evaluate(() => window.hcTest.runtime.explorer.context.open(
   'clay', ['base','now','sample','png'], document.getElementById('apps-tab'),
   undefined, {entry:'file',view:'apps',tomb:false}));
 await openMenu();
 assert.equal(await page.getByRole('menuitem', {name:'Attributes…',exact:true}).count(),1);
 assert.equal(await page.getByRole('menuitem', {name:'File attributes…',exact:true}).count(),0);
 await page.getByRole('menuitem', {name:'Permissions…',exact:true}).click();
 await page.locator('[data-details="permissions"]:not([hidden]) form').first().waitFor();
 assert.equal(await page.locator('.hc-attributes:not([hidden]) form').count(),3);
 assert(!(await page.locator('.hc-attributes:not([hidden])').innerText()).includes('Image attributes'));
 const splitRefs = await page.locator('.ref-tab').count();
 await openMenu();
 await page.getByRole('menuitem', {name:'Attributes…',exact:true}).click();
 assert.equal(await page.locator('[data-details="attributes"]:not([hidden])').count(),1);
 assert.equal(await page.locator('.ref-tab').count(),splitRefs);
 await page.evaluate(() => window.hcTest.openAttributes(['base','now','sample','png'],'file','permissions'));
 assert.equal(await page.locator('.ref-tab').count(),splitRefs);
 await page.evaluate(() => window.hcTest.openAttributes(['base','3','sample','png'],'file','permissions'));
 assert.equal(await page.locator('.ref-tab[aria-selected="true"]').innerText(),'sample.png version 3');
 assert.equal(await page.locator('.hc-attributes:not([hidden]) form').count(),0);
 // Editing a rule in an older open reference must keep its own path.
 await page.evaluate(async () => {
   await window.hcTest.openAttributes(['other', 'now', 'sample', 'wav'], 'file', 'permissions');
   const ref = window.hcTest.runtime.explorer.refs.list().find(item =>
     item.kind === 'permissions' && item.data.path.join('/') === 'base/now/sample/png');
   window.hcTest.runtime.explorer.setView(ref.id);
 });
 assert.equal(await page.locator('.hc-attributes:not([hidden]) form').count(), 3);
 const mutation = page.waitForResponse(response => response.url().endsWith('/api') &&
   response.request().postDataJSON()?.op === 'rule');
 await page.locator('.hc-attributes:not([hidden])').getByRole('button',{name:'Set read here',exact:true}).click();
 await mutation;
 assert.deepEqual(changes.at(-1).path,['base','now','sample','png']);
 console.log('PASS separate Attributes and Permissions menus, tabs, and rule target');
 const labels = await page.evaluate(() => {
   const docs = window.hcTest.runtime.documents;
   for (const path of [['base','now','x','readme','md'], ['other','now','y','readme','md'], ['base','3','x','readme','md']]) {
     docs.create('clay', {path, text: '', clean: '', activate: false});
   }
   return docs.list('clay').filter(tab => tab.path).map(tab => tab.label);
 });
 assert.deepEqual(labels, ['readme.md', 'readme.md', 'readme.md version 3']);
 assert(await page.evaluate(() => window.hcTest.attributeTargets.size ===
   window.hcTest.runtime.explorer.refs.list().length));
 console.log('PASS reference tabs, historical labels, and source labels');
 // A reference tab opens its own file and revision on double-click.
 for(const [kind,revision] of [['attributes','now'],['permissions','3']]){
  const path=['base',revision,'sample','png'];
  await page.evaluate(({path,kind})=>window.hcTest.openAttributes(path,'file',kind),{path,kind});
  const tab=page.locator('.ref-tab[aria-selected="true"]');
  const before=loads.length;
  await tab.click();
  assert.equal(loads.length,before);
  await tab.dblclick();
  await page.waitForFunction(path=>JSON.stringify(window.hcTest.runtime.documents.active('clay')?.path)===JSON.stringify(path),path);
  assert.deepEqual(loads.at(-1),path);
  assert.equal(await page.locator('#result-view img').count(),1);
  assert.equal(await page.evaluate(()=>Boolean(window.hcTest.runtime.documents.active('clay').readonly)),revision!=='now');
  const count=await page.evaluate(()=>window.hcTest.runtime.documents.list('clay').length);
  const reload=page.waitForResponse(response=>response.url().endsWith('/files')&&response.request().postDataJSON()?.op==='load');
  await tab.dblclick();
  await reload;
  assert.equal(await page.evaluate(()=>window.hcTest.runtime.documents.list('clay').length),count);
 }
 const beforeTomb=loads.length;
 await page.evaluate(()=>window.hcTest.openAttributes(['base','now','gone','png'],'file'));
 await page.locator('.ref-tab[aria-selected="true"]').dblclick();
 assert.equal(loads.length,beforeTomb);
 console.log('PASS double-click opens reference files at their revision, reuses tabs, and ignores tombstones');
 assert.equal(await page.locator('#clay-copy').getAttribute('title'),'Copy to clipboard');
 const fullscreen=page.locator('#hc-result-fullscreen');
 const bar=await page.locator('.hc-result-head').boundingBox();
 const icon=await fullscreen.boundingBox();
 assert(Math.abs(icon.x+icon.width-bar.x-bar.width)<2);
 await fullscreen.click();
 await page.waitForFunction(()=>document.fullscreenElement?.id==='result-pane');
 assert.equal(await fullscreen.getAttribute('aria-pressed'),'true');
 await fullscreen.click();
 await page.waitForFunction(()=>!document.fullscreenElement);
 console.log('PASS result fullscreen placement and toggle, copy tooltip');
 await page.evaluate(()=>window.hcTest.openAttributes(['base','now','sample','mov'],'file'));
 await page.locator('.ref-tab[aria-selected="true"]').dblclick();
 await page.waitForFunction(()=>document.querySelector('#result-view video')?.readyState>=1);
 const player=page.locator('#result-view video');
 const paneVideo=await player.boundingBox();
 await player.evaluate(video=>{window.originalVideo=video;video.currentTime=0.1;});
 await page.waitForFunction(()=>!window.originalVideo.seeking);
 const position=await player.evaluate(video=>video.currentTime);
 await fullscreen.click();
 await page.waitForFunction(()=>document.fullscreenElement?.id==='result-pane');
 const fullVideo=await player.boundingBox();
 const videoBody=await page.locator('.hc-result-body').boundingBox();
 assert(fullVideo.width>paneVideo.width && fullVideo.height>paneVideo.height);
 assert(Math.abs(fullVideo.width-videoBody.width)<2);
 assert(Math.abs(fullVideo.height-videoBody.height)<2);
 assert.equal(await player.evaluate(video=>getComputedStyle(video).objectFit),'contain');
 await fullscreen.click();
 await page.waitForFunction(()=>!document.fullscreenElement);
 const restoredVideo=await player.boundingBox();
 assert(Math.abs(restoredVideo.width-paneVideo.width)<2);
 assert(Math.abs(restoredVideo.height-paneVideo.height)<2);
 assert(await player.evaluate(video=>video===window.originalVideo));
 assert.equal(await player.evaluate(video=>video.currentTime),position);
 console.log('PASS video expands with fullscreen and restores size and playback position');
 // Click Chromium's actual native fullscreen control, inside its UA shadow DOM.
 await fullscreen.click();
 await page.waitForFunction(()=>document.fullscreenElement?.id==='result-pane');
 await player.hover();
 const cdp=await page.context().newCDPSession(page);
 const nativeTree=await cdp.send('DOM.getDocument',{depth:-1,pierce:true});
 const findNativeToggle=node=>{
  if(node.attributes?.includes('-webkit-media-controls-fullscreen-button'))return node;
  for(const child of [...(node.children||[]),...(node.shadowRoots||[])]){
   const found=findNativeToggle(child);if(found)return found;
  }
 };
 const nativeToggle=findNativeToggle(nativeTree.root);
 assert(nativeToggle,'Native video fullscreen control is present');
 const {object}=await cdp.send('DOM.resolveNode',{nodeId:nativeToggle.nodeId});
 await cdp.send('Runtime.callFunctionOn',{
  objectId:object.objectId,functionDeclaration:'function(){this.click()}',userGesture:true
 });
 await page.waitForFunction(()=>!document.fullscreenElement);
 assert.equal(await fullscreen.getAttribute('aria-pressed'),'false');
 assert(await player.evaluate(video=>video===window.originalVideo));
 assert.equal(await player.evaluate(video=>video.currentTime),position);
 // Entering video fullscreen directly must still work without a pane layer.
 await player.evaluate(video=>video.requestFullscreen());
 await page.waitForFunction(()=>document.fullscreenElement===window.originalVideo);
 await page.evaluate(()=>document.exitFullscreen());
 await page.waitForFunction(()=>!document.fullscreenElement);
 await cdp.detach();
 console.log('PASS native video control exits pane fullscreen; standalone video fullscreen still works');
 // Editing a historical copy writes only to now, after explicit confirmation.
 const openHistory=async()=>{
  await page.evaluate(()=>window.hcTest.openAttributes(['base','3','history','txt'],'file'));
  await page.locator('.ref-tab[aria-selected="true"]').dblclick();
  await page.waitForFunction(()=>window.hcTest.runtime.documents.active('clay')?.path?.join('/')==='base/3/history/txt');
  assert.equal(await page.evaluate(()=>Boolean(window.hcTest.runtime.documents.active('clay').readonly)),false);
  assert.equal(await page.evaluate(()=>window.hcTest.runtime.documents.active('clay').label),'history.txt version 3');
 };
 const beginSave=async()=>{
  await page.evaluate(()=>{window.pendingSave=window.hcTest.runtime.documents.save('clay');});
  await page.locator('#urui-confirm').waitFor({state:'visible'});
  assert.match(await page.locator('#urui-confirm-message').innerText(),/will create a new current version/);
 };
 await openHistory();
 await page.evaluate(()=>window.hcTest.runtime.documents.editor('clay').setSource('edited historical contents'));
 await beginSave();
 await page.locator('#urui-confirm-cancel').click();
 await page.evaluate(()=>window.pendingSave);
 assert.equal(saves.length,0);
 assert.equal(fileHead.text,'current contents');
 assert.equal(await page.evaluate(()=>window.hcTest.runtime.documents.active('clay').text),'edited historical contents');
 await beginSave();
 await page.locator('#urui-confirm-ok').click();
 await page.evaluate(()=>window.pendingSave);
 assert.deepEqual(saves.at(-1).path,['base','now','history','txt']);
 assert.equal(saves.at(-1).base,'head-1');
 assert.equal(saves.at(-1).overwrite,false);
 assert.equal(fileHead.text,'edited historical contents');
 assert.equal(await page.evaluate(()=>window.hcTest.runtime.documents.active('clay').label),'history.txt');
 await openHistory();
 assert.equal(await page.evaluate(()=>window.hcTest.runtime.documents.active('clay').text),'historical contents');
 await page.evaluate(()=>window.hcTest.runtime.documents.editor('clay').setSource('another edit'));
 await beginSave();
 fileHead={text:'concurrent edit',hash:'head-raced'};
 await page.locator('#urui-confirm-ok').click();
 await page.waitForFunction(()=>document.getElementById('urui-confirm-message').textContent.includes('changed since it was loaded'));
 await page.locator('#urui-confirm-cancel').click();
 await page.evaluate(()=>window.pendingSave);
 assert.equal(fileHead.text,'concurrent edit');
 assert.equal(await page.evaluate(()=>window.hcTest.runtime.documents.active('clay').path[1]),'3');
 assert.equal(await page.evaluate(()=>window.hcTest.runtime.documents.active('clay').text),'another edit');
 console.log('PASS editable historical files, save warning/cancel, current destination, and concurrent-write protection');

 await page.evaluate(async()=>{

  window.hcTest.runtime.explorer.refs.close(window.hcTest.runtime.explorer.view());
  const body=document.querySelector('#result-view');
  await window.hcTest.renderers.md({text:'Heading'},body,()=>true);
 });
 assert.equal(await page.locator('#result-view h1').innerText(),'Heading');
 await page.evaluate(async()=>{
const body=document.querySelector('#result-view');body.replaceChildren();await window.hcTest.renderers.md({text:'failure'},body,()=>true)});
 assert((await page.locator('#result-view').innerText()).includes('bad markdown'));
 // Exercise the real chooser, preflight, and upload URL with fixture files.
 await page.locator('#settings').click();
 assert(await page.getByRole('radio',{name:'Apps upload to /data/',exact:true}).isChecked());
 await page.locator('#close-settings').click();
 const checkUpload = async (path, view, expected, submit=false) => {
   await page.evaluate(({path,view}) => {
     const {runtime} = window.hcTest;
     const target = {path,entry:'directory',view};
     runtime.explorer.setView(view);
     runtime.explorer.context.open('clay',path,
       document.getElementById(view+'-tab'),undefined,target);
   },{path,view});
   const chooser = page.waitForEvent('filechooser');
   await page.getByRole('menuitem',{name:'Upload…',exact:true}).click();
   await (await chooser).setFiles({name:'note.txt',mimeType:'text/plain',buffer:Buffer.from('hello')});
   await page.locator('#hc-upload').waitFor({state:'visible'});
   assert.deepEqual(uploadChecks.at(-1).path,expected);
   if(submit){
     const response = page.waitForResponse(r=>r.url().includes('/heathcliff/upload/'));
     await page.locator('#hc-upload-confirm').click();
     await response;
     assert.equal(uploadPosts.at(-1),'/heathcliff/upload/'+expected.join('/'));
   }
   await page.locator('#hc-upload-cancel').click();
 };
 await checkUpload(['base','now'],'apps',['base','now','data']);
 await checkUpload(['base','now','notes'],'apps',['base','now','data','notes']);
 await checkUpload(['base','now','data','notes'],'apps',['base','now','data','notes']);
 await checkUpload(['base','now','data','notes'],'data',['base','now','data','notes']);
 await page.locator('#settings').click();
 await page.getByRole('radio',{name:'Apps upload to /',exact:true}).check();
 await page.locator('#close-settings').click();
 await checkUpload(['base','now'],'apps',['base','now']);
 await checkUpload(['base','now','notes'],'apps',['base','now','notes'],true);
 await checkUpload(['base','now','data','notes'],'data',['base','now','data','notes']);
 await page.evaluate(()=>window.hcTest.runtime.session.save());
 await page.reload();
 await page.waitForFunction(()=>window.hcTest);
 await page.locator('#settings').click();
 assert(await page.getByRole('radio',{name:'Apps upload to /',exact:true}).isChecked());
 await page.locator('#close-settings').click();
 await page.addInitScript(()=>{
   const key='heathcliff.session';
   const saved=JSON.parse(localStorage.getItem(key));
   saved.preferences.appsUploadRoot='invalid';
   localStorage.setItem(key,JSON.stringify(saved));
 });
 await page.reload();
 await page.waitForFunction(()=>window.hcTest);
 await page.locator('#settings').click();
 assert(await page.getByRole('radio',{name:'Apps upload to /data/',exact:true}).isChecked());
 await page.locator('#close-settings').click();
 console.log('PASS Apps upload defaults, paths, Data isolation, and persistence');
 pickerRoots=true;
 await page.locator('#hc-upload-button').click();
 await page.locator('#hc-upload').waitFor({state:'visible'});
 const destination=page.locator('#hc-upload-path');
 assert.equal(await destination.inputValue(),'');
 await page.locator('.hc-upload-tree summary').filter({hasText:'%base /data'}).click();
 assert.equal(await destination.inputValue(),'/base/data/');
 await page.locator('.hc-upload-tree summary').filter({hasText:/^notes$/}).click();
 assert.equal(await destination.inputValue(),'/base/data/notes/');
 await page.locator('.hc-upload-tree').getByRole('button',{name:'readme.md',exact:true}).click();
 assert.equal(await destination.inputValue(),'/base/data/notes/readme.md');
 assert.deepEqual(treeQueries.at(-1),{op:'tree',desk:'base',case:'now',scope:['data']});
 const chooser=page.waitForEvent('filechooser');
 await page.locator('#hc-upload-choose').click();
 await (await chooser).setFiles({name:'local.txt',mimeType:'text/plain',buffer:Buffer.from('hello')});
 await page.waitForFunction(()=>!document.getElementById('hc-upload-confirm').disabled);
 assert.equal(uploadChecks.at(-1).filename,'readme.md');
 await destination.fill('/base/data/no-mark/');
 await page.waitForFunction(()=>document.getElementById('hc-upload-path').getAttribute('aria-invalid')==='true');
 assert(await page.locator('#hc-upload-confirm').isDisabled());
 await destination.fill('/base/data/name.unsupported');
 await page.locator('#hc-upload-body').getByText('Unsupported mark: unsupported',{exact:true}).waitFor();
 assert(await page.locator('#hc-upload-confirm').isDisabled());
 await destination.fill('/base/../bad.txt');
 await page.waitForFunction(()=>document.getElementById('hc-upload-path').getAttribute('aria-invalid')==='true');
 assert(await page.locator('#hc-upload-confirm').isDisabled());
 const slowRequest=page.waitForRequest(request=>request.url().endsWith('/api')&&request.postDataJSON()?.filename==='slow.txt');
 const slowResponse=page.waitForResponse(response=>response.url().endsWith('/api')&&response.request().postDataJSON()?.filename==='slow.txt');
 await destination.fill('/base/data/slow.txt');
 await slowRequest;
 await destination.fill('/base/data/');
 await slowResponse;
 assert(await page.locator('#hc-upload-confirm').isDisabled());
 await destination.fill('/other/data/new-folder/renamed/txt');
 await page.waitForFunction(()=>!document.getElementById('hc-upload-confirm').disabled);
 assert.deepEqual(uploadChecks.at(-1).path,['other','now','data','new-folder']);
 assert.equal(uploadChecks.at(-1).filename,'renamed.txt');
 const sent=page.waitForResponse(response=>response.url().includes('/heathcliff/upload/'));
 await page.locator('#hc-upload-confirm').click();
 await sent;
 assert.equal(uploadPosts.at(-1),'/heathcliff/upload/other/now/data/new-folder');
 assert(uploadBodies.at(-1).includes('filename="renamed.txt"'));
 await page.locator('#hc-upload-cancel').click();
 await page.locator('#settings').click();
 await page.getByRole('radio',{name:'Apps upload to /',exact:true}).check();
 await page.locator('#close-settings').click();
 await page.locator('#hc-upload-button').click();
 await page.locator('.hc-upload-tree summary').filter({hasText:/^%base \/$/}).click();
 assert.equal(await destination.inputValue(),'/base/');
 await page.locator('.hc-upload-tree summary').filter({hasText:/^app$/}).click();
 assert.equal(await destination.inputValue(),'/base/app/');
 assert.deepEqual(treeQueries.at(-1).scope,[]);
 await page.locator('#hc-upload-cancel').click();
 console.log('PASS toolbar upload destination tree, both settings, mark validation, stale checks, and renamed multipart upload');
 await page.locator('#help').click();
 assert(await page.locator('#fallback-help-content').isVisible());
 assert(await page.locator('#docs-help-content').isHidden());
 await page.locator('#close-help').click();
 docsEnabled=true;
 await page.locator('#help').click();
 await page.waitForFunction(()=>!document.getElementById('docs-help-content').hidden);
 const topics=[['keyboard-shortcuts','Keyboard Shortcuts'],['users-guide','Users Guide'],['about','About Heathcliff and Ace editor']];
 assert.deepEqual(await page.locator('#docs-help-nav a').allTextContents(),topics.map(([,title])=>title));
 for(const [slug,title] of topics){
  if(!(await page.locator('#docs-help-content').isVisible()))await page.locator('#help').click();
  const link=page.locator('#docs-help-nav a').filter({hasText:title});
  assert.equal(await link.getAttribute('href'),'/docs/d/heathcliff/'+slug);
  await link.click();
  const frame=page.frameLocator(`iframe[src="/docs/d/heathcliff/${slug}"]`);
  await frame.locator('pre').waitFor();
  assert((await frame.locator('pre').innerText()).includes('# '));
 }
 await page.reload();
 await page.waitForFunction(()=>window.hcTest?.runtime.explorer.docs.available()===true);
 assert.deepEqual(await page.evaluate(()=>window.hcTest.runtime.explorer.docs.list().map(tab=>tab.path)),topics.map(([slug])=>slug));
 assert.equal(await page.locator('iframe[src="/docs/d/heathcliff/about"]').count(),1);
 console.log('PASS doc.toc Help topics, documentation tabs, persistence, and fallback without /docs');
 console.log('Browser assertions passed',errors);assert.deepEqual(errors,[]);
 }finally{await browser.close();server.close();fs.rmSync(cache,{recursive:true,force:true});}
})().catch(e=>{console.error(e);server.close();fs.rmSync(cache,{recursive:true,force:true});process.exitCode=1});
