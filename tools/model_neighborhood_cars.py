"""Original modeled street cars, Blender 4.3+. No downloaded vehicle meshes.
blender -b -t 4 --python-exit-code 1 --python tools/model_neighborhood_cars.py -- /path/to/project
"""
import bpy, math, sys, json
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(sys.argv[sys.argv.index('--')+1]); OUT=ROOT/'assets/models/environment';OUT.mkdir(parents=True,exist_ok=True)
SOURCE=ROOT/'tools/vehicle_sources';SOURCE.mkdir(parents=True,exist_ok=True);(SOURCE/'.gdignore').write_text('')
def material(name,color,metal=0,rough=.5,coat=0,alpha=1):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,alpha)
    s=m.node_tree.nodes.get('Principled BSDF');s.inputs['Base Color'].default_value=(*color,alpha)
    s.inputs['Metallic'].default_value=metal;s.inputs['Roughness'].default_value=rough;s.inputs['Coat Weight'].default_value=coat;s.inputs['Coat Roughness'].default_value=.18;s.inputs['Alpha'].default_value=alpha
    return m
def mesh(name,verts,faces,mat):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update();obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);obj.data.materials.append(mat)
    for p in data.polygons:p.use_smooth=True
    import bmesh
    bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(data);bm.free()
    return obj
def apply(obj,modifier):
    bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=modifier.name)
def bevel(obj,width=.025,segments=3):
    b=obj.modifiers.new('Rounded manufactured edges','BEVEL');b.width=width;b.segments=segments;apply(obj,b)
    if hasattr(obj.data,'set_sharp_from_angle'):obj.data.set_sharp_from_angle(angle=.70)
    return obj
def box(name,at,size,mat,rounding=.015):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
    if rounding:bevel(o,min(rounding,min(size)*.35),3)
    return o
def line(name,points,radius,mat):
    curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.bevel_depth=radius;curve.bevel_resolution=2
    spline=curve.splines.new('POLY');spline.points.add(len(points)-1)
    for p,co in zip(spline.points,points):p.co=(*co,1)
    obj=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(obj);obj.data.materials.append(mat);return obj
def cylinder(name,at,radius,depth,mat,axis='Y',vertices=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=at)
    o=bpy.context.object;o.name=name
    if axis=='Y':o.rotation_euler.x=math.pi/2
    elif axis=='X':o.rotation_euler.y=math.pi/2
    o.data.materials.append(mat);bevel(o,min(.008,depth*.20),2);return o
def plate(name,x,z,words,sign,trim,dark):
    box(name+' plate',(x,0,z),(.025,.41,.12),trim,.008)
    bpy.ops.object.text_add(location=(x+sign*.015,0,z-.025));o=bpy.context.object;o.name=name+' fictional registration';o.data.body=words;o.data.size=.061;o.data.align_x='CENTER';o.data.extrude=.0004
    right=Vector((0,sign,0));up=Vector((0,0,1));normal=Vector((sign,0,0));o.rotation_euler=Matrix((right,up,normal)).transposed().to_euler();o.data.materials.append(dark)
def grid_glass(name,bottom_x,top_x,bottom_z,top_z,width,top_width,mat):
    verts=[];faces=[]
    for row in range(7):
        t=row/6;x=bottom_x+(top_x-bottom_x)*t;z=bottom_z+(top_z-bottom_z)*t;w=width+(top_width-width)*t
        for col in range(13):
            u=col/12*2-1;verts.append((x+.025*(1-u*u),u*w,z+.012*(1-u*u)))
    for row in range(6):
        for col in range(12):
            a=row*13+col;faces.append((a,a+1,a+14,a+13))
    return mesh(name,verts,faces,mat)
def make_car(kind):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    hatch=kind=='hatchback';half=1.88 if hatch else 2.08;wheelbase=1.18 if hatch else 1.29
    paint=material('Paint_Silver' if hatch else 'Paint_Charcoal',(.40,.45,.47) if hatch else (.085,.11,.12),.62,.27,.65)
    rubber=material('Rubber_Tires',(.018,.021,.022),0,.92);trim=material('Window_Rubber',(.025,.032,.034),.10,.65)
    chrome=material('Alloy_and_Chrome',(.45,.49,.51),.86,.22);dark=material('Panel_Seams',(.018,.024,.026),.12,.65)
    glass=material('Glass_Tinted',(.11,.16,.18),.08,.16,.4,.63);cloth=material('Interior_Fabric',(.085,.09,.086),0,.95)
    lens=material('Headlight_Reflectors',(.64,.68,.65),.34,.19,.3);red=material('Rear_Red_Lenses',(.40,.018,.017),.15,.24,.5);amber=material('Indicator_Lenses',(.56,.19,.02),.10,.24,.4)
    # Closed lower body, with actual circular wheel-well cutouts.
    xs=[-half,-half+.07,-half+.23,-1.43,-1.05,-.60,0,.55,1.0,1.43,half-.23,half-.07,half]
    verts=[];faces=[]
    for x in xs:
        end=abs(x)/half;w=.835-.10*end**5;top=.95-.20*end**4
        if hatch and x< -1.4:top=.89
        ring=[(-w*.88,.335),(-w,.44),(-w,.71),(-w*.99,top-.05),(-w*.86,top),(0,top+.025),(w*.86,top),(w*.99,top-.05),(w,.71),(w,.44),(w*.88,.335),(0,.31)]
        verts.extend((x,y,z) for y,z in ring)
    for row in range(len(xs)-1):
        for j in range(12):a=row*12+j;b=row*12+(j+1)%12;faces.append((a,b,b+12,a+12))
    faces.extend([tuple(reversed(range(12))),tuple(range((len(xs)-1)*12,len(xs)*12))])
    body=mesh('Body_Sculpted',verts,faces,paint);bevel(body,.034,3)
    for x in [-wheelbase,wheelbase]:
        for side in [-1,1]:
            bpy.ops.mesh.primitive_cylinder_add(vertices=40,radius=.366,depth=.72,location=(x,side*.90,.345),rotation=(math.pi/2,0,0));cut=bpy.context.object
            mod=body.modifiers.new('Real wheel arch','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cut;apply(body,mod);bpy.data.objects.remove(cut,do_unlink=True)
    bevel(body,.008,2)
    # Curved roof and four framed side windows, different rooflines for the two cars.
    rear_low=-1.65 if hatch else -1.22;rear_top=-1.00 if hatch else -.77;front_low=.90;front_top=.43
    roof_z=1.48 if hatch else 1.44
    verts=[];faces=[]
    for row in range(9):
        t=row/8;x=rear_top+(front_top-rear_top)*t
        for col in range(13):
            u=col/12*2-1;w=.63-.025*abs(t-.5)*2;verts.append((x,u*w,roof_z+.055*(1-u*u)+.018*math.sin(t*math.pi)))
    for row in range(8):
        for col in range(12):a=row*13+col;faces.append((a,a+1,a+14,a+13))
    roof=mesh('Roof_Curved',verts,faces,paint);solid=roof.modifiers.new('Roof thickness','SOLIDIFY');solid.thickness=.025;apply(roof,solid)
    grid_glass('Glass_Front',front_low,front_top,.975,roof_z,.737,.605,glass)
    grid_glass('Glass_Rear',rear_low,rear_top,.97,roof_z,.733,.605,glass)
    for side in [-1,1]:
        low=side*.775;high=side*.625
        a=(rear_low,low,.975);b=(front_low,low,.975);c=(front_top,high,roof_z);d=(rear_top,high,roof_z)
        divide=-.22
        for left,right in [(rear_low+.06,divide-.035),(divide+.035,front_low-.055)]:
            tl=rear_top+.04 if left<-.5 else divide+.035;tr=divide-.035 if right<0 else front_top-.035
            mesh('Glass_Side',[(left,low,.995),(right,low,.995),(tr,high,roof_z-.035),(tl,high,roof_z-.035)],[(0,1,2,3)],glass)
        line('Painted cabin frame',[a,b,c,d,a],.029,paint)
        line('Window weather seal',[(rear_low+.02,low*1.003,1.005),(front_low-.02,low*1.003,1.005),(front_top-.025,high*1.005,roof_z-.025),(rear_top+.025,high*1.005,roof_z-.025),(rear_low+.02,low*1.003,1.005)],.012,trim)
        line('B pillar',[(divide,low,.97),(divide,high,roof_z)],.027,trim)
        line('Body belt chrome',[(rear_low-.04,side*.832,.91),(front_low+.03,side*.832,.91)],.009,chrome)
        # Recessed door outlines and separate handles.
        for start,end in [(rear_low+.13,-.21),(-.18,.86)]:
            line('Door panel gap',[(start,side*.836,.91),(start+.05,side*.839,.49),(end-.03,side*.839,.49),(end,side*.836,.91)],.0035,dark)
            box('Door handle',(start+.20,side*.85,.86),(.16,.035,.037),chrome,.012)
        mirror=box('Door mirror',(.64,side*.925,1.04),(.20,.14,.12),paint,.035)
        box('Mirror glass',(.565,side*.93,1.045),(.012,.11,.078),chrome,.004)
        line('Lower rocker trim',[(-.72,side*.842,.395),(.72,side*.842,.395)],.018,trim)
    # Hood seams and windshield wipers follow the glass surface.
    for side in [-1,1]:
        line('Hood shut line',[(.98,side*.66,.976),(half-.20,side*.62,.80)],.003,dark)
        line('Wiper arm',[(.94,side*.28,.99),(.75,side*.12,1.19)],.008,trim)
        line('Wiper blade',[(.77,side*.12-.15,1.18),(.77,side*.12+.15,1.18)],.010,trim)
    # Bumpers, grilles, headlight units and lens ribs.
    for sign in [-1,1]:
        box('Bumper',(sign*(half+.015),0,.45),(.14,1.55,.14),trim,.05)
        box('Bumper chrome',(sign*(half+.09),0,.49),(.018,1.46,.026),chrome,.005)
    box('Front grille',(half+.015,0,.685),(.025,.66,.17),dark,.012)
    for row in range(5):box('Grille slat',(half+.035,0,.62+row*.031),(.025,.62,.009),chrome,.002)
    for side in [-1,1]:
        box('Headlight black surround',(half-.012,side*.535,.718),(.055,.43,.215),trim,.025)
        box('Headlight lens',(half+.024,side*.52,.72),(.04,.34,.17),lens,.022)
        for rib in range(8):box('Headlight lens ribs',(half+.048,side*.52-.145+rib*.041,.72),(.008,.006,.145),chrome,.001)
        box('Amber indicator',(half+.018,side*.755,.71),(.045,.095,.16),amber,.016)
        box('Tail lens',(-half-.014,side*.53,.73),(.04,.43,.16),red,.025)
        box('Tail reverse lens',(-half-.038,side*.42,.73),(.008,.09,.11),lens,.006)
    plate('Front',half+.10,.48,'JAV 0707',1,lens,dark);plate('Rear',-half-.10,.57,'JAV 0707',-1,lens,dark)
    # Tires have round shoulders, alloy rim recesses, spokes, bolts and tread blocks.
    for x in [-wheelbase,wheelbase]:
        for side in [-1,1]:
            y=side*.79
            bpy.ops.mesh.primitive_torus_add(major_segments=40,minor_segments=12,location=(x,y,.335),major_radius=.252,minor_radius=.078,rotation=(math.pi/2,0,0));o=bpy.context.object;o.name='Tire_Rounded';o.data.materials.append(rubber)
            for p in o.data.polygons:p.use_smooth=True
            cylinder('Rim inset',(x,side*.868,.335),.205,.026,trim)
            cylinder('Alloy dish',(x,side*.884,.335),.18,.020,chrome)
            cylinder('Hub cap',(x,side*.903,.335),.053,.018,chrome)
            for j in range(5):
                angle=j*math.tau/5
                spoke=box('Alloy spoke',(x+math.sin(angle)*.105,side*.905,.335+math.cos(angle)*.105),(.035,.023,.15),chrome,.010);spoke.rotation_euler.y=angle
                cylinder('Wheel bolt',(x+math.sin(angle)*.039,side*.917,.335+math.cos(angle)*.039),.008,.012,dark,vertices=12)
            for j in range(32):
                angle=j*math.tau/32
                tread=box('Tread',(x+math.sin(angle)*.326,y,.335+math.cos(angle)*.326),(.014,.128,.009),rubber,.002);tread.rotation_euler.y=angle
    # Interior can be seen through the tinted glazing.
    box('Cabin floor',(-.25,0,.77),(1.65,1.40,.06),trim,.015)
    box('Dashboard',(.66,0,.99),(.28,1.32,.16),trim,.045)
    for side in [-1,1]:
        box('Front seat cushion',(-.22,side*.36,.86),(.50,.48,.17),cloth,.07)
        seat=box('Front seat back',(-.50,side*.36,1.08),(.15,.47,.47),cloth,.065);seat.rotation_euler.y=-.12
        box('Headrest',(-.51,side*.36,1.34),(.12,.26,.14),cloth,.04)
    box('Rear bench',(-.98,0,.87),(.37,1.22,.16),cloth,.05);box('Rear backrest',(-1.17,0,1.06),(.10,1.2,.34),cloth,.04)
    bpy.ops.mesh.primitive_torus_add(major_segments=24,minor_segments=8,major_radius=.125,minor_radius=.012,location=(.34,-.37,1.11),rotation=(0,math.pi/2-.45,0));bpy.context.object.name='Steering wheel';bpy.context.object.data.materials.append(trim)
    cylinder('Exhaust',(-half-.035,.52,.30),.028,.15,chrome,axis='X',vertices=16)
    # Convert and combine by material to keep a small, predictable draw-call count.
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.convert(target='MESH');bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    groups={}
    for obj in list(bpy.context.scene.objects):
        if obj.type=='MESH':groups.setdefault(obj.data.materials[0].name,[]).append(obj)
    for name,objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();objects[0].name=name
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(kind+'.blend')),compress=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(kind+'.glb')),export_format='GLB',export_apply=True,export_yup=True,export_cameras=False,export_lights=False)
    tris=0
    for o in bpy.context.scene.objects:
        if o.type=='MESH':o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles)
    return {'kind':kind,'triangles':tris,'material_groups':len(groups),'length_m':(half+.11)*2,'width_m':1.99,'height_m':1.55}
report=[make_car(kind) for kind in ['sedan','hatchback']]
(ROOT/'docs/vehicle_report.json').write_text(json.dumps(report,indent=2))
print('VEHICLE_REPORT',json.dumps(report))
