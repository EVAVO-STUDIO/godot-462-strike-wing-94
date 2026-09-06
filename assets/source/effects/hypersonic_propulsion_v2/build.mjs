import {readFile,writeFile,mkdir,copyFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {constants} from 'node:fs';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const base='assets/source/effects/hypersonic_propulsion_v2';
await mkdir(base+'/originals',{recursive:true});await mkdir(base+'/cels',{recursive:true});
await writeFile(base+'/.gdignore','');
for(const f of ['afterburner','hypersonic_ignition','sonic_boom'])for(let i=0;i<4;i++)await copyFile(`assets/runtime/effects/persistent/${f}/${i}.png`,`${base}/originals/${f}_${i}.png`,constants.COPYFILE_EXCL).catch(e=>{if(e.code!=="EEXIST")throw e;});
const hash=b=>createHash('sha256').update(b).digest('hex');
const files=[];
async function cel(name,w,h,body){
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" shape-rendering="crispEdges">${body}</svg>`;
 await writeFile(`${base}/${name}.svg`,svg);
 const r=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png'});
 await writeFile(`${base}/cels/${name}.png`,r.buffer);
 await writeFile(`${base}/${name}.receipt.json`,JSON.stringify(r.evidence,null,2));
 files.push({source:name+'.svg',sourceSha256:hash(svg),target:name+'.png',sha256:hash(r.buffer),width:w,height:h});
}
const rect=(x,y,w,h,c,a=1)=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${c}" opacity="${a}"/>`;
for(let i=0;i<4;i++){
 let b='';const tail=[28,30,29,27][i];
 b+=rect(5,3,6,7,'#34659c',.6)+rect(6,4,4,tail-4,'#3c91d0',.62);
 b+=rect(5,10+i%2,6,3,'#559fdb',.45)+rect(6,18-i%2,4,4,'#75c7f1',.58);
 b+=rect(7,4,2,tail-7,'#92d9fa',.86)+rect(6,3,4,6,'#d9f3ff');
 b+=rect(7,3,2,8,'#f2fbff')+rect(7,14+i%2,2,3,'#e6f8ff');
 b+=rect(7,23-i%2,2,2,'#c4edff',.75)+rect(i%2?7:8,tail-2,1,3,'#5b99be',.42);
 await cel(`blue_plume_${i}`,16,40,b);
}
for(let i=0;i<6;i++){
 let b='';let r=[5,10,17,25,34,43][i];let alpha=[.95,.9,.8,.66,.45,.22][i];
 for(const side of [-1,1]){
  const origin=48+(side<0?-6:5);
  if(i<2)b+=rect(origin-2,5,4,9,'#e0f6ff',1-i*.25);
  for(let j=0;j<6;j++){
   const theta=.10+j*.235;const x=origin+side*r*Math.cos(theta);const y=8+r*.48*Math.sin(theta);
   b+=rect(Math.round(x)-1,Math.round(y),j<3?3:2,1,i<3?'#b7e0ed':'#739fad',alpha);
   if(j%2===0)b+=rect(Math.round(x)-2,Math.round(y)+2,2,1,'#426678',alpha*.6);
  }
 }
 await cel(`engine_burst_${i}`,112,40,b);
}
await writeFile(base+'/manifest.json',JSON.stringify({status:'art_candidate_pending_native_review',source:'Original authored cels finished with EVAVO Art Studio',plumeAnchor:[8,4],burstAnchor:[48,8],engineOffsets:[[-6,30],[5,30]],plumeFps:16,burstDurationsMs:[35,45,55,65,75,85],files},null,2));
console.log('10 propulsion cels finished; original runtime effects preserved.');
