"""Sample exported deformations and measure shoe/support-plane contact."""
import bpy,json,sys,math
from pathlib import Path
root=Path(sys.argv[sys.argv.index('--')+1]);report={}
for name in ['Dery','Felps']:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 for a in list(bpy.data.actions):bpy.data.actions.remove(a)
 bpy.ops.import_scene.gltf(filepath=str(root/'assets/models/characters'/f'{name}.glb'))
 rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 for track in rig.animation_data.nla_tracks:track.mute=True
 body=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.name.endswith('_Body'))
 soles={}
 for side in ['L','R']:
  group=body.vertex_groups['foot_'+side].index
  soles[side]=[v.index for v in body.data.vertices if any(g.group==group and g.weight>.8 for g in v.groups)]
  assert soles[side],(name,side,'no sole samples')
 results={}
 for clip in ['idle','idle_shift','idle_look','walk','run','carry','carry_walk','crouch_idle','crouch_walk','pickup','put_down','cashier','talk']:
  action=next(a for a in bpy.data.actions if a.name==clip+'_'+name+'_Rig');rig.animation_data.action=action
  end=action.frame_range[1];penetration=0;lowest=10;highest_support=-10
  for i in range(41):
   t=i/40;bpy.context.scene.frame_set(int(end*t),subframe=end*t-int(end*t));bpy.context.view_layer.update()
   deps=bpy.context.evaluated_depsgraph_get();evaluated=body.evaluated_get(deps);mesh=evaluated.to_mesh()
   assert all(math.isfinite(c) for v in mesh.vertices for c in v.co),(name,clip,'NaN')
   for side,offset in [('L',0),('R',.5)]:
    phase=(t+offset)%1;support=phase<(.31 if clip=='run' else .56) if clip in ['walk','run','carry_walk','crouch_walk'] else True
    if support:
     minimum=min(mesh.vertices[j].co.z for j in soles[side]);lowest=min(lowest,minimum);highest_support=max(highest_support,minimum);penetration=max(penetration,-minimum)
   evaluated.to_mesh_clear()
  results[clip]={'maximum_sole_penetration_m':round(penetration,5),'lowest_support_sole_m':round(lowest,5),'highest_support_sole_m':round(highest_support,5),'finite':True}
 report[name]=results
(root/'docs/characters_v03/motion_metrics.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
assert all(r['maximum_sole_penetration_m']<.012 for a in report.values() for r in a.values()),'Ground penetration exceeds 1.2 cm'
