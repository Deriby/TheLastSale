"""Render actual exported arm/torso bones and measure the relaxed pose.
blender -b -t 4 --python tools/review_anatomy.py -- PROJECT [PREVIOUS_DERY_GLB]
"""
import bpy,sys,json,math
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];root=Path(args[0]);out=root/'docs/fixes_v031';out.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
items=[]
if len(args)>1:items.append(('DERYK 0.3',Path(args[1]),False))
items += [(n+' 0.3.1',root/'assets/models/characters'/f'{file}.glb',True) for n,file in [('DERYK','Dery'),('FELPS','Felps')]]
overlay=[];report={}
def flat(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);return m
red=flat('Actual bone segments',(.9,.025,.025));blue=flat('Actual joints',(.015,.22,1))
for column,(label,path,current) in enumerate(items):
 previous=set(bpy.context.scene.objects);previous_actions=set(bpy.data.actions);bpy.ops.import_scene.gltf(filepath=str(path))
 imported=set(bpy.context.scene.objects)-previous;rig=next(o for o in imported if o.type=='ARMATURE')
 for track in rig.animation_data.nla_tracks:track.mute=True
 action=next(a for a in set(bpy.data.actions)-previous_actions if a.name.startswith('idle_') and not any(v in a.name for v in ['shift','look','adjust','tired']))
 rig.animation_data.action=action;bpy.context.scene.frame_set(30);bpy.context.view_layer.update()
 for ob in imported:
  if not ob.parent:ob.location.x+=column*1.02
 bpy.context.view_layer.update()
 def at(name):return rig.matrix_world@rig.pose.bones[name].head
 if current:
  data={}
  for side in ['L','R']:
   a,b,c=[at(n+'_'+side) for n in ['arm','forearm','hand']]
   angle=math.degrees((b-a).angle(c-b))
   data[side]={'shoulder_height_m':round(a.z,4),'elbow_height_m':round(b.z,4),'wrist_height_m':round(c.z,4),'elbow_flexion_deg':round(angle,2),'upper_arm_m':round((b-a).length,4),'forearm_m':round((c-b).length,4)}
   assert .70<c.z<.84 and .98<b.z<1.14,(label,side,data[side])
   assert .8<(b-a).length/(c-b).length<1.2,(label,side,'limb ratio')
   assert angle<30,(label,side,'relaxed elbow is over-flexed',angle)
  data['torso_bones']=[n for n in ['pelvis','waist','spine','chest','upper_chest'] if n in rig.pose.bones]
  assert len(data['torso_bones'])==5
  report[label]=data
 segments=['pelvis','waist','spine','chest','upper_chest','shoulder_L','shoulder_R','arm_L','forearm_L','arm_R','forearm_R']
 for name in segments:
  if name not in rig.pose.bones:continue
  pb=rig.pose.bones[name];a=rig.matrix_world@pb.head;b=rig.matrix_world@pb.tail
  a.y=b.y=-.25;direction=b-a
  bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.006,depth=direction.length,location=(a+b)*.5)
  line=bpy.context.object;line.rotation_euler=direction.to_track_quat('Z','Y').to_euler();line.data.materials.append(red);overlay.append(line)
  for p in [a,b]:
   bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=.013,location=p)
   joint=bpy.context.object;joint.data.materials.append(blue);overlay.append(joint)
 bpy.ops.object.text_add(location=(column*1.02,-.15,1.91),rotation=(math.pi/2,0,0))
 text=bpy.context.object;text.data.body=label;text.data.align_x='CENTER';text.data.size=.078;text.data.materials.append(flat('Label',(.8,.85,.8)))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False;scene.world.color=(.20,.20,.20)
center=(len(items)-1)*1.02/2
bpy.ops.object.camera_add(location=(center,-6,1.03));camera=bpy.context.object;camera.rotation_euler=(Vector((center,0,1.03))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=3.25;scene.camera=camera
bpy.ops.object.light_add(type='AREA',location=(center,-4,5));light=bpy.context.object;light.data.energy=1000;light.data.size=6;light.rotation_euler=(Vector((center,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=1400;scene.render.resolution_y=950;scene.render.resolution_percentage=100
scene.render.filepath=str(out/'anatomy_bones.png');bpy.ops.render.render(write_still=True)
for ob in overlay:ob.hide_render=True
scene.render.filepath=str(out/'anatomy_clean.png');bpy.ops.render.render(write_still=True)
(out/'arm_metrics.json').write_text(json.dumps(report,indent=2)+'\n');print('ARM_METRICS',json.dumps(report))
