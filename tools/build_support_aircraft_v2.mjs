import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath,pathToFileURL} from 'node:url';
import path from 'node:path';
const repo=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const source=path.join(repo,'assets/source/support/aircraft_v2');
const studio=process.env.EVAVO_ART_STUDIO || 'C:/Gitrepos/evavo-art-studio';
const {finishRasterAsset}=await import(pathToFileURL(path.join(studio,'packages/media/dist/index.js')));
const manifest=JSON.parse(await readFile(path.join(source,'manifest.json'),'utf8'));
const sha=b=>createHash('sha256').update(b).digest('hex');
const pending=[];
for(const file of manifest.files){
  const input=await readFile(path.join(source,file.source));
  if(sha(input)!==file.sourceSha256) throw Error('Source hash mismatch: '+file.source);
  const result=await finishRasterAsset(input,file.spec);
  if(sha(result.buffer)!==file.sha256) throw Error('Render hash mismatch: '+file.target);
  pending.push({file,buffer:result.buffer});
}
// Verify the whole family before any production write.
for(const {file,buffer} of pending){
  const target=path.join(repo,file.target);
  await mkdir(path.dirname(target),{recursive:true});
  await writeFile(target,buffer);
}
console.log(pending.length+' support media assets rebuilt with exact approved hashes.');
