import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';

const source='work/vx94_transform_dorsal_modules_v1/';
const base='work/vx94_transform_module_damage_v1/';
await mkdir(base+'layers',{recursive:true});
const entries=[];
for(const route of ['bomber','hypersonic'])for(const kind of ['point_defence_pod','emp_disruptor','magnetic_screen'])for(const severity of ['scarred','burnt'])for(let exposure=0;exposure<10;exposure++){
 const u=exposure/9,h=u*u*(3-2*u),y=39+(route==='bomber'?h:4*h),width=route==='bomber'?1:1-.25*h;
 let mark='<path d="M-2 3h3v2h-1v3h-2z" fill="#272b2b" fill-opacity=".8"/><path d="M-2 4h1v2h1v2h1" fill="none" stroke="#101d26" stroke-width="1"/><path d="M-1 4h1v1h-1zM0 7h1v1H0z" fill="#a0a49a"/>';
 if(severity==='burnt')mark+='<path d="M-3 2h4v2h1v5h-3v1h-2z" fill="#20272b" fill-opacity=".9"/><path d="M-2 3h2v3h1v3h-2V7h-1z" fill="#101b22"/><path d="M0 4h1v1H0zM-2 8h1v1h-1z" fill="#89958f"/>';
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="72" shape-rendering="crispEdges"><g transform="translate(32 ${y}) scale(${width} 1)">${mark}</g></svg>`;
 const id=`${route}_${kind}_${severity}_${String(exposure).padStart(2,'0')}`,target=base+'layers/'+id;
 const mask=await readFile(`${source}layers/${route}_${kind}_idle_${String(exposure).padStart(2,'0')}.png`);
 await writeFile(target+'.svg',svg);
 const finished=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png',maskBuffer:mask});
 await writeFile(target+'.png',finished.buffer);
 await writeFile(target+'.evidence.json',JSON.stringify(finished.evidence,null,2));
 entries.push({id,route,kind,severity,exposure,anchor:[32,y],width,pivot:[32,38]});
}
await writeFile(base+'manifest.json',JSON.stringify({schema:'hypersonic_vx94_transform_module_damage_v1',status:'art_candidate',entries},null,2));
