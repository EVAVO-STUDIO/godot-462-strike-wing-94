import {readFile,writeFile,mkdir,copyFile} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const base='C:/Gitrepos/godot-462-strike-wing-94/work/mid_clouds_v3/';
const generated='C:/Users/User/.codex/generated_images/01a071b8-a586-7ed1-9626-51d73f4d1ddf/';
const sources={a:'exec-13a91203-64e7-4b44-a3e1-cf8c3d80c1fc.png',b:'exec-a4c84170-423c-4f4f-b95c-17116914f751.png',c:'exec-1395c468-ab75-448c-8d3e-bcc9dea7e3c1.png',d:'exec-2756ae8b-2a95-446c-ba6a-0bcf330bc7a3.png'};
await mkdir(base+'sources',{recursive:true});await mkdir(base+'native',{recursive:true});
const evidence={};
for(const [id,file] of Object.entries(sources)){
 await copyFile(generated+file,base+'sources/'+id+'.png');
 const r=await finishRasterAsset(await readFile(base+'sources/'+id+'.png'),{ensureAlpha:true,trim:{threshold:0,padding:4},resize:{width:248,height:104,fit:'inside',withoutEnlargement:true},format:'png'});
 const w=r.evidence.outputWidth,h=r.evidence.outputHeight;
 const final=await finishRasterAsset(r.buffer,{ensureAlpha:true,padding:{top:Math.floor((112-h)/2),bottom:Math.ceil((112-h)/2),left:Math.floor((256-w)/2),right:Math.ceil((256-w)/2),background:'#00000000'},format:'png'});
 await writeFile(base+'native/'+id+'.png',final.buffer);evidence[id]={resize:r.evidence,padding:final.evidence};
}
await writeFile(base+'finish.json',JSON.stringify(evidence,null,2));
