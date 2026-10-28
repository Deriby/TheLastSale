"""Run: blender -b -t 4 --python tools/rig_characters_legacy.py -- /absolute/project/root
Legacy Enemy-only generator; protagonists use rig_characters.py. Originals are never overwritten.
"""
import bpy,sys,math,json
from pathlib import Path
from mathutils import Vector,Quaternion
root=Path(sys.argv[sys.argv.index('--')+1]);report=json.loads((root/'docs/rig_report.json').read_text())
for name in ['Enemy']:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(root/'assets/models/originals'/f'{name}.glb'))
 mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
 bpy.context.view_layer.objects.active=mesh;mesh.select_set(True)
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 height=max(v.co.z for v in mesh.data.vertices);factor=1.78/height
 for v in mesh.data.vertices:v.co*=factor
 # Preserve UVs and silhouette, reduce the dense supplied scan-like surface.
 dec=mesh.modifiers.new('Runtime polygon budget','DECIMATE');dec.ratio=0.24
 bpy.ops.object.modifier_apply(modifier=dec.name)
 for mat in mesh.data.materials:
  bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
  for inp in ['Normal','Metallic','Roughness']:
   for link in list(bs.inputs[inp].links):mat.node_tree.links.remove(link)
  bs.inputs['Metallic'].default_value=0;bs.inputs['Roughness'].default_value=0.95
  for n in mat.node_tree.nodes:
   if n.type=='TEX_IMAGE' and n.image:
    n.image.scale(512,512);n.interpolation='Closest'
 bpy.ops.object.armature_add();rig=bpy.context.object;rig.name=name+'_Rig'
 bpy.ops.object.mode_set(mode='EDIT');rig.data.edit_bones.remove(rig.data.edit_bones[0])
 bones={}
 def bone(n,a,b,parent=None):
  q=rig.data.edit_bones.new(n);q.head=Vector(a)*1.78;q.tail=Vector(b)*1.78
  if parent:q.parent=bones[parent]
  bones[n]=q
 bone('pelvis',(0,0,.45),(0,0,.53))
 bone('spine',(0,0,.53),(0,0,.65),'pelvis');bone('chest',(0,0,.65),(0,0,.77),'spine')
 bone('neck',(0,0,.77),(0,0,.84),'chest');bone('head',(0,0,.84),(0,0,.98),'neck')
 for s,sg in [('L',1),('R',-1)]:
  bone('shoulder_'+s,(0,0,.76),(sg*.145,0,.755),'chest')
  bone('arm_'+s,(sg*.145,0,.755),(sg*.287,0,.75),'shoulder_'+s)
  bone('forearm_'+s,(sg*.287,0,.75),(sg*.39,0,.745),'arm_'+s)
  bone('hand_'+s,(sg*.39,0,.745),(sg*.44,0,.745),'forearm_'+s)
  bone('thigh_'+s,(sg*.085,0,.49),(sg*.105,0,.28),'pelvis')
  bone('shin_'+s,(sg*.105,0,.28),(sg*.12,0,.075),'thigh_'+s)
  bone('foot_'+s,(sg*.12,0,.075),(sg*.12,-.09,.04),'shin_'+s)
 bpy.ops.object.mode_set(mode='OBJECT')
 groups={n:mesh.vertex_groups.new(name=n) for n in bones}
 def blend(v,pairs):
  total=sum(w for _,w in pairs)
  for n,w in pairs:
   if w>0:groups[n].add([v.index],w/total,'REPLACE')
 def between(v,axis,lo,hi,n1,n2):
  t=max(0,min(1,(axis-lo)/(hi-lo)));blend(v,[(n1,1-t),(n2,t)])
 for v in mesh.data.vertices:
  x,y,z=v.co/1.78;s='L' if x>0 else 'R';ax=abs(x)
  if z>.64 and ax>.145:
   if ax<.21:between(v,ax,.145,.21,'chest','arm_'+s)
   elif ax<.315:between(v,ax,.265,.315,'arm_'+s,'forearm_'+s)
   else:between(v,ax,.365,.405,'forearm_'+s,'hand_'+s)
  elif z<.49:
   if z>.42:between(v,z,.42,.49,'thigh_'+s,'pelvis')
   elif z>.24:between(v,z,.24,.31,'shin_'+s,'thigh_'+s)
   else:between(v,z,.06,.12,'foot_'+s,'shin_'+s)
  elif z<.64:between(v,z,.5,.64,'pelvis','spine')
  elif z<.77:between(v,z,.65,.75,'spine','chest')
  elif z<.85:between(v,z,.77,.85,'neck','head')
  else:blend(v,[('head',1)])
 mod=mesh.modifiers.new('Humanoid skin','ARMATURE');mod.object=rig;mesh.parent=rig;mesh.name=name+'_Visual'
 rig.animation_data_create()
 clips=['idle','walk','run','crouch_idle','crouch_walk','carry','carry_walk','pickup','place','talk','cashier','look','startled','attack']
 for clip in clips:
  act=bpy.data.actions.new(clip);rig.animation_data.action=act;length=32 if clip=='run' else 48
  for frame in range(0,length+1,4):
   phase=frame/length*2*math.pi;wave=math.sin(phase)
   rotations={}
   for s,sg in [('L',1),('R',-1)]:
    rotations['arm_'+s]=Quaternion((0,1,0),sg*math.radians(82))
   moving=clip in ['walk','run','crouch_walk','carry_walk'];amp=.42 if clip!='run' else .75
   if moving:
    for s,sg in [('L',1),('R',-1)]:
     rotations['thigh_'+s]=Quaternion((1,0,0),sg*wave*amp)
     rotations['shin_'+s]=Quaternion((1,0,0),max(0,-sg*wave)*amp*1.1)
     rotations['arm_'+s]=Quaternion((1,0,0),-sg*wave*amp*.65)@rotations['arm_'+s]
   if clip.startswith('crouch'):
    for s in ['L','R']:
     rotations['thigh_'+s]=Quaternion((1,0,0),-1.0+sg*wave*.20 if moving else -1.0)
     rotations['shin_'+s]=Quaternion((1,0,0),1.65-sg*wave*.30 if moving else 1.65)
    rotations['spine']=Quaternion((1,0,0),.22)
   if clip in ['carry','carry_walk','pickup','place','cashier']:
    reach=.70 if clip in ['carry','carry_walk','cashier'] else max(0,math.sin(frame/length*math.pi))*.95
    for s in ['L','R']:
     rotations['arm_'+s]=Quaternion((1,0,0),-reach)@rotations['arm_'+s]
     rotations['forearm_'+s]=Quaternion((0,0,1),(-1 if s=='L' else 1)*.3)
   if clip in ['talk','look','startled','attack']:
    rotations['head']=Quaternion((0,0,1),wave*.22)
    if clip=='talk':rotations['forearm_L']=Quaternion((0,0,1),-.4-.25*wave)
    if clip in ['attack','startled']:rotations['arm_R']=Quaternion((1,0,0),-.9*math.sin(frame/length*math.pi))@rotations['arm_R']
   if clip=='idle':rotations['chest']=Quaternion((1,0,0),wave*.012)
   for pb in rig.pose.bones:
    rest=pb.bone.matrix_local.to_quaternion();pb.rotation_mode='QUATERNION';pb.rotation_quaternion=rest.inverted()@rotations.get(pb.name,Quaternion())@rest
    pb.location=rest.inverted()@Vector((0,0,-.23 if clip.startswith('crouch') else 0)) if pb.name=='pelvis' else (0,0,0)
    pb.keyframe_insert('rotation_quaternion',frame=frame);pb.keyframe_insert('location',frame=frame)
  track=rig.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,0,act);rig.animation_data.action=None
 # Rest validation: all vertices weighted, finite evaluated poses.
 unweighted=sum(not v.groups for v in mesh.data.vertices);assert unweighted==0
 rig.animation_data.action=None
 bpy.context.scene.frame_set(0)
 bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
 bpy.ops.export_scene.gltf(filepath=str(root/'assets/models/characters'/f'{name}.glb'),use_selection=True,export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_materials='EXPORT')
 report[name]={'vertices':len(mesh.data.vertices),'triangles':sum(len(p.vertices)-2 for p in mesh.data.polygons),'bones':len(rig.data.bones),'unweighted':unweighted,'clips':clips,'height_m':1.78,'source_height':height}
(root/'docs/rig_report.json').write_text(json.dumps(report,indent=2))
print('RIG_REPORT',json.dumps(report))
