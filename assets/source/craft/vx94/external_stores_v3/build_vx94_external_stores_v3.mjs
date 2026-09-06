import {writeFile,mkdir} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const base='work/vx94_external_stores_v3/';await mkdir(base+'layers',{recursive:true});
const authority={candidatePromotion:false,publication:false,targetRepositoryMutation:false,candidateApproval:false,providerExecution:false};
function store(kind,loaded){
 const rail='<path d="M-1 7h2v13h-2z" fill="#33434a"/><path d="M-1 8h1v10h-1z" fill="#99a5a2"/>';
 if(!loaded && kind!=='twin_rocket_pods')return rail;
 if(kind==='hunter_rack')return rail+'<path d="M0 0l2 4v11l2 4h-3v2h-2v-2h-3l2-4V4z" fill="#283943"/><path d="M0 1l1 4v14h-2V5z" fill="#babeb0"/><path d="M-1 5h2v2h-2z" fill="#a18246"/><path d="M-1 2h2v3h-2z" fill="#596568"/><path d="M-3 7h2v2h-3zM1 7h2l1 2H1zM-3 15h2v3h-3zM1 15h2l1 3H1z" fill="#7c8c90"/>';
 if(kind==='twin_rocket_pods')return rail+'<path d="M-2 4h4l1 2v12l-1 2h-4l-1-2V6z" fill="#293a43"/><path d="M-2 7h4v11h-4z" fill="#717b6b"/><path d="M-2 7h1v10h-1z" fill="#acb3a1"/><path d="M-2 5h4v3h-4z" fill="#111d26"/><path d="M-1 5h1v1h-1zM1 5h1v1H1zM0 7h1v1H0z" fill="'+(loaded?'#818b86':'#111d26')+'"/><path d="M-2 12h4v1h-4z" fill="#344952"/>';
 return rail+'<path d="M0 2l2 3 1 8-1 4 2 4h-8l2-4-1-4 1-8z" fill="#263638"/><path d="M0 3l1 3 1 7-1 5h-2l-1-5 1-7z" fill="#79836b"/><path d="M-1 6h2v1h-2z" fill="#c0af6b"/><path d="M-1 8h1v7h-1z" fill="#a0a88a"/><path d="M-3 19h6v2h-6z" fill="#586968"/>';
}
const tasks=[],entries=[];
for(const form of ['fighter','bomber'])for(const kind of ['hunter_rack','twin_rocket_pods','precision_bomb']){
 if(form==='fighter'&&kind==='precision_bomb')continue;
 for(const state of ['loaded',kind==='twin_rocket_pods'?'left_expended':'left_released','empty']){
  const id=`${form}_${kind}_${state}`,xs=form==='fighter'?[21,43]:[14,50],y=(form==='fighter'?32:35)-(kind==='twin_rocket_pods'?4:0);
  const sources=[];
  for(let side=0;side<2;side++){
   const loaded=state==='loaded'||((state==='left_released'||state==='left_expended')&&side===1);
   const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="72" shape-rendering="crispEdges"><g transform="translate(${xs[side]} ${y})">${store(kind,loaded)}</g></svg>`;
   const path=base+'layers/'+id+'_'+side;await writeFile(path+'.svg',svg);const r=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png'});await writeFile(path+'.png',r.buffer);sources.push(path+'.png');
  }
  sources.push(`assets/runtime/craft/vx94/gameplay/bank/${form}_neutral.png`);
  tasks.push({id,kind:'image-composite',sources,targetPath:id+'.png',canvas:{width:64,height:72,background:'#00000000'},layers:sources.map((_,sourceIndex)=>({sourceIndex,x:0,y:0,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))});
  entries.push({id,form,kind,state,store_noses:xs.map(x=>[x,y]),pivot:[32,38],scope:'Neutral art anchors, not gameplay release offsets'});
 }
}
await writeFile(base+'request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-external-stores',projectId:'hypersonic',purpose:'Existing missile/rocket/bomb roles as physical under-wing equipment; original authored layers',authority,tasks},null,2));
await writeFile(base+'manifest.json',JSON.stringify({status:'candidate',entries},null,2));
const sources=entries.map(e=>base+'composites/'+e.id+'.png');
await writeFile(base+'board_request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-external-stores-review',projectId:'hypersonic',purpose:'Five loadouts by loaded, left released, empty; 3x native inspection',authority,tasks:[{id:'stores',kind:'image-composite',sources,targetPath:'stores.png',canvas:{width:576,height:1080,background:'#15212b'},layers:sources.map((_,i)=>({sourceIndex:i,x:i%3*192,y:Math.floor(i/3)*216,width:192,height:216,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))}]},null,2));
