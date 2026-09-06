import {writeFile,mkdir} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';

const base='work/vx94_transform_precision_bombs_v1/';
await mkdir(base+'layers',{recursive:true});

function bomb(loaded){
 const rail='<path d="M-1 7h2v13h-2z" fill="#33434a"/><path d="M-1 8h1v10h-1z" fill="#99a5a2"/>';
 if(!loaded)return rail;
 return rail+'<path d="M0 2l2 3 1 8-1 4 2 4h-8l2-4-1-4 1-8z" fill="#263638"/><path d="M0 3l1 3 1 7-1 5h-2l-1-5 1-7z" fill="#79836b"/><path d="M-1 6h2v1h-2z" fill="#c0af6b"/><path d="M-1 8h1v7h-1z" fill="#a0a88a"/><path d="M-3 19h6v2h-6z" fill="#586968"/>';
}

const wingAngles=[-22,-20,-17,-13,-9,-5,-2,0,2.5,0];
const entries=[];
for(const state of ['loaded','left_released','empty'])for(let exposure=0;exposure<10;exposure++){
 const t=(wingAngles[exposure]+22)/22;
 const x=21-7*t,y=32+3*t;
 const id=`bomber_precision_bomb_${state}_${String(exposure).padStart(2,'0')}`;
 for(let side=0;side<2;side++){
  const loaded=state==='loaded'||(state==='left_released'&&side===1),px=side===0?x:64-x;
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="72" shape-rendering="crispEdges"><g transform="translate(${px} ${y})">${bomb(loaded)}</g></svg>`;
  const target=base+'layers/'+id+'_'+side;
  await writeFile(target+'.svg',svg);
  const finished=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png'});
  await writeFile(target+'.png',finished.buffer);
 }
 entries.push({id,state,exposure,anchors:[[x,y],[64-x,y]],pivot:[32,38]});
}
await writeFile(base+'manifest.json',JSON.stringify({schema:'hypersonic_vx94_transform_precision_bombs_v1',status:'art_candidate',entries},null,2));
