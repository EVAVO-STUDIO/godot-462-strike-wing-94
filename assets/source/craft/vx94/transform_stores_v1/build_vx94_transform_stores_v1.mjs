import {writeFile,mkdir} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const base='work/vx94_transform_stores_v1/';await mkdir(base+'layers',{recursive:true});
const authority={candidatePromotion:false,publication:false,targetRepositoryMutation:false,candidateApproval:false,providerExecution:false};
function store(kind,loaded){
 const rail='<path d="M-1 7h2v13h-2z" fill="#33434a"/><path d="M-1 8h1v10h-1z" fill="#99a5a2"/>';
 if(!loaded && kind!=='twin_rocket_pods')return rail;
 if(kind==='hunter_rack')return rail+'<path d="M0 0l2 4v11l2 4h-3v2h-2v-2h-3l2-4V4z" fill="#283943"/><path d="M0 1l1 4v14h-2V5z" fill="#babeb0"/><path d="M-1 5h2v2h-2z" fill="#a18246"/><path d="M-1 2h2v3h-2z" fill="#596568"/><path d="M-3 7h2v2h-3zM1 7h2l1 2H1zM-3 15h2v3h-3zM1 15h2l1 3H1z" fill="#7c8c90"/>';
 if(kind==='twin_rocket_pods')return rail+'<path d="M-2 4h4l1 2v12l-1 2h-4l-1-2V6z" fill="#293a43"/><path d="M-2 7h4v11h-4z" fill="#717b6b"/><path d="M-2 7h1v10h-1z" fill="#acb3a1"/><path d="M-2 5h4v3h-4z" fill="#111d26"/><path d="M-1 5h1v1h-1zM1 5h1v1H1zM0 7h1v1H0z" fill="'+(loaded?'#818b86':'#111d26')+'"/><path d="M-2 12h4v1h-4z" fill="#344952"/>';
 return rail+'<path d="M0 2l2 3 1 8-1 4 2 4h-8l2-4-1-4 1-8z" fill="#263638"/><path d="M0 3l1 3 1 7-1 5h-2l-1-5 1-7z" fill="#79836b"/><path d="M-1 6h2v1h-2z" fill="#c0af6b"/><path d="M-1 8h1v7h-1z" fill="#a0a88a"/><path d="M-3 19h6v2h-6z" fill="#586968"/>';
}

const wingAngles=[-22,-20,-17,-13,-9,-5,-2,0,2.5,0],tasks=[],entries=[];
for(const kind of ['hunter_rack','twin_rocket_pods'])for(let i=0;i<10;i++){
 const t=(wingAngles[i]+22)/22,x=21-7*t,y=(kind==='twin_rocket_pods'?28:32)+3*t,id=`${kind}_${String(i).padStart(2,'0')}`,sources=[];
 for(let side=0;side<2;side++){
  const px=side===0?x:64-x;const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="72" shape-rendering="crispEdges"><g transform="translate(${px} ${y})">${store(kind,true)}</g></svg>`;
  const p=base+'layers/'+id+'_'+side;await writeFile(p+'.svg',svg);const r=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png'});await writeFile(p+'.png',r.buffer);sources.push(p+'.png');
 }
 sources.push(`assets/runtime/craft/vx94/transform/bomber_${String(i).padStart(2,'0')}.png`);
 tasks.push({id,kind:'image-composite',sources,targetPath:id+'.png',canvas:{width:64,height:72,background:'#00000000'},layers:sources.map((_,sourceIndex)=>({sourceIndex,x:0,y:0,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))});entries.push({id,kind,exposure:i,wing_angle:wingAngles[i],noses:[[x,y],[64-x,y]],pivot:[32,38],note:'Forward-aligned swivel rails, includes wing overshoot at exposure 8'});
}
await writeFile(base+'manifest.json',JSON.stringify({status:'transform_art_candidate',entries},null,2));
await writeFile(base+'request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-transform-stores',projectId:'hypersonic',purpose:'Retained stores follow ten authored wing exposures, forward-aligned swivel pylons',authority,tasks},null,2));
const sources=entries.map(e=>base+'composites/'+e.id+'.png');await writeFile(base+'board_request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-transform-stores-board',projectId:'hypersonic',purpose:'Ten exposures: Hunter Rack then Twin Rocket Pods',authority,tasks:[{id:'transform_stores',kind:'image-composite',sources,targetPath:'transform_stores.png',canvas:{width:1280,height:288,background:'#15212b'},layers:sources.map((_,i)=>({sourceIndex:i,x:i%10*128,y:Math.floor(i/10)*144,width:128,height:144,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))}]},null,2));
