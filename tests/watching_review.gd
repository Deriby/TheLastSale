extends Node
## Separate staged opportunities; actual event timing, original killer and physical cover.
var app: Node
var clock:=0.0
var scene:=-1
var started:=false
var caption: Label
var card: ColorRect
var results: Array=[]
var current: Dictionary={}
var taken:=false
var cases: Array[Dictionary]=[{"site":11,"at":Vector3(1.5,.01,-12.0)},{"site":3,"at":Vector3(4.25,.01,-8.5)},{"site":5,"at":Vector3(-4.7,.01,-8.5)}]
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 Preferences.camera_distance=0;Preferences.pixel_scale=2;Preferences.fov=68;Preferences.frame_limit=30;Preferences.ps1_mode=false;Preferences.apply();Session.new_shift()
 app=load("res://scenes/main/main.tscn").instantiate();app.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(app);app.start_new();app.interface.has_started=true;app.interface.set_paused(false);app.world.spawn_wait=999;Session.greet();Dialogue.clear();Session.world_seconds=420;Session.campaign.phase="restored";Session.campaign.flags.generator_running=true;app.world.friday.apply_power();app.world.player.torch.show();app.world.presence.state().next_at=99999
 for child in app.world.depot.stock_door.get_children():
  if child is Interaction and child.kind=="door":child.activate(app.world.player)
 var layer:=CanvasLayer.new();layer.layer=12;add_child(layer);card=ColorRect.new();layer.add_child(card);card.size=Vector2(1280,720);card.color=Color.BLACK
 caption=Label.new();layer.add_child(caption);caption.position=Vector2(80,190);caption.size=Vector2(1120,350);caption.add_theme_font_size_override("font_size",30);caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.text="0.31.0 — ALGUÉM ESTÁ OBSERVANDO?\n\nTrês oportunidades separadas, em tempo normal.\nOs intervalos foram cortados só nesta prévia."
func next_case() -> void:
 if scene>=0:results.append(current)
 scene+=1;clock=0;taken=false;started=false
 if scene>=cases.size():set_process(false);call_deferred("finish");return
 var data: Dictionary=cases[scene];var site: Dictionary=app.world.presence.sites[int(data.site)]
 var actor: DepotPlayer=app.world.player;actor.position=data.at;actor.velocity=Vector3.ZERO;actor.reset_physics_interpolation();actor.camera_rig.yaw=atan2(-(site.pos.x-data.at.x),-(site.pos.z-data.at.z))+.35;actor.camera_rig.pitch=-.05;actor.camera_rig.reset_follow()
 card.hide();caption.position=Vector2(25,20);caption.size=Vector2(1100,36);caption.add_theme_font_size_override("font_size",19);caption.text="0.31.0  /  exemplo "+str(scene+1)+" de 3  /  tempo normal"
 current={"site":site.id,"prepared":false,"head_seconds":0.0,"body_exposed":false,"retired_hidden":false,"note_count_before":Session.campaign.experience.notes.size()}
func _process(delta: float) -> void:
 clock+=delta;app.interface.hud.hide()
 if scene<0:
  if clock>2:next_case()
  return
 if not started and clock>.25:
  started=true;app.world.presence.state().next_at=99999;app.world.presence.create(app.world.presence.sites[int(cases[scene].site)],.28)
  var actor: HeadWatcher=app.world.presence.watcher
  actor.prepared.connect(func():current.prepared=true)
  actor.rejected.connect(func():current.rejected_reason=app.world.presence.last_rejection)
  actor.withdrawn.connect(func():current.retired_hidden=not app.world.presence.any_visible(actor.body_points()+actor.head_points()))
 if is_instance_valid(app.world.presence.watcher):
  var actor: HeadWatcher=app.world.presence.watcher
  if actor.started:
   current.body_exposed=bool(current.body_exposed) or app.world.presence.any_visible(actor.body_points())
   if app.world.presence.any_visible(actor.head_points()):current.head_seconds=float(current.head_seconds)+delta
   if actor.phase=="holding" and not taken:taken=true;call_deferred("shot",str(current.site))
 if clock>2.9:
  current.note_count_after=Session.campaign.experience.notes.size();current.forced_dialogue=Dialogue.active;next_case()
func shot(id: String) -> void:
 await RenderingServer.frame_post_draw
 var output:=OS.get_environment("WATCHING_REVIEW_PATH")
 if not output.is_empty():DirAccess.make_dir_recursive_absolute(output);get_viewport().get_texture().get_image().save_png(output+"/"+id+".png")
func finish() -> void:
 print("WATCHING REVIEW ",JSON.stringify(results))
 Dialogue.clear();app.world.sound.stop_all();await get_tree().create_timer(.25,true,false,true).timeout;app.queue_free()
 for frame in 5:await get_tree().process_frame
 Geo.materials.clear();ProductLibrary.materials.clear();ProductLibrary.meshes.clear();CharacterModels.imported_materials.clear();CharacterModels.costume_materials.clear();get_tree().quit(0 if results.all(func(item):return item.prepared and item.retired_hidden and not item.body_exposed and item.head_seconds>0) else 1)
