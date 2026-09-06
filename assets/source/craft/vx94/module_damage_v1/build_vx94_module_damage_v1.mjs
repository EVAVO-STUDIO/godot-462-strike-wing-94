import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const b='work/vx94_module_damage_v1/';await mkdir(b+'layers',{recursive:true});
const modules=JSON.parse(await readFile('work/vx94_dorsal_modules_v1/manifest.json','utf8')).entries.filter(e=>e.state==='idle');
const authority={candidatePromotion:false,publication:false,targetRepositoryMutation:false,candidateApproval:false,providerExecution:false},tasks=[],entries=[];
for(const m of modules)for(const severity of ['scarred','burnt']){
 const heavy=severity==='burnt';let mark='<path d="M-2 3h3v2h-1v3h-2z" fill="#272b2b" fill-opacity=".8"/><path d="M-2 4h1v2h1v2h1" fill="none" stroke="#101d26" stroke-width="1"/><path d="M-1 4h1v1h-1zM0 7h1v1H0z" fill="#a0a49a"/>';
 if(heavy)mark+='<path d="M-3 2h4v2h1v5h-3v1h-2z" fill="#20272b" fill-opacity=".9"/><path d="M-2 3h2v3h1v3h-2V7h-1z" fill="#101b22"/><path d="M0 4h1v1H0zM-2 8h1v1h-1z" fill="#89958f"/>';
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="64" height="72" shape-rendering="crispEdges"><g transform="translate(${m.anchor[0]} ${m.anchor[1]}) rotate(${m.angle}) scale(${m.width} 1)">${mark}</g></svg>`;
 const id=m.id.replace('_idle_','_'+severity+'_'),layer=b+'layers/'+id,mask=await readFile('work/vx94_dorsal_modules_v1/layers/'+m.id+'.png');
 await writeFile(layer+'.svg',svg);const r=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png',maskBuffer:mask});await writeFile(layer+'.png',r.buffer);await writeFile(layer+'.evidence.json',JSON.stringify(r.evidence,null,2));
 const sources=['work/vx94_dorsal_modules_v1/composites/'+m.id+'.png',layer+'.png'];tasks.push({id,kind:'image-composite',sources,targetPath:id+'.png',canvas:{width:64,height:72,background:'#00000000'},layers:sources.map((_,sourceIndex)=>({sourceIndex,x:0,y:0,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))});entries.push({...m,id,severity,base_id:m.id});
}
await writeFile(b+'manifest.json',JSON.stringify({status:'localized_module_damage_art_candidate',entries},null,2));await writeFile(b+'request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-module-damage',projectId:'hypersonic',purpose:'Localized hardware scorch and fractured finish; mask retained module silhouette',authority,tasks},null,2));
const boards=[];for(const kind of ['point_defence_pod','emp_disruptor','magnetic_screen']){
 const sources=[];for(const form of ['fighter','bomber'])for(const state of ['idle','scarred','burnt'])for(const bank of ['hard_left','left','neutral','right','hard_right'])sources.push(state==='idle'?`work/vx94_dorsal_modules_v1/composites/${kind}_${form}_idle_${bank}.png`:`${b}composites/${kind}_${form}_${state}_${bank}.png`);
 boards.push({id:kind,kind:'image-composite',sources,targetPath:kind+'.png',canvas:{width:640,height:864,background:'#15212b'},layers:sources.map((_,i)=>({sourceIndex:i,x:i%5*128,y:Math.floor(i/5)*144,width:128,height:144,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))});
}await writeFile(b+'board_request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-module-damage-board',projectId:'hypersonic',purpose:'Intact, scarred, burnt module presentation for both forms and five banks',authority,tasks:boards},null,2));
