import {writeFile} from 'node:fs/promises';
const root='C:/Gitrepos/godot-462-strike-wing-94/',base='work/vx94_pitch_relief_v3/';
const angles=['dive_18','dive_12','dive_06','neutral','climb_06','climb_12','climb_18'];
const tasks=['fighter','bomber'].flatMap(form=>angles.map(pose=>({id:form+'_'+pose,kind:'image-composite',sources:[base+form+'/'+pose+'_4x.png'],targetPath:form+'_'+pose+'.png',canvas:{width:64,height:72,background:'#00000000'},layers:[{sourceIndex:0,x:0,y:0,width:64,height:72,sourceRect:{x:0,y:0,width:256,height:288},sampling:'nearest'}]})));
const authority={candidatePromotion:false,publication:false,targetRepositoryMutation:false,candidateApproval:false,providerExecution:false};
await writeFile(root+base+'native_request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'hypersonic-pitch-relief-native',projectId:'hypersonic',purpose:'Native nearest-sampled export of fourteen source-textured 3D pitch views',authority,tasks},null,2));
const sources=['fighter','bomber'].flatMap(form=>angles.map(p=>base+'native/'+form+'_'+p+'.png'));
const board={id:'pitch_family',kind:'image-composite',sources,targetPath:'pitch_family.png',canvas:{width:896,height:288,background:'#15212b'},layers:sources.map((_,i)=>({sourceIndex:i,x:i%7*128,y:Math.floor(i/7)*144,width:128,height:144,sourceRect:{x:0,y:0,width:64,height:72},sampling:'nearest'}))};
await writeFile(root+base+'board_request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'hypersonic-pitch-relief-board',projectId:'hypersonic',purpose:'Diving 18/12/6, neutral, climbing 6/12/18 degrees; fighter then bomber',authority,tasks:[board]},null,2));
