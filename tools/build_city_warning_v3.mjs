import {readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath,pathToFileURL} from 'node:url';
import path from 'node:path';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const source=path.join(root,'assets/source/cinematics/city_warning_v3');
const studio=process.env.EVAVO_ART_STUDIO || 'C:/Gitrepos/evavo-art-studio';
const {finishRasterAsset}=await import(pathToFileURL(path.join(studio,'packages/media/dist/index.js')));
const manifest=JSON.parse(await readFile(path.join(source,'manifest.json'),'utf8'));
const hash=b=>createHash('sha256').update(b).digest('hex');
const pending=[];
for(const file of manifest.files){
 const bytes=await readFile(path.join(source,file.source));
 if(hash(bytes)!==file.sourceSha256) throw Error('City warning source changed: '+file.source);
 const result=await finishRasterAsset(bytes,{ensureAlpha:true,format:'png'});
 if(hash(result.buffer)!==file.sha256) throw Error('City warning output changed: '+file.target);
 pending.push({file,bytes:result.buffer});
}
for(const item of pending) await writeFile(path.join(root,'assets/runtime/cinematics/fx/machine_war',item.file.target),item.bytes);
console.log('Four reviewed city-warning cels rebuilt with exact hashes.');
