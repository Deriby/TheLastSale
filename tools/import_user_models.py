"""Convert the supplied AccuRIG FBX files without auto-rigging or replacing skin weights.

blender -b -t 4 --python tools/import_user_models.py -- PROJECT SOURCE [Dery ...]
SOURCE is the extracted 'Modelos para The Last Sale' folder, kept outside Git.
"""
import bpy, bmesh, sys, json, math, hashlib
from pathlib import Path
from mathutils import Matrix, Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
from humanoid_motion import Motion,DURATIONS

args=sys.argv[sys.argv.index('--')+1:]
project,source=map(Path,args[:2]);selected=set(args[2:])
CAST={
 'Dery':('Dery',1.78,35000), 'Felps':('Felps',1.77,35000),
 'Killer':('Enemy',1.86,26000), 'Bryan - NPC':('Bryan',1.19,24000),
 'Garota 1 - NPC':('Garota1',1.66,24000), 'Garota 2 - NPC':('Garota2',1.70,24000),
 'Velha 1 - NPC':('Velha1',1.58,24000), 'Zirico - NPC':('Zirico',1.74,26000),
}
MAP={'RL_BoneRoot':'root','CC_Base_Hip':'pelvis','CC_Base_Pelvis':'hip_support',
 'CC_Base_Waist':'waist','CC_Base_Spine01':'spine','CC_Base_Spine02':'chest',
 'CC_Base_NeckTwist01':'neck','CC_Base_NeckTwist02':'neck_upper','CC_Base_Head':'head'}
for side in ['L','R']:
 for old,new in [('Clavicle','shoulder'),('Upperarm','arm'),('Forearm','forearm'),('Hand','hand'),('Thigh','thigh'),('Calf','shin'),('Foot','foot')]:
  MAP[f'CC_Base_{side}_{old}']=f'{new}_{side}'
output=project/'assets/models/characters';output.mkdir(exist_ok=True,parents=True)
report_path=project/'docs/user_models_report.json'
report=json.loads(report_path.read_text()) if report_path.exists() else {}

def normalize(meshes,rig=None,length=None):
 points=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
 floor=min(p.z for p in points);height=max(p.z for p in points)-floor
 factor=(length/(max(p.y for p in points)-min(p.y for p in points))) if length else 1.78/height
 center=Vector(((min(p.x for p in points)+max(p.x for p in points))*.5,(min(p.y for p in points)+max(p.y for p in points))*.5,0)) if length else Vector((0,0,0))
 transform=Matrix.Scale(factor,4)@Matrix.Translation(-center-Vector((0,0,floor)))
 if length:transform=Matrix.Rotation(-math.pi/2,4,'Z')@transform
 world={o:o.matrix_world.copy() for o in meshes+([rig] if rig else [])}
 for o in world:o.parent=None
 for o,matrix in world.items():
  if o.type=='MESH':o.data.transform(transform@matrix,shape_keys=True)
  else:o.data.transform(transform@matrix)
  o.matrix_world=Matrix.Identity(4)
 if rig:
  for o in meshes:o.parent=rig;o.matrix_parent_inverse=Matrix.Identity(4)
 return height

def materials(meshes,car=False):
 used=set(m for o in meshes for m in o.data.materials if m)
 images=set()
 for mat in used:
  bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
  bs.inputs['Alpha'].default_value=1
  for link in list(bs.inputs['Alpha'].links):mat.node_tree.links.remove(link)
  if not car:
   bs.inputs['Roughness'].default_value=.88;bs.inputs['Metallic'].default_value=0
   for link in list(bs.inputs['Metallic'].links):mat.node_tree.links.remove(link)
  for n in mat.node_tree.nodes:
   if n.type=='NORMAL_MAP':n.inputs['Strength'].default_value=.45 if not car else .65
   if n.type=='TEX_IMAGE' and n.image:
    normal='normal' in n.image.name.lower()
    utility=any(key in n.image.name.lower() for key in ['metallic','roughness'])
    size=(512 if utility else (1024 if normal else 2048)) if car else (512 if normal else 1024)
    n.image.scale(size,size);n.interpolation='Linear';images.add(n.image)
 return [{'name':im.name,'size':list(im.size)} for im in images]

def weights(mesh):
 # Compatibility uses four influences. Keep the supplied dominant influences,
 # normalize only the small discarded remainder; no automatic reweighting.
 removed=0
 for v in mesh.data.vertices:
  values=sorted([(g.group,g.weight) for g in v.groups if g.weight>0],key=lambda x:-x[1])
  if not values:raise RuntimeError('Unweighted source vertex')
  for index,w in values[4:]:mesh.vertex_groups[index].remove([v.index]);removed+=1
  total=sum(w for _,w in values[:4])
  for index,w in values[:4]:mesh.vertex_groups[index].add([v.index],w/total,'REPLACE')
 return removed

for folder,(name,height,budget) in CAST.items():
 if selected and name not in selected:continue
 bpy.ops.wm.read_factory_settings(use_empty=True)
 f=next(f for f in (source/folder).glob('*.fbx') if 'rig' in f.stem.lower())
 bpy.ops.import_scene.fbx(filepath=str(f),use_anim=False)
 rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 assert len(meshes)==1
 mesh=meshes[0];source_height=normalize(meshes,rig)
 source_bones=len(rig.data.bones)
 for old,new in MAP.items():
  rig.data.bones[old].name=new
  for ob in meshes:
   if old in ob.vertex_groups:ob.vertex_groups[old].name=new
 rig.name=name+'_Rig';mesh.name=name+'_Body'
 bpy.context.view_layer.objects.active=rig
 bpy.ops.object.mode_set(mode='EDIT')
 chest=rig.data.edit_bones['chest']
 upper=rig.data.edit_bones.new('upper_chest');upper.head=chest.head.lerp(rig.data.edit_bones['neck'].head,.72);upper.tail=upper.head+Vector((0,0,.06));upper.parent=chest;upper.use_deform=False
 for n in ['neck','shoulder_L','shoulder_R']:rig.data.edit_bones[n].parent=upper
 bpy.ops.object.mode_set(mode='OBJECT')
 textures=materials(meshes)
 bpy.context.view_layer.objects.active=mesh
 triangles=sum(len(p.vertices)-2 for p in mesh.data.polygons)
 nonempty_shapes=False
 if mesh.data.shape_keys:
  basis=mesh.data.shape_keys.key_blocks[0]
  nonempty_shapes=any(any((v.co-basis.data[i].co).length>1e-7 for i,v in enumerate(k.data)) for k in list(mesh.data.shape_keys.key_blocks)[1:])
  if not nonempty_shapes:mesh.shape_key_clear()
 if not nonempty_shapes:
  dec=mesh.modifiers.new('Runtime silhouette budget','DECIMATE');dec.ratio=min(1,budget/triangles);mesh.modifiers.move(len(mesh.modifiers)-1,0)
  bpy.ops.object.modifier_apply(modifier=dec.name)
 pruned=weights(mesh)
 if name in ['Dery','Felps']:
  head=mesh.copy();head.data=mesh.data.copy();bpy.context.collection.objects.link(head);head.name=name+'_Head'
  cutoff=rig.data.bones['neck_upper'].head_local.z+.015
  for ob,keep in [(mesh,False),(head,True)]:
   bm=bmesh.new();bm.from_mesh(ob.data)
   bmesh.ops.delete(bm,geom=[face for face in bm.faces if (face.calc_center_median().z>cutoff)!=keep],context='FACES')
   # Drop isolated vertices left by face deletion; they inflate skinning cost/bounds.
   bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
   bm.to_mesh(ob.data);bm.free()
  meshes.append(head)
 foot_points={}
 for side in ['L','R']:
  foot=rig.data.bones['foot_'+side];names={foot.name}|{b.name for b in foot.children_recursive}
  indices={g.index for g in mesh.vertex_groups if g.name in names}
  foot_points[side]=[v.co-foot.head_local for v in mesh.data.vertices if sum(g.weight for g in v.groups if g.group in indices)>.5 and v.co.z<.32]
  assert foot_points[side]
 motion=Motion(rig,foot_points);rig.animation_data_create();fps=30;bpy.context.scene.render.fps=fps
 clips=[c for c in DURATIONS if c not in ['hold_bottle','browse','pay']] if name in ['Dery','Felps'] else ['idle','idle_shift','idle_look','walk','carry','talk','look','startled','hold_bottle','browse','pay']
 if name=='Enemy':clips=['idle','walk','look','attack']
 for clip in clips:
  action=bpy.data.actions.new(clip);rig.animation_data.action=action;end=round(DURATIONS[clip]*fps)
  for frame in sorted(set(range(0,end+1,2))|{end}):
   motion.apply(clip,frame/end)
   for pb in rig.pose.bones:
    for prop in ['location','rotation_quaternion','scale']:pb.keyframe_insert(prop,frame=frame)
  for curve in action.fcurves:
   for key in curve.keyframe_points:key.interpolation='LINEAR'
  track=rig.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,0,action);track.mute=True;rig.animation_data.action=None
 motion.apply('idle',0);bpy.context.scene.frame_set(0)
 for track in rig.animation_data.nla_tracks:track.mute=False
 rig.scale=(height/1.78,)*3
 bpy.ops.object.select_all(action='DESELECT')
 for ob in [rig]+meshes:ob.select_set(True)
 bpy.context.view_layer.objects.active=rig
 dest=output/(name+'.glb')
 bpy.ops.export_scene.gltf(filepath=str(dest),use_selection=True,export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_step=2,export_materials='EXPORT')
 report[name]={'source_file':str(f.relative_to(source)),'source_sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'source_bones':source_bones,'runtime_bones':len(rig.data.bones),'source_triangles':triangles,'triangles':sum(len(p.vertices)-2 for ob in meshes for p in ob.data.polygons),'vertices':sum(len(ob.data.vertices) for ob in meshes),'pruned_minor_influences':pruned,'height_m':height,'source_height_m':source_height,'foot_clearance':sum(motion.foot_height(s,0) for s in ['L','R'])*.5*height/1.78,'stride_scale':height/1.78,'textures':textures,'clips':clips,'bytes':dest.stat().st_size,'skin':'uploaded AccuRIG weights; collapse interpolation and four-influence normalization only'}
 report_path.write_text(json.dumps(report,indent=2)+'\n')
 print('MODEL_READY',name,report[name],flush=True)

if not selected or 'Carro1' in selected:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 f=source/'Carro 1/Carro 1.fbx';bpy.ops.import_scene.fbx(filepath=str(f),use_anim=False)
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];normalize(meshes,length=4.2);textures=materials(meshes,True)
 for ob in meshes:ob.name='UserCar_Body'
 dest=project/'assets/models/environment/user_car.glb'
 bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',export_animations=False,export_materials='EXPORT')
 points=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
 report['Carro1']={'source_file':str(f.relative_to(source)),'source_sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'triangles':sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons),'dimensions_m':[max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)],'textures':textures,'bytes':dest.stat().st_size}
 report_path.write_text(json.dumps(report,indent=2)+'\n');print('MODEL_READY Carro1',report['Carro1'],flush=True)

profiles={name:{k:data[k] for k in ['height_m','foot_clearance','stride_scale','runtime_bones']} for name,data in report.items() if 'runtime_bones' in data}
(project/'resources/character_profiles.json').write_text(json.dumps(profiles,indent=2)+'\n')
