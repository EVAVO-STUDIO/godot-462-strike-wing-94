import {readFile,writeFile} from 'node:fs/promises';
const base='work/vx94_pitch_relief_v3/';const r=JSON.parse(await readFile(base+'native_request.json','utf8'));
r.sandboxId='hypersonic-pitch-hidden-rgb-clean';r.purpose='Clear fully transparent renderer RGB; preserve all visible RGBA';r.tasks=r.tasks.map(t=>({id:t.id,kind:'image',source:base+'native/'+t.targetPath,targetPath:t.targetPath,operations:[{op:'alpha-clean',threshold:0,binary:false,zeroTransparentRgb:true}]}));
await writeFile(base+'clean_request.json',JSON.stringify(r,null,2));
