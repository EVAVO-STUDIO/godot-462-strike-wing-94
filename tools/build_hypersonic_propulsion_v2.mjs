import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath,pathToFileURL} from 'node:url';
import path from 'node:path';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const source=path.join(root,'assets/source/effects/hypersonic_propulsion_v2');
const studio=process.env.EVAVO_ART_STUDIO || 'C:/Gitrepos/evavo-art-studio';
const {finishRasterAsset}=await import(pathToFileURL(path.join(studio,'packages/media/dist/index.js')));
const manifest=JSON.parse(await readFile(path.join(source,'manifest.json'),'utf8'));
const hash=value=>createHash('sha256').update(value).digest('hex');
const pending=[];
for(const file of manifest.files){
  const input=await readFile(path.join(source,file.source));
  if(hash(input)!==file.sourceSha256) throw Error('Hypersonic propulsion source changed: '+file.source);
  const result=await finishRasterAsset(input,{ensureAlpha:true,format:'png'});
  if(hash(result.buffer)!==file.sha256) throw Error('Hypersonic propulsion output changed: '+file.target);
  const family=file.target.startsWith('blue_plume_')?'hypersonic_blue_plume':'hypersonic_engine_burst';
  const index=file.target.match(/_(\d+)\.png$/)?.[1];
  if(index===undefined) throw Error('Unrecognized reviewed propulsion target: '+file.target);
  pending.push({target:path.join(root,'assets/runtime/effects/persistent',family,index+'.png'),buffer:result.buffer});
}
for(const item of pending){await mkdir(path.dirname(item.target),{recursive:true});await writeFile(item.target,item.buffer);}
console.log('Ten reviewed hypersonic propulsion cels rebuilt with exact hashes.');
