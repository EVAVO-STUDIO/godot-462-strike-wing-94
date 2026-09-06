import {writeFile,mkdir,copyFile} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const b='work/mission_intel_icons_v2/';await mkdir(b+'icons',{recursive:true});await mkdir(b+'originals',{recursive:true});
const icons={
 threat:['#dc6655','<path d="M8 2l6 11H2z" fill="none" stroke="C"/><path d="M7 6h2v4H7zM7 11h2v1H7z" fill="C"/>'],
 envelope:['#6aa4c8','<path d="M4 2H2v12h2M12 2h2v12h-2" fill="none" stroke="C"/><path d="M7 3h2v4l3 3v1H9v2H7v-2H4v-1l3-3z" fill="C"/>'],
 profile:['#6aa4c8','<path d="M2 3v10h12" fill="none" stroke="#526772"/><path d="M3 11h3V8h4V4h3" fill="none" stroke="C"/><path d="M11 3h3v3" fill="none" stroke="C"/>'],
 lanes:['#6aa4c8','<path d="M2 3h8M2 8h8M2 13h8" stroke="#526772"/><path d="M3 7h6v2H3z" fill="C"/><path d="M12 3v10M10 5l2-2 2 2M10 11l2 2 2-2" fill="none" stroke="C"/>'],
 routes:['#6aa4c8','<path d="M8 14V9L3 4M8 9l5-5M2 7V3h4M10 3h4v4" fill="none" stroke="C"/><path d="M7 12h2v2H7z" fill="#bdc9c8"/>'],
 boss:['#dc6655','<path d="M2 5V2h3M11 2h3v3M2 11v3h3M11 14h3v-3" fill="none" stroke="C"/><path d="M7 4h2v3l3 3v1H9v1H7v-1H4v-1l3-3z" fill="C"/>'],
 allied:['#67c3a5','<path d="M7 2h2v3l2 2H9v2H7V7H5l2-2zM3 8h1v2l2 2H4v2H3v-2H1l2-2zM12 8h1v2l2 2h-2v2h-1v-2h-2l2-2z" fill="C"/>'],
 advice:['#e8ca6a','<path d="M4 3H2v11h12V3h-2M6 2h4v3H6z" fill="none" stroke="C"/><path d="M5 9l2 2 4-4" fill="none" stroke="C"/>']};
for(const [name,[colour,paths]]of Object.entries(icons)){
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" shape-rendering="crispEdges">${paths.replaceAll('C',colour)}</svg>`;await writeFile(b+'icons/icon_'+name+'.svg',svg);const r=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png'});await writeFile(b+'icons/icon_'+name+'.png',r.buffer);await copyFile('assets/runtime/ui/menu/mission_intel/icon_'+name+'.png',b+'originals/icon_'+name+'.png');
}
const authority={candidatePromotion:false,publication:false,targetRepositoryMutation:false,candidateApproval:false,providerExecution:false},sources=['originals','icons'].flatMap(d=>Object.keys(icons).map(n=>b+d+'/icon_'+n+'.png'));
await writeFile(b+'board_request.json',JSON.stringify({schema:'evavo.project-art-sandbox-request.v1',sandboxId:'intel-icons-review',projectId:'hypersonic',purpose:'Original then revised intelligence symbols, 4x native',authority,tasks:[{id:'icons',kind:'image-composite',sources,targetPath:'icons.png',canvas:{width:512,height:128,background:'#111e27'},layers:sources.map((_,i)=>({sourceIndex:i,x:i%8*64,y:Math.floor(i/8)*64,width:64,height:64,sourceRect:{x:0,y:0,width:16,height:16},sampling:'nearest'}))}]},null,2));
