import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const root='C:/Gitrepos/godot-462-strike-wing-94/',base='work/vx94_banked_housings/';
await mkdir(root+base+'layers',{recursive:true});
const poses={
fighter:{hard_left:{angle:-28,muzzles:[[18,25],[30,23]],widths:[1,.65],under:[1]},left:{angle:-3,muzzles:[[25,23],[37,24]],widths:[1,.85],under:[]},neutral:{angle:0,muzzles:[[26,23],[38,23]],widths:[1,1],under:[]},right:{angle:3,muzzles:[[27,24],[40,23]],widths:[.85,1],under:[]},hard_right:{angle:28,muzzles:[[34,23],[46,25]],widths:[.65,1],under:[0]}},
bomber:{hard_left:{angle:-29,muzzles:[[10,3]],widths:[.75],under:[0]},left:{angle:-7,muzzles:[[26,3]],widths:[.9],under:[0]},neutral:{angle:0,muzzles:[[32,3]],widths:[1],under:[0]},right:{angle:8,muzzles:[[39,3]],widths:[.9],under:[0]},hard_right:{angle:29,muzzles:[[55,3]],widths:[.75],under:[0]}}
};
function fighter(frame){const tip=[5,4,2,0][frame];let s='<path d="M-2 6h4v6h-4z" fill="#25313a"/><path d="M-2 6h1v5h-1z" fill="#9da9ac"/><path d="M1 6h1v5h-1z" fill="#576972"/>';if(!frame)return s+'<path d="M-1 6h2v4h-2z" fill="#71858e"/><path d="M-1 7h2" stroke="#aeb8b8"/>';return s+`<path d="M-1 ${tip}h2v${10-tip}h-2z" fill="#17232b"/><path d="M-1 ${tip+1}h1v${8-tip}h-1z" fill="#83949a"/><path d="M-1 7h2v1h-2z" fill="#b7c0bc"/>`;}
function bomber(frame){const tip=[9,6,3,0][frame];let s='<path d="M-4 10h8v8h-8z" fill="#25313a"/><path d="M-4 11h1v6h-1z" fill="#84959a"/><path d="M3 11h1v6h-1z" fill="#536773"/><path d="M-3 9h6v5h-6z" fill="#354750"/>';if(frame){for(const x of [-2,0,2])s+=`<path d="M${x} ${tip}h1v${14-tip}h-1z" fill="#17232b"/><path d="M${x} ${tip+1}h1v${11-tip}h-1z" fill="#788d98"/>`;s+=`<path d="M-2 ${tip+3}h5v1h-5z" fill="#a3b2b5"/>`;}return s;}
const tasks=[],evidence=[];
for(const [form,banks] of Object.entries(poses))for(const [bank,pose]of Object.entries(banks))for(let frame=0;frame<4;frame++){
 const id=`${form}_${bank}_${frame}`,sources=[`assets/runtime/craft/vx94/gameplay/bank/${form}_${bank}.png`],under=[],over=[];
 for(let p=0;p<pose.muzzles.length;p++){
  const [x,y]=pose.muzzles[p];
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="72" shape-rendering="crispEdges"><g transform="translate(${x} ${y}) rotate(${pose.angle}) scale(${pose.widths[p]} 1)">${form==='fighter'?fighter(frame):bomber(frame)}</g></svg>`;
  const name=`${id}_${p}`;
  await writeFile(root+base+'layers/'+name+'.svg',svg);
  const rendered=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png'});
  await writeFile(root+base+'layers/'+name+'.png',rendered.buffer);
  sources.push(base+'layers/'+name+'.png');
  (pose.under.includes(p)?under:over).push(sources.length-1);
 }
 tasks.push({id,kind:'image-composite',sources,targetPath:id+'.png',canvas:{width:64,height:72,background:'#00000000'},layers:[...under,0,...over].map(sourceIndex=>({sourceIndex,x:0,y:0,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))});
 evidence.push({id,form,bank,frame,...pose});
}
await writeFile(root+base+'poses.json',JSON.stringify({status:'candidate_visual_anchors_not_gameplay_offsets',canvas:[64,72],pivot:[32,38],poses},null,2));
await writeFile(root+base+'exposures.json',JSON.stringify(evidence,null,2));
await writeFile(root+base+'request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'hypersonic-banked-primary-housings',projectId:'hypersonic',purpose:'Forty primary deployment states with authored pose anchors and far-side occlusion',authority:{candidatePromotion:false,publication:false,targetRepositoryMutation:false,candidateApproval:false,providerExecution:false},tasks},null,2));
