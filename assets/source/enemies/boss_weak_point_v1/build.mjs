import {mkdir,writeFile,copyFile,access,readFile} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
import {createHash} from 'node:crypto';

const base='assets/source/enemies/boss_weak_point_v1/';
const runtime='assets/runtime/enemies/boss_weak_point/';
await mkdir(base+'originals',{recursive:true});
await mkdir(base+'finished',{recursive:true});
await mkdir(runtime,{recursive:true});
const frames=[];
for(let i=0;i<4;i++){
 const inset=[3,2,1,2][i];
 const edge=17-inset;
 const hot=['#aa6a24','#d18a2f','#f2b548','#d18a2f'][i];
 const pale=['#c89042','#e4aa50','#ffe19a','#e4aa50'][i];
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" shape-rendering="crispEdges">
 <path fill="${hot}" d="M${inset} ${inset}H${inset+5}V${inset+2}H${inset+2}V${inset+5}H${inset}Z M${edge-5} ${inset}H${edge}V${inset+5}H${edge-2}V${inset+2}H${edge-5}Z M${inset} ${edge-5}H${inset+2}V${edge-2}H${inset+5}V${edge}H${inset}Z M${edge-2} ${edge-5}H${edge}V${edge}H${edge-5}V${edge-2}H${edge-2}Z"/>
 <path fill="${pale}" d="M8 5h2v2H8zm-3 3h2v2H5zm6 0h2v2h-2zm-3 3h2v2H8z"/>
 <path fill="#713d20" d="M8 8h2v2H8z"/></svg>`;
 const original=base+`originals/cue_v2_${i}.svg`;
 try{await access(original);}catch{await writeFile(original,svg);}
 const source=await readFile(original);
 const result=await finishRasterAsset(source,{ensureAlpha:true,format:'png'});
 const finished=base+`finished/cue_${i}.png`;
 await writeFile(finished,result.buffer);
 await writeFile(base+`finished/cue_${i}.evidence.json`,JSON.stringify(result.evidence,null,2));
 await copyFile(finished,runtime+`cue_${i}.png`);
 frames.push({file:`cue_${i}.png`,sha256:createHash('sha256').update(result.buffer).digest('hex').toUpperCase()});
}
await writeFile(base+'manifest.json',JSON.stringify({schema:'hypersonic_boss_weak_point_v1',status:'reviewed_art_candidate',canvas:[18,18],pivot:[9,9],frames,visual_contract:'Amber mechanical acquisition brackets and aperture ticks; no neon bloom; displayed only for exposed phase-three boss hardpoints.'},null,2)+'\n');
console.log('Built four EVAVO-finished boss weak-point cues.');
