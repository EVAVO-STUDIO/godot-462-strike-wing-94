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
 let b='';let r=[7,16,27,39,51,62][i];let alpha=[.98,.92,.82,.66,.43,.20][i];
 for(const side of [-1,1]){
  const origin=72+(side<0?-6:5);
  if(i<2)b+=rect(origin-3,7,6,11,'#e9f9ff',1-i*.22)+rect(origin-5,11,10,5,'#8fd4ed',.62-i*.12);
  for(let j=0;j<9;j++){
   const theta=-.12+j*.205;const x=origin+side*r*Math.cos(theta);const y=13+r*.48*Math.sin(theta);
   const width=j<4?4:3;
   b+=rect(Math.round(x)-2,Math.round(y),width,2,i<3?'#c8eaf2':'#789fac',alpha);
   if(j%2===0)b+=rect(Math.round(x)-3,Math.round(y)+3,3,1,'#446b79',alpha*.55);
  }
 }
 if(i>=1&&i<=4){
  const bridge=[9,16,22,27][i-1], gap=5+i*2, y=16+i*2;
  b+=rect(72-bridge,y,bridge-gap,2,'#a9d6df',alpha*.42);
  b+=rect(72+gap,y+1,bridge-gap,1,'#a9d6df',alpha*.34);
 }
 await cel(`engine_burst_${i}`,144,72,b);
}
await writeFile(base+'/manifest.json',JSON.stringify({status:'runtime_integrated',source:'Original authored cels finished with EVAVO Art Studio',plumeAnchor:[8,4],burstAnchor:[72,13],engineOffsets:[[-6,30],[5,30]],plumeFps:16,burstDurationsMs:[35,45,55,65,75,85],files},null,2));
console.log('10 propulsion cels finished; original runtime effects preserved.');
