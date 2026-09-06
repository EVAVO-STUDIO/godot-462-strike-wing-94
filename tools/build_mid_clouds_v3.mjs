import {readFile,copyFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const dir=path.join(root,'assets/source/environments/mid_clouds_v3');
const m=JSON.parse(await readFile(path.join(dir,'manifest.json'),'utf8'));
for(const frame of m.frames){
 if(createHash('sha256').update(await readFile(path.join(dir,frame.master))).digest('hex')!==frame.sha256)throw Error('Mid-cloud master hash mismatch: '+frame.id);
}
for(const frame of m.frames)await copyFile(path.join(dir,frame.master),path.join(root,frame.runtime));
console.log('Delivered four verified 256x112 mid-cloud masters. Generative source creation is not deterministic.');
