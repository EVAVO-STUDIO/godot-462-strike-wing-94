import bpy
import math
from mathutils import Vector
from pathlib import Path

OUT = Path(__file__).resolve().parent / 'model_candidates_e'
OUT.mkdir(parents=True, exist_ok=True)

def material(name, color, metal=0.25, glow=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Metallic'].default_value = metal
    p.inputs['Roughness'].default_value = 0.6
    p.inputs['Emission Color'].default_value = (*color, 1)
    p.inputs['Emission Strength'].default_value = glow
    return m

def box(name, location, scale, mat, bevel=0.04):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    o = bpy.context.object
    o.name = name
    o.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(mat)
    if bevel:
        mod = o.modifiers.new('Machined edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 1
    return o

def plate(name, points, z, thickness, mat):
    n = len(points)
    vertices = [(x,y,z) for x,y in points] + [(x,y,z+thickness) for x,y in points]
    faces = [tuple(reversed(range(n))), tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    o = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(mat)
    return o

def tube(name, location, radius, length, mat, axis='X'):
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius, depth=length, location=location)
    o=bpy.context.object
    o.name=name
    o.rotation_euler[1 if axis=='X' else 0] = math.pi/2
    o.data.materials.append(mat)
    return o

def body(stations, mat):
    verts=[]
    for x, ry, rz, z in stations:
        verts += [(x,math.cos(i*math.tau/12)*ry,z+math.sin(i*math.tau/12)*rz) for i in range(12)]
    faces=[tuple(reversed(range(12))), tuple(range((len(stations)-1)*12,len(stations)*12))]
    for k in range(len(stations)-1):
        faces += [(k*12+i,k*12+(i+1)%12,(k+1)*12+(i+1)%12,(k+1)*12+i) for i in range(12)]
    mesh=bpy.data.meshes.new('Pressure hull')
    mesh.from_pydata(verts,[],faces)
    mesh.update()
    obj=bpy.data.objects.new('Pressure hull',mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)

for family, length, span, bulk in [('atlas_tanker',9.2,5.8,.56),('rapier_fighter',6.8,4.7,.32),('hammer_bomber',8.0,6.4,.48),('spectre_gunship',8.5,5.5,.62)]:
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    paint=material('Fleet graphite blue',(.18,.23,.25))
    upper=material('Upper composite',(.36,.42,.41))
    edge=material('Machined titanium',(.08,.11,.13),.7)
    recess=material('Intake and panel recess',(.045,.065,.074))
    glass=material('Armoured blue glass',(.07,.24,.30),.5)
    stripe=material('Muted identification ochre',(.55,.40,.15))
    red=material('Port identification lamp',(.62,.08,.035),.1,1)
    green=material('Starboard identification lamp',(.06,.37,.22),.1,1)
    heat=material('Warm engine throat',(.92,.30,.035),.3,1.2)
    L=length/2
    body([(-L,.035,.045,.1),(-L+.7,bulk*.7,bulk*.65,.14),(-L+1.5,bulk,bulk*.8,.13),(L-1.1,bulk*.85,bulk*.72,.1),(L,.12,.16,.1)],paint)
    # Swept load-bearing wings, separate control surfaces and root fairings.
    for side in [-1,1]:
        wing_root, wing_tip, wing_back = {
            'atlas_tanker':(-1.3,.55,1.45),
            'rapier_fighter':(-1.8,1.0,1.55),
            'hammer_bomber':(-2.4,.65,2.25),
            'spectre_gunship':(-.7,-.35,.85),
        }[family]
        points=[(wing_root,side*.25),(wing_tip,side*span/2),(wing_back,side*span/2),(2.0 if family=='hammer_bomber' else 1.2,side*.32)]
        plate('Port wing' if side<0 else 'Starboard wing',points,0,.12,upper)
        plate('Elevon',[(wing_back-.28,side*(span/2-.12)),(wing_back-.05,side*(span/2-.12)),(1.65 if family=='hammer_bomber' else 1.1,side*.65),(.88,side*.65)],.13,.025,paint)
        box('Wing root fairing',(.0,side*.55,.23),(2.1,.42,.23),paint)
        box('Wing recognition stripe',((wing_tip+wing_back)/2-.12,side*span*.36,.15),(.19,.54,.025),stripe,.005)
        plate('Tailplane',[(L-1.4,side*.15),(L-.65,side*1.22),(L-.1,side*1.22),(L-.35,side*.12)],.15,.10,paint)
        box('Navigation light',((wing_tip+wing_back)/2,side*(span/2),.18),(.16,.10,.085),red if side<0 else green,.015)
    # Canopy and discrete frames remain readable after reduction.
    canopy=box('Canopy',(-L+1.6,0,bulk*.7+.18),(.95,bulk*1.25,.28),glass,.13)
    for x in [-L+1.23,-L+1.64,-L+2.01]:
        box('Canopy frame',(x,0,bulk*.7+.33),(.07,bulk*1.28,.035),edge,.006)
    for x in [-.65,.0,.65,1.3]:
        box('Dorsal access panel',(x,0,bulk*.8+.12),(.48,bulk*.95,.045),upper,.025)
        for side in [-1,1]:
            box('Panel fastener',(x-.17,side*bulk*.34,bulk*.8+.15),(.035,.035,.022),edge,.002)
    # Twin pods on combat types; four smaller high-bypass pods on the tanker.
    engine_offsets=[-1.55,-.85,.85,1.55] if family=='atlas_tanker' else [-.87,.87]
    for y in engine_offsets:
        r=.22 if family=='atlas_tanker' else .28
        tube('Engine nacelle',(.75,y,.12),r,2.0,paint)
        tube('Intake lip',(-.29,y,.12),r*1.06,.16,edge)
        tube('Intake cavity',(-.38,y,.12),r*.8,.045,recess)
        tube('Exhaust collar',(1.8,y,.12),r*.86,.20,edge)
        tube('Exhaust throat',(1.92,y,.12),r*.60,.04,heat)
    # Vertical fin is real geometry, not a painted shape.
    fin=plate('Vertical stabilizer',[(L-1.25,0),(L-.25,0),(L-.50,1.10)],0,.12,paint)
    fin.rotation_euler[0]=math.pi/2
    fin.location.z=.2
    if family=='atlas_tanker':
        box('Fuel manifold',(.25,0,bulk+.05),(1.8,.46,.16),edge)
        box('Boom saddle',(L-.45,0,-.1),(.7,.25,.2),upper)
    elif family=='rapier_fighter':
        for side in [-1,1]:
            box('Cannon fairing',(-1.25,side*.42,.1),(1.2,.3,.24),paint)
            tube('Wing root cannon',(-1.95,side*.42,.1),.075,.8,edge)
            tube('Short range store',(.1,side*1.5,-.08),.10,1.05,upper)
    elif family=='hammer_bomber':
        for side in [-1,1]:
            for y in [1.35,2.05]:
                tube('Strike store',(.7,side*y,-.1),.17,1.3,edge)
        box('Dorsal mission spine',(.6,0,bulk+.08),(2.6,.25,.16),recess)
    else:
        for x in [-.4,.45,1.2]:
            box('Side cannon mount',(x,-.68,.05),(.40,.34,.32),edge)
            tube('Side cannon',(x,-1.16,.03),.075,.8,edge,'Y')
        box('Sensor blister',(-1.0,0,bulk+.18),(.6,.48,.3),edge,.15)
    scene=bpy.context.scene
    scene.render.engine='CYCLES'
    scene.cycles.samples=24
    native_w,native_h={'atlas_tanker':(112,64),'rapier_fighter':(48,28),'hammer_bomber':(64,36),'spectre_gunship':(96,56)}[family]
    scene.render.resolution_x=native_w*8
    scene.render.resolution_y=native_h*8
    scene.render.resolution_percentage=100
    scene.render.film_transparent=True
    scene.view_settings.view_transform='Standard'
    scene.world.color=(.18,.18,.18)
    bpy.ops.object.light_add(type='AREA',location=(-3,-4,8))
    bpy.context.object.data.energy=480
    bpy.context.object.data.shape='DISK'
    bpy.context.object.data.size=5
    bpy.ops.object.light_add(type='AREA',location=(2,4,5))
    bpy.context.object.data.energy=200
    bpy.context.object.data.size=4
    bpy.ops.object.camera_add(location=(0,-3,16))
    camera=bpy.context.object
    camera.rotation_euler=(Vector((0,0,0))-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO'
    camera.data.ortho_scale=max(length*native_w/(native_w-8), (span+.12)*native_w/(native_h-8))
    scene.camera=camera
    # Explicit camera roll keeps the nose left in the support interface.
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(family+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(family+'.glb')),export_format='GLB',export_cameras=False,export_lights=False)
    for exposure in range(4):
        heat.node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value=[.8,1.2,1.6,1.2][exposure]
        red.node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value=[.3,1.5,.3,.3][exposure]
        green.node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value=[.3,.3,.3,1.5][exposure]
        scene.render.filepath=str(OUT/(family+'_'+str(exposure)+'.png'))
        bpy.ops.render.render(write_still=True)
print('Four dimensional support-aircraft candidates retained; not runtime-approved.')
