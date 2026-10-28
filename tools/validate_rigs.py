"""Validate exported GLB deformations and render a pose sheet, using Blender CPU."""
import bpy,sys,math,json
from pathlib import Path
from mathutils import Vector
root=Path(sys.argv[sys.argv.index('--')+1]);out=Path('/tmp/rig-review');out.mkdir(exist_ok=True);report={}
for name in ['Dery','Felps','Enemy']:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 for a in list(bpy.data.actions):bpy.data.actions.remove(a)
 bpy.ops.import_scene.gltf(filepath=str(root/'assets/models/characters'/f'{name}.glb'))
 rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
 for track in rig.animation_data.nla_tracks:track.mute=True
 checks=[]
 print("IMPORTED_ACTIONS",[a.name for a in bpy.data.actions])
 for idx,clip in enumerate(['idle','walk','run','crouch_idle','carry']):
  act=next(a for a in bpy.data.actions if a.name==clip+'_'+name+'_Rig')
  rig.animation_data.action=act;bpy.context.scene.frame_set(12 if clip!='run' else 8);bpy.context.view_layer.update()
  deps=bpy.context.evaluated_depsgraph_get();evaluated=mesh.evaluated_get(deps)
  snapshot=bpy.data.meshes.new_from_object(evaluated,depsgraph=deps)
  points=[v.co for v in snapshot.vertices]
  assert all(math.isfinite(c) for p in points for c in p)
  bounds=[max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)]
  assert bounds[0]<1.9 and bounds[1]<1.9 and bounds[2]<2.4,(name,clip,bounds)
  o=bpy.data.objects.new(clip,snapshot);bpy.context.collection.objects.link(o);o.location.x=idx*1.5
  checks.append({'clip':clip,'finite':True,'bounds':bounds})
 bpy.data.objects.remove(mesh,do_unlink=True);bpy.data.objects.remove(rig,do_unlink=True)
 scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=False;scene.world.color=(.23,.23,.23)
 bpy.ops.object.camera_add(location=(3,-8,2.2));cam=bpy.context.object;cam.rotation_euler=(Vector((3,0,.9))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=7.8;scene.camera=cam
 bpy.ops.object.light_add(type='AREA',location=(3,-4,5));light=bpy.context.object;light.data.energy=1100;light.data.size=7;light.rotation_euler=(Vector((3,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
 scene.render.resolution_x=1600;scene.render.resolution_y=460;scene.render.resolution_percentage=100;scene.render.filepath=str(out/f'{name}.png');bpy.ops.render.render(write_still=True)
 report[name]=checks
(root/'docs/rig_validation.json').write_text(json.dumps(report,indent=2))
