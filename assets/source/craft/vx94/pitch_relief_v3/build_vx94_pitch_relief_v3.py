import bpy,math,json,sys
from pathlib import Path
from mathutils import Euler
form=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'fighter'
assert form in ['fighter','bomber']
repo=Path('C:/Gitrepos/godot-462-strike-wing-94');out=repo/'work/vx94_pitch_relief_v3'/form;out.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1;scene.cycles.pixel_filter_type='BOX';scene.cycles.filter_width=0.01;scene.cycles.use_denoising=False
scene.render.resolution_x=256;scene.render.resolution_y=288;scene.render.resolution_percentage=100
scene.render.film_transparent=True;scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.image_settings.color_depth='8'
scene.view_settings.view_transform='Standard';scene.view_settings.look='None';scene.view_settings.exposure=0;scene.view_settings.gamma=1;scene.render.dither_intensity=0
image=bpy.data.images.load(str(repo/f'assets/runtime/craft/vx94/gameplay/bank/{form}_neutral.png'));image.pack();pixels=list(image.pixels)
def rgba(x,y):
 if not(0<=x<64 and 0<=y<72):return (0,0,0,0)
 i=((71-y)*64+x)*4;return pixels[i:i+4]
top=bpy.data.materials.new('Retained VX94 painting');top.use_nodes=True
n=top.node_tree.nodes;n.clear();links=top.node_tree.links
tex=n.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Closest';tex.extension='CLIP'
em=n.new('ShaderNodeEmission');tr=n.new('ShaderNodeBsdfTransparent');mix=n.new('ShaderNodeMixShader');output=n.new('ShaderNodeOutputMaterial')
links.new(tex.outputs['Color'],em.inputs['Color']);links.new(tex.outputs['Alpha'],mix.inputs[0]);links.new(tr.outputs[0],mix.inputs[1]);links.new(em.outputs[0],mix.inputs[2]);links.new(mix.outputs[0],output.inputs['Surface'])
side=bpy.data.materials.new('Restrained dark composite edge');side.use_nodes=True;n=side.node_tree.nodes;n.clear();em=n.new('ShaderNodeEmission');em.inputs['Color'].default_value=(.015,.025,.035,1);output=n.new('ShaderNodeOutputMaterial');side.node_tree.links.new(em.outputs[0],output.inputs['Surface'])
def height(x,y):
 fuselage=math.exp(-((x-32)/3.8)**2)*(1.4+1.3*math.sin(math.pi*max(0,min(1,(y-4)/67))))
 canopy=1.5*math.exp(-((x-32)/2.8)**2-((y-20)/9)**2)
 engines=1.4*(math.exp(-((x-27)/2.7)**2)+math.exp(-((x-37)/2.7)**2))*math.exp(-((y-54)/13)**2)
 return .45+fuselage+canopy+engines
verts=[];faces=[];uvs=[];mats=[]
def face(points,uv,material):
 first=len(verts);verts.extend(points);faces.append(tuple(range(first,first+4)));uvs.append(uv);mats.append(material)
for y in range(72):
 for x in range(64):
  if rgba(x,y)[3]<=0:continue
  coords=[(x,y),(x+1,y),(x+1,y+1),(x,y+1)]
  points=[(xx-32,38-yy,height(xx,yy))for xx,yy in coords]
  face(points,[(xx/64,1-yy/72)for xx,yy in coords],0)
  if rgba(x,y)[3]<.5:continue
  for a,b,dx,dy in [(0,1,0,-1),(1,2,1,0),(2,3,0,1),(3,0,-1,0)]:
   if rgba(x+dx,y+dy)[3]>=.5:continue
   pa,pb=points[a],points[b];face([pa,pb,(pb[0],pb[1],-.6),(pa[0],pa[1],-.6)],[(0,0)]*4,1)
mesh=bpy.data.meshes.new('Pixel-registered airframe relief');mesh.from_pydata(verts,[],faces);mesh.materials.append(top);mesh.materials.append(side)
uv=mesh.uv_layers.new(name='Retained source UV')
for poly,coords,mat in zip(mesh.polygons,uvs,mats):
 poly.material_index=mat
 for i,co in zip(poly.loop_indices,coords):uv.data[i].uv=co
craft=bpy.data.objects.new('VX94 fighter relief pitch study',mesh);bpy.context.collection.objects.link(craft)
camera_data=bpy.data.cameras.new('Registered orthographic camera');camera=bpy.data.objects.new('Camera',camera_data);bpy.context.collection.objects.link(camera);camera.location=(0,2,200);camera_data.type='ORTHO';camera_data.ortho_scale=72;scene.camera=camera
bpy.ops.wm.save_as_mainfile(filepath=str(out/'vx94_relief.blend'))
for name,angle in [('dive_18',-18),('dive_12',-12),('dive_06',-6),('neutral',0),('climb_06',6),('climb_12',12),('climb_18',18)]:
 craft.rotation_euler=Euler((math.radians(angle),0,0),'XYZ');scene.render.filepath=str(out/(name+'_4x.png'));bpy.ops.render.render(write_still=True)
(out/'manifest.json').write_text(json.dumps({'status':'shallow_relief_art_study_not_final_aircraft_model','source':f'assets/runtime/craft/vx94/gameplay/bank/{form}_neutral.png','pivot':[32,38],'render_size':[256,288],'native_size':[64,72],'faces':len(faces),'angles':{'dive_18':-18,'dive_12':-12,'dive_06':-6,'neutral':0,'climb_06':6,'climb_12':12,'climb_18':18},'scope':'Retained source UV with authored shallow fuselage/canopy/engine height and boundary edge faces. Neutral registration must be verified before accepting any pitched output.'},indent=2)+'\n')
print('VX94_PITCH_RELIEF: seven rendered views')
