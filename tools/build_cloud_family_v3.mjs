import {readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const source=path.join(root,'assets/source/environments/cloud_family_v3');
const manifest=JSON.parse(await readFile(path.join(source,'manifest.json'),'utf8'));
const pending=[];
for(const item of manifest.files){const bytes=await readFile(path.join(source,'masters',item.source));if(createHash('sha256').update(bytes).digest('hex')!==item.sha256)throw Error('Cloud master changed: '+item.source);pending.push({target:item.target,bytes});}
for(const item of pending)await writeFile(path.join(root,'assets/runtime/environments/clouds',item.target),item.bytes);
console.log('Three reviewed cloud masters installed after all source hashes passed.');
