"""Blender 4.3+: rebuild Dery and the corrected Felps, preserving uploaded originals.
blender -b -t 4 --python tools/rig_characters.py -- /absolute/project/root
Enemy and the independent customer rigs are intentionally unchanged.
"""
import bpy,sys,math,json,bmesh,hashlib
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
from humanoid_motion import Motion,DURATIONS,STRIDES,ONESHOTS,smooth
root=Path(sys.argv[sys.argv.index('--')+1]);report=json.loads((root/'docs/rig_report.json').read_text())
for name in ['Dery','Felps']:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 for a in list(bpy.data.actions):bpy.data.actions.remove(a)
 source=root/'assets/models/originals'/f'{name}.glb'
 bpy.ops.import_scene.gltf(filepath=str(source))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];assert len(meshes)==1
 mesh=meshes[0];bpy.context.view_layer.objects.active=mesh
 bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True)
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 floor=min(v.co.z for v in mesh.data.vertices);height=max(v.co.z for v in mesh.data.vertices)-floor
 for v in mesh.data.vertices:v.co.z-=floor;v.co*=1.78/height
 dec=mesh.modifiers.new('Preserve silhouette runtime budget','DECIMATE');dec.ratio=.24;bpy.ops.object.modifier_apply(modifier=dec.name)
 for mat in mesh.data.materials:
  bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
  for inp in ['Normal','Metallic','Roughness']:
   for link in list(bs.inputs[inp].links):mat.node_tree.links.remove(link)
  bs.inputs['Metallic'].default_value=0;bs.inputs['Roughness'].default_value=.96
  for n in mat.node_tree.nodes:
   if n.type=='TEX_IMAGE' and n.image:n.image.scale(1024,1024);n.interpolation='Closest'
 bpy.ops.object.armature_add();rig=bpy.context.object;rig.name=name+'_Rig'
 bpy.ops.object.mode_set(mode='EDIT');rig.data.edit_bones.remove(rig.data.edit_bones[0]);bones={}
 def bone(n,a,b,parent=None):
  q=rig.data.edit_bones.new(n);q.head=Vector(a)*1.78;q.tail=Vector(b)*1.78
  if parent:q.parent=bones[parent]
  bones[n]=q
 bone('pelvis',(0,0,.45),(0,0,.53));bone('spine',(0,0,.53),(0,0,.65),'pelvis');bone('chest',(0,0,.65),(0,0,.77),'spine')
 bone('neck',(0,0,.77),(0,0,.84),'chest');bone('head',(0,0,.84),(0,0,.98),'neck')
 for side,sg in [('L',1),('R',-1)]:
  bone('shoulder_'+side,(0,0,.76),(sg*.145,0,.755),'chest')
  bone('arm_'+side,(sg*.145,0,.755),(sg*.287,0,.75),'shoulder_'+side)
  bone('forearm_'+side,(sg*.287,0,.75),(sg*.39,0,.745),'arm_'+side)
  bone('hand_'+side,(sg*.39,0,.745),(sg*.44,0,.745),'forearm_'+side)
  bone('thigh_'+side,(sg*.085,0,.49),(sg*.105,0,.28),'pelvis')
  bone('shin_'+side,(sg*.105,0,.28),(sg*.12,0,.075),'thigh_'+side)
  bone('foot_'+side,(sg*.12,0,.075),(sg*.12,-.09,.04),'shin_'+side)
 bpy.ops.object.mode_set(mode='OBJECT')
 groups={n:mesh.vertex_groups.new(name=n) for n in bones}
 def blend(v,n1,n2,t):
  t=smooth(t)
  if t<1:groups[n1].add([v.index],1-t,'REPLACE')
  if t>0:groups[n2].add([v.index],t,'REPLACE')
 def between(v,axis,lo,hi,n1,n2):blend(v,n1,n2,(axis-lo)/(hi-lo))
 for v in mesh.data.vertices:
  x,y,z=v.co/1.78;side='L' if x>0 else 'R';ax=abs(x)
  if .63<z<.84 and ax>.12:
   if ax<.205:between(v,ax,.12,.205,'chest','arm_'+side)
   elif ax<.315:between(v,ax,.265,.315,'arm_'+side,'forearm_'+side)
   else:between(v,ax,.36,.405,'forearm_'+side,'hand_'+side)
  elif z<.49:
   if z>.415:between(v,z,.415,.495,'thigh_'+side,'pelvis')
   elif z>.225:between(v,z,.225,.315,'shin_'+side,'thigh_'+side)
   else:between(v,z,.075,.115,'foot_'+side,'shin_'+side)
  elif z<.65:between(v,z,.50,.65,'pelvis','spine')
  elif z<.77:between(v,z,.65,.76,'spine','chest')
  elif z<.85:between(v,z,.77,.85,'neck','head')
  else:groups['head'].add([v.index],1,'REPLACE')
 assert all(v.groups and abs(sum(g.weight for g in v.groups)-1)<1e-5 for v in mesh.data.vertices)
 mod=mesh.modifiers.new('Humanoid skin','ARMATURE');mod.object=rig;mesh.parent=rig;mesh.name=name+'_Body'
 # Shared skin/UVs on two render meshes allow a real first-person body without the head interior.
 head=mesh.copy();head.data=mesh.data.copy();bpy.context.collection.objects.link(head);head.name=name+'_Head'
 for ob,keep_head in [(mesh,False),(head,True)]:
  bm=bmesh.new();bm.from_mesh(ob.data)
  remove=[f for f in bm.faces if (f.calc_center_median().z>1.485)!=keep_head]
  bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(ob.data);bm.free()
 foot_points={}
 for side in ['L','R']:
  index=mesh.vertex_groups['foot_'+side].index;origin=rig.data.bones['foot_'+side].head_local
  foot_points[side]=[v.co-origin for v in mesh.data.vertices if any(g.group==index and g.weight>.8 for g in v.groups)]
 motion=Motion(rig,foot_points);rig.animation_data_create();fps=30;bpy.context.scene.render.fps=fps
 for clip,seconds in DURATIONS.items():
  act=bpy.data.actions.new(clip);rig.animation_data.action=act;end=round(seconds*fps)
  for frame in sorted(set(list(range(0,end+1,2))+[end])):
   motion.apply(clip,frame/end)
   for pb in rig.pose.bones:
    for key in ['location','rotation_quaternion','scale']:pb.keyframe_insert(key,frame=frame)
  for fcurve in act.fcurves:
   for key in fcurve.keyframe_points:key.interpolation='LINEAR'
  track=rig.animation_data.nla_tracks.new();track.name=clip;strip=track.strips.new(clip,0,act);track.mute=True;rig.animation_data.action=None
 # Export tracks individually, with a neutral underlying pose rather than stacked actions.
 motion.apply('idle',0);bpy.context.scene.frame_set(0)
 for track in rig.animation_data.nla_tracks:track.mute=False
 bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);head.select_set(True);bpy.context.view_layer.objects.active=rig
 bpy.ops.export_scene.gltf(filepath=str(root/'assets/models/characters'/f'{name}.glb'),use_selection=True,export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_materials='EXPORT')
 report[name]={'vertices':sum(len(o.data.vertices) for o in [mesh,head]),'triangles':sum(len(p.vertices)-2 for o in [mesh,head] for p in o.data.polygons),'bones':len(rig.data.bones),'unweighted':0,'clips':list(DURATIONS),'height_m':1.78,'source_height':height,'texture_size':1024,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'render_meshes':2}
(root/'docs/rig_report.json').write_text(json.dumps(report,indent=2))
(root/'resources/motion.json').write_text(json.dumps({'durations':DURATIONS,'strides':STRIDES,'oneshots':sorted(ONESHOTS)},indent=2))
print('RIG_REPORT',json.dumps(report))
