import {writeFile,mkdir} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const base='work/vx94_banked_stores_v2/';await mkdir(base+'layers',{recursive:true});
const authority={candidatePromotion:false,publication:false,targetRepositoryMutation:false,candidateApproval:false,providerExecution:false};
function store(kind,loaded){
 const rail='<path d="M-1 7h2v13h-2z" fill="#33434a"/><path d="M-1 8h1v10h-1z" fill="#99a5a2"/>';
 if(!loaded && kind!=='twin_rocket_pods')return rail;
 if(kind==='hunter_rack')return rail+'<path d="M0 0l2 4v11l2 4h-3v2h-2v-2h-3l2-4V4z" fill="#283943"/><path d="M0 1l1 4v14h-2V5z" fill="#babeb0"/><path d="M-1 5h2v2h-2z" fill="#a18246"/><path d="M-1 2h2v3h-2z" fill="#596568"/><path d="M-3 7h2v2h-3zM1 7h2l1 2H1zM-3 15h2v3h-3zM1 15h2l1 3H1z" fill="#7c8c90"/>';
 if(kind==='twin_rocket_pods')return rail+'<path d="M-2 4h4l1 2v12l-1 2h-4l-1-2V6z" fill="#293a43"/><path d="M-2 7h4v11h-4z" fill="#717b6b"/><path d="M-2 7h1v10h-1z" fill="#acb3a1"/><path d="M-2 5h4v3h-4z" fill="#111d26"/><path d="M-1 5h1v1h-1zM1 5h1v1H1zM0 7h1v1H0z" fill="'+(loaded?'#818b86':'#111d26')+'"/><path d="M-2 12h4v1h-4z" fill="#344952"/>';
 return rail+'<path d="M0 2l2 3 1 8-1 4 2 4h-8l2-4-1-4 1-8z" fill="#263638"/><path d="M0 3l1 3 1 7-1 5h-2l-1-5 1-7z" fill="#79836b"/><path d="M-1 6h2v1h-2z" fill="#c0af6b"/><path d="M-1 8h1v7h-1z" fill="#a0a88a"/><path d="M-3 19h6v2h-6z" fill="#586968"/>';
}

const banks=['hard_left','left','neutral','right','hard_right'];
const poses={fighter:{noseX:[15,30,32,34,48],noseY:[3,4,4,4,3],angles:[-28,-3,0,3,28]},bomber:{noseX:[10,26,32,40,55],noseY:[3,4,4,4,3],angles:[-29,-7,0,8,29]}};
const tasks=[],entries=[];
for(const form of ['fighter','bomber'])for(const kind of ['hunter_rack','twin_rocket_pods','precision_bomb']){
 if(form==='fighter'&&kind==='precision_bomb')continue;
 for(const state of ['loaded',kind==='twin_rocket_pods'?'left_expended':'left_released','empty'])for(let bi=0;bi<5;bi++){
  const bank=banks[bi],pose=poses[form],angle=pose.angles[bi],theta=angle*Math.PI/180;
  const id=`${form}_${kind}_${state}_${bank}`,xs=form==='fighter'?[21,43]:[14,50],y=(form==='fighter'?32:35)-(kind==='twin_rocket_pods'?4:0),sources=[],noses=[];
  for(let side=0;side<2;side++){
   const loaded=state==='loaded'||((state==='left_released'||state==='left_expended')&&side===1);
   const rawDx=xs[side]-32,hard=bi===0||bi===4,farSide=(bi===0&&side===1)||(bi===4&&side===0); const dx=hard?(farSide?rawDx*.5:rawDx+Math.sign(rawDx)*4.5):rawDx,dy=y-4;
   const x=pose.noseX[bi]+dx*Math.cos(theta)-dy*Math.sin(theta),yy=pose.noseY[bi]+dx*Math.sin(theta)+dy*Math.cos(theta);
   const far=(bi===0&&side===1)||(bi===4&&side===0),width=far?.65:1;
   const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="72" shape-rendering="crispEdges"><g transform="translate(${x} ${yy}) rotate(${angle}) scale(${width} 1)">${store(kind,loaded)}</g></svg>`;
   const path=base+'layers/'+id+'_'+side;await writeFile(path+'.svg',svg);const r=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png'});await writeFile(path+'.png',r.buffer);sources.push(path+'.png');noses.push({side,x,y:yy,angle,width});
  }
  sources.push(`assets/runtime/craft/vx94/gameplay/bank/${form}_${bank}.png`);
  tasks.push({id,kind:'image-composite',sources,targetPath:id+'.png',canvas:{width:64,height:72,background:'#00000000'},layers:sources.map((_,sourceIndex)=>({sourceIndex,x:0,y:0,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))});
  entries.push({id,form,kind,state,bank,store_noses:noses,pivot:[32,38],scope:'Art registration candidate, not gameplay release offsets'});
 }
}
await writeFile(base+'request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-banked-stores',projectId:'hypersonic',purpose:'Retained ordnance across five authored bank silhouettes with under-wing occlusion',authority,tasks},null,2));
await writeFile(base+'manifest.json',JSON.stringify({status:'candidate',poses,entries},null,2));
const boards=[];
for(const [form,kind]of [['fighter','hunter_rack'],['fighter','twin_rocket_pods'],['bomber','hunter_rack'],['bomber','twin_rocket_pods'],['bomber','precision_bomb']]){
 const sources=entries.filter(e=>e.form===form&&e.kind===kind).map(e=>base+'composites/'+e.id+'.png');
 boards.push({id:form+'_'+kind,kind:'image-composite',sources,targetPath:form+'_'+kind+'.png',canvas:{width:640,height:432,background:'#15212b'},layers:sources.map((_,i)=>({sourceIndex:i,x:i%5*128,y:Math.floor(i/5)*144,width:128,height:144,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))});
}
await writeFile(base+'board_request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-banked-stores-review',projectId:'hypersonic',purpose:'Five banks, three static load states, five loadouts',authority,tasks:boards},null,2));
