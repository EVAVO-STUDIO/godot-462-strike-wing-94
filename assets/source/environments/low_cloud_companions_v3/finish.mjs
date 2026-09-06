import {readFile,writeFile,mkdir,copyFile} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const base='C:/Gitrepos/godot-462-strike-wing-94/work/low_cloud_companions_v3/';
const generated='C:/Users/User/.codex/generated_images/01a071b8-a586-7ed1-9626-51d73f4d1ddf/';
const sources={b:'exec-fc129ac5-f9ed-4fc5-8450-06b0ad965e8c.png',c:'exec-2c6cf9b5-bd65-4de1-97fc-314bac6e461f.png',d:'exec-343d2225-a51a-4bde-a275-af5ab9725f1b.png'};
await mkdir(base+'sources',{recursive:true});await mkdir(base+'native',{recursive:true});
const evidence={};
for(const [id,file] of Object.entries(sources)){
 await copyFile(generated+file,base+'sources/'+id+'.png');
 const r=await finishRasterAsset(await readFile(base+'sources/'+id+'.png'),{ensureAlpha:true,trim:{threshold:0,padding:4},resize:{width:184,height:56,fit:'inside',withoutEnlargement:true},format:'png'});
 const w=r.evidence.outputWidth,h=r.evidence.outputHeight;
 const final=await finishRasterAsset(r.buffer,{ensureAlpha:true,padding:{top:Math.floor((64-h)/2),bottom:Math.ceil((64-h)/2),left:Math.floor((192-w)/2),right:Math.ceil((192-w)/2),background:'#00000000'},format:'png'});
 await writeFile(base+'native/'+id+'.png',final.buffer);evidence[id]={resize:r.evidence,padding:final.evidence};
}
await writeFile(base+'finish.json',JSON.stringify(evidence,null,2));
