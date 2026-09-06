import {readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=new URL('../',import.meta.url),source=new URL('assets/source/ui/menu/mission_intel_v2/',root),manifest=JSON.parse(await readFile(new URL('runtime_manifest.json',source),'utf8'));
const verified=[];
for(const item of manifest.files){const bytes=await readFile(new URL(item.source,source));if(createHash('sha256').update(bytes).digest('hex')!==item.sha256)throw Error('Reviewed icon/screen source changed: '+item.source);verified.push({item,bytes});}
for(const {item,bytes}of verified)await writeFile(new URL(item.runtime,root),bytes);
process.stdout.write(`Installed ${verified.length} verified mission-interface media assets.\n`);
