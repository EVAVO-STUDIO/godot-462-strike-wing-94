import {writeFile,mkdir} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const root='C:/Gitrepos/godot-462-strike-wing-94/',base='work/vx94_specialist_housings_v2/';
await mkdir(root+base+'layers',{recursive:true});
const banks=['hard_left','left','neutral','right','hard_right'];
const poses={fighter:{x:[15,30,32,34,48],angle:[-28,-3,0,3,28],width:[.8,.95,1,.95,.8]},bomber:{x:[10,26,32,40,55],angle:[-29,-7,0,8,29],width:[.75,.9,1,.9,.75]}};
const weapons=['needle_rail','storm_cannon','plasma_lance'];
function hardware(weapon,state){
 let s='<path d="M-3 5h6v11h-6z" fill="#283943"/><path d="M-3 6h1v8h-1z" fill="#879aa0"/><path d="M2 6h1v8h-1z" fill="#526771"/>';
 if(state===0)return s+'<path d="M-2 3h4v5h-4z" fill="#7e9298"/><path d="M-2 4h4" stroke="#b4c0bd"/>';
 if(weapon==='needle_rail'){
  s+='<path d="M-2 0h1v10h-1zM1 0h1v10h-1z" fill="#bac5c2"/><path d="M-1 1h2v9h-2z" fill="#13232c"/><path d="M-3 7h6v1h-6zM-3 10h6v1h-6z" fill="#9aa8a8"/>';
  if(state>=2)s+=`<path d="M-1 1h2v2h-2z" fill="${state===3?'#e2f0e9':'#79aaa9'}"/>`;
 }else if(weapon==='storm_cannon'){
  s+='<path d="M-3 2l1-2h4l1 2v7h-6z" fill="#9baaa9"/><path d="M-2 1h4v3h-4z" fill="#223d48"/><path d="M-3 5h6v1h-6z" fill="#d1d4c6"/>';
  if(state>=2)s+=`<path d="M-2 1h4v2h-4z" fill="${state===3?'#f2edce':'#95bbc0'}"/>`;
 }else{
  s+='<path d="M-3 1h6v10h-6z" fill="#67777e"/><path d="M-2 0h4v4h-4z" fill="#b5b8a6"/><path d="M-1 1h2v2h-2z" fill="#302b2c"/><path d="M-4 5h1v5h-1zM3 5h1v5h-1z" fill="#bcc3b8"/><path d="M-2 7h4v1h-4zM-2 9h4v1h-4z" fill="#253540"/>';
  if(state>=2)s+=`<path d="M-1 1h2v2h-2z" fill="${state===3?'#ffe6b7':'#c5835b'}"/>`;
 }
 return s;
}
const tasks=[],frames=[];
for(const weapon of weapons)for(const [form,pose]of Object.entries(poses))for(let b=0;b<5;b++)for(let state=0;state<4;state++){
 const id=`${weapon}_${form}_${banks[b]}_${state}`;
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="72" shape-rendering="crispEdges"><g transform="translate(${pose.x[b]} 3) rotate(${pose.angle[b]}) scale(${pose.width[b]} 1)">${hardware(weapon,state)}</g></svg>`;
 await writeFile(root+base+'layers/'+id+'.svg',svg);
 const rendered=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png'});
 await writeFile(root+base+'layers/'+id+'.png',rendered.buffer);
 const sources=[base+'layers/'+id+'.png',`assets/runtime/craft/vx94/gameplay/bank/${form}_${banks[b]}.png`];
 if(state>0){
  const colours={needle_rail:['#1e343e','#79aaa9','#e2f0e9'],storm_cannon:['#223d48','#95bbc0','#f2edce'],plasma_lance:['#302b2c','#c5835b','#ffe6b7']};
  const x=weapon==='storm_cannon'?-2:-1,w=weapon==='storm_cannon'?4:2;
  const aperture=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="72" shape-rendering="crispEdges"><g transform="translate(${pose.x[b]} 3) rotate(${pose.angle[b]}) scale(${pose.width[b]} 1)"><path d="M${x} 1h${w}v2h-${w}z" fill="${colours[weapon][state-1]}"/></g></svg>`;
  await writeFile(root+base+'layers/'+id+'_aperture.svg',aperture);
  const a=await finishRasterAsset(Buffer.from(aperture),{ensureAlpha:true,format:'png'});
  await writeFile(root+base+'layers/'+id+'_aperture.png',a.buffer);
  sources.push(base+'layers/'+id+'_aperture.png');
 }
 tasks.push({id,kind:'image-composite',sources,targetPath:id+'.png',canvas:{width:64,height:72,background:'#00000000'},layers:sources.map((_,sourceIndex)=>({sourceIndex,x:0,y:0,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))});
 frames.push({id,weapon,form,bank:banks[b],state:['stowed','deployed','charged','discharge'][state],muzzle:[pose.x[b],3],angle:pose.angle[b],pivot:[32,38]});
}
await writeFile(root+base+'manifest.json',JSON.stringify({status:'candidate_visual_hardware_not_gameplay_offsets',weapons,poses,frames},null,2));
await writeFile(root+base+'request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'hypersonic-specialist-primary-hardware',projectId:'hypersonic',purpose:'Distinct centreline hardware for existing rail, pulse and plasma roles, registered beneath ten painted aircraft poses',authority:{candidatePromotion:false,publication:false,targetRepositoryMutation:false,candidateApproval:false,providerExecution:false},tasks},null,2));
