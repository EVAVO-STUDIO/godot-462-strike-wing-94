import {mkdir,writeFile} from 'node:fs/promises';
import {compileRainFieldPlan,verifyRainFieldPlan,evaluateVerifiedRainField} from 'file:///C:/Gitrepos/atmosphere-studio/lib/render/rain-field.ts';
const out='C:/Gitrepos/godot-462-strike-wing-94/work/rain_flight_v4/';
await mkdir(out,{recursive:true});
const results={};
for(const [name,intensity,densityScale]of [['drizzle',.45,1.1],['rain',.72,1.8],['storm',.9,3]]){
 const request={schemaVersion:1,seed:9406,width:640,height:304,cycleSeconds:8,intensity,windX:.14,windY:.35,densityScale,shutterAngleDegrees:30,depthBands:['background','midground','foreground']};
 const plan=verifyRainFieldPlan(compileRainFieldPlan(request));
 const frames=Array.from({length:192},(_,i)=>evaluateVerifiedRainField(plan,i/24));
 const start=evaluateVerifiedRainField(plan,0),end=evaluateVerifiedRainField(plan,8);
 const loopExact=JSON.stringify(start)===JSON.stringify(end);
 if(!loopExact)throw Error('Rain field loop does not reproduce');
 await writeFile(out+name+'_plan.json',JSON.stringify(plan,null,2));
 await writeFile(out+name+'_states.json',JSON.stringify({fps:24,cycle:8,frames}));
 results[name]={particles:plan.particles.length,bands:plan.bandCounts,loopExact,checksum:plan.checksum};
}
await writeFile(out+'style.json',JSON.stringify({status:'art_fixture_not_production_weather',maxStreakPixels:{background:2,midground:4,foreground:8},widthPixels:1,colour:[.56,.65,.70],opacityScale:.78,tailOpacityScale:.4,travelParallaxPixelsPerWorldUnit:42,hudClipping:[0,34,640,304],note:'Retain verified Atmosphere plan. Limit drawn streak length for tracer separation; add integrated aircraft travel by particle depth without scaling rain time.'},null,2));
await writeFile(out+'verification.json',JSON.stringify(results,null,2));
console.log(JSON.stringify(results));
