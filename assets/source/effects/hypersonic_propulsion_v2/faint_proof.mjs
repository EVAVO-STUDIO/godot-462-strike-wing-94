import {readFile,writeFile} from 'node:fs/promises';
import {createTransparencyProofSheet} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const p='assets/source/effects/hypersonic_propulsion_v2/cels/engine_burst_5.png';
const r=await createTransparencyProofSheet(await readFile(p),{nearest:true});
await writeFile('work/hypersonic_propulsion_v2/proofs/engine_burst_5.png',r.png);
await writeFile('work/hypersonic_propulsion_v2/evidence/engine_burst_5.proof.json',JSON.stringify(r.evidence,null,2));
