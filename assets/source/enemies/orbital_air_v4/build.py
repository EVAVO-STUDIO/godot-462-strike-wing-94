"""Build grounded BLACK SKY aerospace silhouettes and registered bank cels."""
from hashlib import sha256
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance

ROOT=Path(__file__).resolve().parents[4]; SOURCE=ROOT/"assets/source/enemies/orbital_air_v4"; RUNTIME=ROOT/"assets/runtime/enemies"
INK=(7,12,20,255); GRAPHITE=(28,37,49,255); COBALT=(33,53,70,255); CERAMIC=(157,166,166,255)
LIGHT=(202,205,195,255); COPPER=(169,94,47,255); CYAN=(76,193,220,255); WHITE=(226,246,241,255)
def poly(d,p,f): d.polygon(p,fill=f); d.line(p+[p[0]],fill=INK,width=1)
def core(d,x,y): d.rectangle((x-2,y-2,x+2,y+2),fill=GRAPHITE); d.rectangle((x-1,y-1,x+1,y+1),fill=CYAN); d.point((x,y-1),fill=WHITE)
def exo():
 im=Image.new('RGBA',(30,30),(0,0,0,0));d=ImageDraw.Draw(im);poly(d,[(2,17),(8,9),(12,8),(15,2),(18,8),(22,9),(28,17),(21,18),(18,16),(18,23),(15,28),(12,23),(12,16),(9,18)],COBALT);poly(d,[(4,16),(10,10),(13,10),(11,17)],GRAPHITE);poly(d,[(26,16),(20,10),(17,10),(19,17)],CERAMIC);poly(d,[(13,8),(15,2),(17,8),(17,22),(15,27),(13,22)],LIGHT);core(d,15,14);d.point((8,18),fill=COPPER);d.point((22,18),fill=COPPER);d.point((11,24),fill=CYAN);d.point((19,24),fill=CYAN);return im
def sentry():
 im=Image.new('RGBA',(40,38),(0,0,0,0));d=ImageDraw.Draw(im);poly(d,[(2,20),(9,12),(16,11),(20,3),(24,11),(31,12),(38,20),(32,24),(25,22),(24,31),(20,36),(16,31),(15,22),(8,24)],GRAPHITE);poly(d,[(4,19),(11,13),(17,13),(14,22),(8,23)],COBALT);poly(d,[(36,19),(29,13),(23,13),(26,22),(32,23)],CERAMIC);poly(d,[(17,10),(20,3),(23,10),(24,30),(20,36),(16,30)],LIGHT);core(d,20,19);d.rectangle((18,24,22,33),fill=GRAPHITE,outline=INK);d.point((20,34),fill=CYAN);return im
def phase():
 im=Image.new('RGBA',(34,34),(0,0,0,0));d=ImageDraw.Draw(im);poly(d,[(1,18),(8,11),(14,10),(17,2),(20,10),(26,11),(33,18),(27,20),(21,18),(20,27),(17,32),(14,27),(13,18),(7,20)],COBALT);poly(d,[(3,17),(9,12),(15,12),(12,18)],GRAPHITE);poly(d,[(31,17),(25,12),(19,12),(22,18)],CERAMIC);poly(d,[(15,8),(17,2),(19,8),(20,26),(17,32),(14,26)],LIGHT);core(d,17,16);d.rectangle((7,16,10,19),fill=CYAN,outline=INK);d.rectangle((24,16,27,19),fill=CYAN,outline=INK);d.point((12,28),fill=CYAN);d.point((22,28),fill=CYAN);return im
def beam():
 im=Image.new('RGBA',(42,40),(0,0,0,0));d=ImageDraw.Draw(im);poly(d,[(1,22),(5,11),(14,10),(21,3),(28,10),(37,11),(41,22),(35,26),(28,23),(26,33),(21,38),(16,33),(14,23),(7,26)],GRAPHITE);poly(d,[(2,21),(6,12),(15,12),(13,23),(7,24)],COBALT);poly(d,[(40,21),(36,12),(27,12),(29,23),(35,24)],CERAMIC);poly(d,[(17,9),(21,3),(25,9),(26,31),(21,38),(16,31)],LIGHT);d.rectangle((3,16,8,24),fill=COBALT,outline=INK);d.rectangle((34,16,39,24),fill=CERAMIC,outline=INK);core(d,21,19);d.ellipse((18,21,24,27),fill=GRAPHITE,outline=INK);d.rectangle((20,23,22,26),fill=CYAN);return im
def lancer():
 im=Image.new('RGBA',(48,58),(0,0,0,0));d=ImageDraw.Draw(im);poly(d,[(2,31),(8,18),(17,16),(24,3),(31,16),(40,18),(46,31),(38,35),(31,31),(29,46),(24,56),(19,46),(17,31),(10,35)],GRAPHITE);poly(d,[(4,29),(10,20),(18,18),(16,32),(9,33)],COBALT);poly(d,[(44,29),(38,20),(30,18),(32,32),(39,33)],CERAMIC);poly(d,[(20,12),(24,3),(28,12),(29,45),(24,56),(19,45)],LIGHT);d.rectangle((5,25,10,37),fill=COBALT,outline=INK);d.rectangle((38,25,43,37),fill=CERAMIC,outline=INK);core(d,24,27);d.rectangle((22,31,26,52),fill=GRAPHITE,outline=INK);d.line([(24,34),(24,53)],fill=CYAN);d.point((13,45),fill=CYAN);d.point((35,45),fill=CYAN);return im
def bank(level,left):
 width,height=level.size; scaled=level.resize((round(width*.80),height),Image.Resampling.NEAREST); out=Image.new('RGBA',level.size,(0,0,0,0)); x=(width-scaled.width)//2+(-2 if left else 2); out.alpha_composite(scaled,(x,0)); pix=out.load()
 for y in range(height):
  for xx in range(width):
   r,g,b,a=pix[xx,y]
   if not a: continue
   raised=(xx < width//2) if left else (xx > width//2)
   factor=1.16 if raised else .72; pix[xx,y]=(min(255,int(r*factor)),min(255,int(g*factor)),min(255,int(b*factor)),a)
 return out
families={'exo_drone':exo,'orbital_sentry':sentry,'phase_interceptor':phase,'beam_sentry':beam,'orbital_lancer':lancer};records=[]
for enemy_id,factory in families.items():
 level=factory()
 for pose,image in [('level',level),('left',bank(level,True)),('right',bank(level,False))]:
  runtime=RUNTIME/(f'orbital_air/{enemy_id}_idle.png' if pose=='level' else f'bank/{enemy_id}/{pose}.png');runtime.parent.mkdir(parents=True,exist_ok=True);image.save(runtime,optimize=True);source=SOURCE/f'{enemy_id}_{pose}.png';image.save(source,optimize=True);records.append({'id':enemy_id,'pose':pose,'runtime':runtime.relative_to(ROOT).as_posix(),'size':list(image.size),'visible_bounds':list(image.getbbox()),'sha256':sha256(runtime.read_bytes()).hexdigest().upper()})
(SOURCE/'manifest.json').write_text(json.dumps({'asset_family':'orbital_air_v4','status':'runtime_integrated','identity':'recognizable human-derived BLACK SKY upper-atmosphere military aerospace','visual_contract':['thermal ceramic and graphite structure','broad lifting and control surfaces','physically attached radiators, rails and apertures','localized cyan-white emission','coherent foreshortened bank cels','never alien or humanoid'],'collision_policy':'all existing gameplay radii and mount anchors remain authoritative','outputs':records},indent=2)+'\n',encoding='utf-8')
catalog_path=ROOT/'assets/source/enemies/orbital_air_asset_manifest.json';catalog=json.loads(catalog_path.read_text(encoding='utf-8'));catalog['status']='runtime_motion_v4';catalog['v4_override']='res://assets/source/enemies/orbital_air_v4/manifest.json'
for entry in catalog['runtime']:
 match=next(r for r in records if r['id']==entry['id'] and r['pose']=='level');entry['sha256']=match['sha256']
catalog_path.write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8');print('Built five orbital airframes and ten coherent bank cels.')
