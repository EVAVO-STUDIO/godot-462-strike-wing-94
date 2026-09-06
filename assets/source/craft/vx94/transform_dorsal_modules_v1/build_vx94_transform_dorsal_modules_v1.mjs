import {writeFile,mkdir} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';

const base='work/vx94_transform_dorsal_modules_v1/';
await mkdir(base+'layers',{recursive:true});

function hardware(kind,active){
 let s='<path d="M-3 0h6l1 2v9l-1 2h-6l-1-2V2z" fill="#182832"/><path d="M-3 1h6v10h-6z" fill="#526770"/><path d="M-3 1h1v9h-1z" fill="#a1afae"/><path d="M2 2h1v9H2z" fill="#32464f"/>';
 if(kind==='point_defence_pod')s+='<path d="M-2 2h4v5h-4z" fill="#aeb8ad"/><path d="M-1 1h2v2h-2z" fill="#d0d3c4"/><path d="M-2 3h4v2h-4z" fill="#243b48"/><path d="M-2 8h4v2h-4z" fill="#293e49"/>';
 if(kind==='emp_disruptor')s+='<path d="M-2 2h4v8h-4z" fill="#253b46"/><path d="M-2 2h4v1h-4zM-2 5h4v1h-4zM-2 8h4v1h-4z" fill="#b4bdb0"/><path d="M-1 3h2v2h-2zM-1 6h2v2h-2z" fill="#697c7b"/>';
 if(kind==='magnetic_screen')s+='<path d="M-2 2h1v8h-1zM1 2h1v8H1z" fill="#aa9675"/><path d="M-1 2h2v1h-2zM-1 9h2v1h-2z" fill="#ccd0bd"/><path d="M-1 4h2v4h-2z" fill="#263c46"/>';
 const light=active?({point_defence_pod:'#ccd9ca',emp_disruptor:'#a9c5c4',magnetic_screen:'#d0b991'}[kind]):'#344851';
 return s+`<path d="M-1 11h2v1h-2z" fill="${light}"/>`;
}

const entries=[];
for(const route of ['bomber','hypersonic'])for(const kind of ['point_defence_pod','emp_disruptor','magnetic_screen'])for(const state of ['idle','active'])for(let exposure=0;exposure<10;exposure++){
 const u=exposure/9,h=u*u*(3-2*u),y=39+(route==='bomber'?h:4*h),width=route==='bomber'?1:1-.25*h;
 const id=`${route}_${kind}_${state}_${String(exposure).padStart(2,'0')}`;
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="72" shape-rendering="crispEdges"><g transform="translate(32 ${y}) scale(${width} 1)">${hardware(kind,state==='active')}</g></svg>`;
 const target=base+'layers/'+id;
 await writeFile(target+'.svg',svg);
 const finished=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png'});
 await writeFile(target+'.png',finished.buffer);
 entries.push({id,route,kind,state,exposure,anchor:[32,y],width,pivot:[32,38]});
}
await writeFile(base+'manifest.json',JSON.stringify({schema:'hypersonic_vx94_transform_dorsal_modules_v1',status:'art_candidate',entries},null,2));
