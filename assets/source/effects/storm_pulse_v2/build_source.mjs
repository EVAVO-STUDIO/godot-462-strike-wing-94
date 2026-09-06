import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {finishRasterAsset} from 'file:///C:/Gitrepos/evavo-art-studio/packages/media/dist/index.js';
const out=new URL('./storm_candidate/',import.meta.url);
await mkdir(out,{recursive:true});
for(let i=0;i<4;i++){
 const sparks=[[[3,6],[11,10]],[[4,10],[11,5]],[[3,8],[11,7]],[[4,5],[10,11]]][i];
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="16" height="24" viewBox="0 0 16 24" shape-rendering="crispEdges">
 <path fill="#172b34" d="M7 2h2v2h2v2h2v4h-2v2H9v5H7v-5H5v-2H3V6h2V4h2z"/>
 <path fill="#426774" d="M7 3h2v2h2v2h1v2h-1v2H9v3H7v-3H5V9H4V7h1V5h2z"/>
 <path fill="#75b6c1" d="M7 4h2v2h2v3H9v3H7V9H5V6h2z"/>
 <path fill="#d7e9d8" d="M7 5h2v2h1v2H9v1H7V9H6V7h1z"/>
 <path fill="#fff1c1" d="M7 6h2v3H7z"/>
 <path fill="#68909a" d="M7 13h2v${i%2?2:3}H7z"/>
 ${sparks.map(([x,y])=>`<rect x="${x}" y="${y}" width="2" height="1" fill="#b9d5ce"/>`).join('')}
 </svg>`;
 await writeFile(new URL(`flight_${i}.svg`,out),svg);
 const result=await finishRasterAsset(Buffer.from(svg),{ensureAlpha:true,format:'png'});
 await writeFile(new URL(`flight_${i}.png`,out),result.buffer);
 await writeFile(new URL(`flight_${i}.receipt.json`,out),JSON.stringify(result.evidence,null,2));
}
