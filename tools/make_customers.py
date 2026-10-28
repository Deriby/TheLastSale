"""Three original modular low-poly local customers, sharing the humanoid rig/clips."""
import bpy,sys,math
from pathlib import Path
from mathutils import Vector
root=Path(sys.argv[sys.argv.index('--')+1])
for idx in [1,2,3]:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(root/'assets/models/characters/Dery.glb'))
 rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 for o in list(bpy.context.scene.objects):
  if o.type=='MESH':bpy.data.objects.remove(o,do_unlink=True)
 rig.name=f'Customer{idx}_Rig';parts=[]
 def mat(name,col):
  m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*col,1);b.inputs['Roughness'].default_value=.95;return m
 skin=mat('Pele',[(.48,.30,.20),(.72,.49,.33),(.61,.39,.26)][idx-1]);shirt=mat('Roupa',[(.22,.34,.34),(.43,.28,.15),(.42,.27,.34)][idx-1]);pants=mat('Calca',(.12,.16,.19));hair=mat('Cabelo',(.06,.045,.03) if idx<3 else (.34,.32,.28));black=mat('Olhos',(.025,.022,.018));white=mat('Olhos branco',(.65,.62,.53));shoe=mat('Sapatos',(.17,.15,.12))
 def bind(obj,bone,material):
  obj.data.materials.append(material);g=obj.vertex_groups.new(name=bone);g.add(list(range(len(obj.data.vertices))),1,'REPLACE');parts.append(obj)
 def box(pos,size,bone,material,bevel=0):
  bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
  if bevel:
   m=o.modifiers.new('Angular edges','BEVEL');m.width=bevel;m.segments=1;bpy.ops.object.modifier_apply(modifier=m.name)
  bind(o,bone,material);return o
 def ico(pos,scale,bone,material,sub=1):
  bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=pos);o=bpy.context.object;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);bind(o,bone,material);return o
 def limb(a,b,r,bone,material):
  a,b=Vector(a),Vector(b);bpy.ops.mesh.primitive_cone_add(vertices=6,radius1=r,radius2=r*.82,depth=(b-a).length,location=(a+b)/2);o=bpy.context.object;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();bind(o,bone,material)
 # Coordinates follow the inspected original T-pose proportions, in meters.
 box((0,0,1.13),(.41,.24,.43),'spine',shirt,.04)
 box((0,0,.85),(.35,.24,.23),'pelvis',pants,.025)
 limb((0,0,1.35),(0,0,1.50),.068,'neck',skin)
 ico((0,0,1.58),(.14,.12,.185),'head',skin,2)
 ico((0,.025,1.70),(.146,.125,.10),'head',hair,2)
 for s,sg in [('L',1),('R',-1)]:
  limb((sg*.13,0,1.34),(sg*.51,0,1.335),.09,'arm_'+s,shirt)
  limb((sg*.51,0,1.335),(sg*.70,0,1.325),.061,'forearm_'+s,skin)
  box((sg*.738,-.01,1.325),(.12,.09,.06),'hand_'+s,skin,.018)
  limb((sg*.145,0,.85),(sg*.185,0,.49),.115,'thigh_'+s,pants)
  limb((sg*.185,0,.49),(sg*.21,0,.13),.085,'shin_'+s,pants)
  box((sg*.21,-.055,.085),(.16,.30,.13),'foot_'+s,shoe,.025)
  ico((sg*.139,-.005,1.58),(.035,.028,.055),'head',skin)
  box((sg*.055,-.111,1.62),(.048,.018,.025),'head',white)
  box((sg*.055,-.123,1.62),(.018,.006,.019),'head',black)
  box((sg*.057,-.12,1.653),(.06,.014,.014),'head',hair)
 ico((0,-.131,1.575),(.029,.044,.05),'head',skin)
 box((0,-.114,1.51),(.071,.012,.014),'head',hair)
 if idx==1:box((0,-.128,1.72),(.31,.21,.035),'head',hair,.02)
 if idx==2:box((-.085,-.127,1.2),(.065,.008,.08),'chest',mat('Crachá',(.69,.63,.4)))
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();mesh=bpy.context.object;mesh.name=f'Customer{idx}_Visual'
 # Apply transforms so the armature uses the same model-space bind matrices.
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 mesh.parent=rig;mod=mesh.modifiers.new('Humanoid skin','ARMATURE');mod.object=rig
 bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
 bpy.ops.export_scene.gltf(filepath=str(root/'assets/models/characters'/f'Customer{idx}.glb'),use_selection=True,export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS')
print('3 original customers exported')
