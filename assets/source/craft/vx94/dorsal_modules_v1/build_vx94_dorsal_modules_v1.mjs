import {writeFile,mkdir} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const base='work/vx94_dorsal_modules_v1/';await mkdir(base+'layers',{recursive:true});
const authority={candidatePromotion:false,publication:false,targetRepositoryMutation:false,candidateApproval:false,providerExecution:false};
const banks=['hard_left','left','neutral','right','hard_right'];
const poses={fighter:{noseX:[15,30,32,34,48],noseY:[3,4,4,4,3],angles:[-28,-3,0,3,28]},bomber:{noseX:[10,26,32,40,55],noseY:[3,4,4,4,3],angles:[-29,-7,0,8,29]}};
function hardware(kind,active){
 let s='<path d="M-3 0h6l1 2v9l-1 2h-6l-1-2V2z" fill="#182832"/><path d="M-3 1h6v10h-6z" fill="#526770"/><path d="M-3 1h1v9h-1z" fill="#a1afae"/><path d="M2 2h1v9H2z" fill="#32464f"/>';
 if(kind==='point_defence_pod')s+='<path d="M-2 2h4v5h-4z" fill="#aeb8ad"/><path d="M-1 1h2v2h-2z" fill="#d0d3c4"/><path d="M-2 3h4v2h-4z" fill="#243b48"/><path d="M-2 8h4v2h-4z" fill="#293e49"/>';
 if(kind==='emp_disruptor')s+='<path d="M-2 2h4v8h-4z" fill="#253b46"/><path d="M-2 2h4v1h-4zM-2 5h4v1h-4zM-2 8h4v1h-4z" fill="#b4bdb0"/><path d="M-1 3h2v2h-2zM-1 6h2v2h-2z" fill="#697c7b"/>';
 if(kind==='magnetic_screen')s+='<path d="M-2 2h1v8h-1zM1 2h1v8H1z" fill="#aa9675"/><path d="M-1 2h2v1h-2zM-1 9h2v1h-2z" fill="#ccd0bd"/><path d="M-1 4h2v4h-2z" fill="#263c46"/>';
 const light=active?({point_defence_pod:'#ccd9ca',emp_disruptor:'#a9c5c4',magnetic_screen:'#d0b991'}[kind]):'#344851';
 return s+`<path d="M-1 11h2v1h-2z" fill="${light}"/>`;
}
const tasks=[],entries=[];
for(const kind of ['point_defence_pod','emp_disruptor','magnetic_screen'])for(const form of ['fighter','bomber'])for(const state of ['idle','active'])for(let bi=0;bi<5;bi++){
 const pose=poses[form],angle=pose.angles[bi],r=angle*Math.PI/180,dy=form==='fighter'?35:36,x=pose.noseX[bi]-dy*Math.sin(r),y=pose.noseY[bi]+dy*Math.cos(r),width=(bi===0||bi===4)?.8:1;
 const id=`${kind}_${form}_${state}_${banks[bi]}`;
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="72" shape-rendering="crispEdges"><g transform="translate(${x} ${y}) rotate(${angle}) scale(${width} 1)">${hardware(kind,state==='active')}</g></svg>`;
 await writeFile(base+'layers/'+id+'.svg',svg);const r0=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png'});await writeFile(base+'layers/'+id+'.png',r0.buffer);
 const sources=[`assets/runtime/craft/vx94/gameplay/bank/${form}_${banks[bi]}.png`,base+'layers/'+id+'.png'];
 tasks.push({id,kind:'image-composite',sources,targetPath:id+'.png',canvas:{width:64,height:72,background:'#00000000'},layers:sources.map((_,sourceIndex)=>({sourceIndex,x:0,y:0,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))});
 entries.push({id,kind,form,state,bank:banks[bi],anchor:[x,y],angle,width,pivot:[32,38]});
}
await writeFile(base+'manifest.json',JSON.stringify({status:'art_candidate_no_gameplay_change',entries},null,2));
await writeFile(base+'request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-dorsal-modules',projectId:'hypersonic',purpose:'Three physical support housings with restrained ready indication, mounted aft of the canopy',authority,tasks},null,2));
const boards=[];
for(const kind of ['point_defence_pod','emp_disruptor','magnetic_screen']){
 const sources=entries.filter(e=>e.kind===kind).map(e=>base+'composites/'+e.id+'.png');boards.push({id:kind,kind:'image-composite',sources,targetPath:kind+'.png',canvas:{width:640,height:576,background:'#15212b'},layers:sources.map((_,i)=>({sourceIndex:i,x:i%5*128,y:Math.floor(i/5)*144,width:128,height:144,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))});
}
await writeFile(base+'board_request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-dorsal-review',projectId:'hypersonic',purpose:'Each module: fighter idle/active and bomber idle/active across five banks',authority,tasks:boards},null,2));
