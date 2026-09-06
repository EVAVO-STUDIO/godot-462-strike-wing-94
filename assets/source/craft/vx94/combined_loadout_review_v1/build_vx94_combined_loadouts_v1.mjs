import {readFile,writeFile,mkdir} from 'node:fs/promises';
const b='work/vx94_combined_loadouts_v1/';await mkdir(b,{recursive:true});
const primary=JSON.parse(await readFile('work/vx94_banked_housings/request.json','utf8')).tasks;
const specialist=JSON.parse(await readFile('work/vx94_specialist_housings_v2/request.json','utf8')).tasks;
const stores=JSON.parse(await readFile('work/vx94_banked_stores_v2/request.json','utf8')).tasks;
const dorsal=JSON.parse(await readFile('work/vx94_dorsal_modules_v1/request.json','utf8')).tasks;
const loadouts=[['ballistic','twin_rocket_pods'],['needle_rail','hunter_rack'],['plasma_lance','magnetic_screen'],['storm_cannon','emp_disruptor'],['ballistic','point_defence_pod']];
const banks=['hard_left','left','neutral','right','hard_right'],entries=[],tasks=[];
const authority={candidatePromotion:false,publication:false,targetRepositoryMutation:false,candidateApproval:false,providerExecution:false};
for(const [weapon,support] of loadouts)for(const form of ['fighter','bomber'])for(const bank of banks){
 const p=weapon==='ballistic'?primary.find(t=>t.id===`${form}_${bank}_3`):specialist.find(t=>t.id===`${weapon}_${form}_${bank}_2`);
 const s=['twin_rocket_pods','hunter_rack'].includes(support)?stores.find(t=>t.id===`${form}_${support}_loaded_${bank}`):dorsal.find(t=>t.id===`${support}_${form}_active_${bank}`);
 if(!p||!s)throw Error('Missing loadout source');
 const body=`assets/runtime/craft/vx94/gameplay/bank/${form}_${bank}.png`,under=[],over=[];
 for(const task of [s,p]){let above=false;for(const layer of task.layers){const source=task.sources[layer.sourceIndex];if(source===body){above=true;continue;}(above?over:under).push(source);}}
 const sources=[...under,body,...over],id=`${weapon}_${support}_${form}_${bank}`;
 tasks.push({id,kind:'image-composite',sources,targetPath:id+'.png',canvas:{width:64,height:72,background:'#00000000'},layers:sources.map((_,sourceIndex)=>({sourceIndex,x:0,y:0,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))});entries.push({id,weapon,support,form,bank,pivot:[32,38],draw_order:sources});
}
await writeFile(b+'manifest.json',JSON.stringify({status:'combined_art_review_not_gameplay',loadouts,entries},null,2));await writeFile(b+'request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-combined-loadouts',projectId:'hypersonic',purpose:'Review primary plus one support using retained independent layers in correct depth order',authority,tasks},null,2));
const boards=loadouts.map(([weapon,support])=>{const sources=entries.filter(e=>e.weapon===weapon&&e.support===support).map(e=>b+'composites/'+e.id+'.png');return {id:weapon+'_'+support,kind:'image-composite',sources,targetPath:weapon+'_'+support+'.png',canvas:{width:640,height:288,background:'#15212b'},layers:sources.map((_,i)=>({sourceIndex:i,x:i%5*128,y:Math.floor(i/5)*144,width:128,height:144,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))};});
await writeFile(b+'board_request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-combined-board',projectId:'hypersonic',purpose:'Five valid one-primary/one-support loadouts, both forms, five banks',authority,tasks:boards},null,2));
