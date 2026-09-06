import {readFile,writeFile,mkdir} from 'node:fs/promises';
const b='work/vx94_transform_primary_v1/';await mkdir(b,{recursive:true});
const ballistic=JSON.parse(await readFile('work/vx94_banked_housings/request.json','utf8')).tasks,special=JSON.parse(await readFile('work/vx94_specialist_housings_v2/request.json','utf8')).tasks;
const authority={candidatePromotion:false,publication:false,targetRepositoryMutation:false,candidateApproval:false,providerExecution:false};
const entries=[],tasks=[];
for(const route of ['bomber','hypersonic'])for(const weapon of ['ballistic','needle_rail','storm_cannon','plasma_lance'])for(let i=0;i<10;i++){
 const form=route==='bomber'&&i>=4?'bomber':'fighter';
 const exposure=weapon==='ballistic'?(route==='bomber'?[3,2,1,0,0,0,1,2,3,3][i]:[3,2,1,0,0,0,0,0,0,0][i]):(route==='bomber'?[1,1,0,0,0,0,0,1,1,1][i]:[1,1,0,0,0,0,0,0,0,0][i]);
 const task=weapon==='ballistic'?ballistic.find(t=>t.id===`${form}_neutral_${exposure}`):special.find(t=>t.id===`${weapon}_${form}_neutral_${exposure}`);
 if(!task)throw Error('Missing primary source');const oldBody=`assets/runtime/craft/vx94/gameplay/bank/${form}_neutral.png`,body=`assets/runtime/craft/vx94/transform/${route}_${String(i).padStart(2,'0')}.png`,id=`${route}_${weapon}_${String(i).padStart(2,'0')}`;
 const sources=task.sources.map(s=>s===oldBody?body:s);tasks.push({...task,id,sources,targetPath:id+'.png'});entries.push({id,route,weapon,exposure:i,hardware_form:form,hardware_exposure:exposure,pivot:[32,38],sources});
}
await writeFile(b+'manifest.json',JSON.stringify({status:'primary_transform_art_candidate',entries},null,2));await writeFile(b+'request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-primary-transform',projectId:'hypersonic',purpose:'Retained primary retraction and deployment synchronized with authored wing exposures',authority,tasks},null,2));
const boards=['bomber','hypersonic'].map(route=>{const sources=entries.filter(e=>e.route===route).map(e=>b+'composites/'+e.id+'.png');return {id:route,kind:'image-composite',sources,targetPath:route+'.png',canvas:{width:1280,height:576,background:'#15212b'},layers:sources.map((_,i)=>({sourceIndex:i,x:i%10*128,y:Math.floor(i/10)*144,width:128,height:144,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))};});
await writeFile(b+'board_request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'vx94-primary-transform-board',projectId:'hypersonic',purpose:'Ten exposures; ballistic, rail, Storm and plasma rows',authority,tasks:boards},null,2));
