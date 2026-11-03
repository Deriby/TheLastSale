class_name AnalogFinish
extends Node3D
## Cosmetic layers on existing surfaces. No collision, navigation, actors or event state.
var details: Array[GeometryInstance3D]=[]
var bounce_lights: Array[Light3D]=[]
func _ready() -> void:
 name="AnalogFinish";physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
 var plaster:=SurfaceMaterials.make("wall",Color("c6bea1"))
 var edge:=Geo.material(Color("737b66"))
 # Old washable paint stops below the player eye line. All layers hug solid walls.
 for data in [
  [Vector3(-5.863,.40,-7.9),Vector2(15.3,.80),PI/2],
  [Vector3(5.863,.40,-8.0),Vector2(15.3,.80),-PI/2],
  [Vector3(-1.1,.40,-10.992),Vector2(9.6,.80),0.0],
  [Vector3(-1.1,.40,-11.208),Vector2(9.6,.80),PI],
  [Vector3(1.95,.40,-15.861),Vector2(2.65,.80),0.0]]:
  var node:=patch(data[0],data[1],float(data[2]),plaster)
  node.name="OldPaintBand";node.set_meta("visual_role","paint_band")
  var upper: Vector3=data[0];upper.y=.808
  patch(upper,Vector2(data[1].x,.022),float(data[2]),edge).name="PaintBandEdge"
 # Existing alpha artwork supplies irregular dampness and scuffed paint.
 for data in [
  [Vector3(-5.854,.30,-13.5),Vector2(4.0,.60),PI/2],
  [Vector3(5.854,.26,-11.9),Vector2(5.0,.52),-PI/2],
  [Vector3(1.95,.33,-15.85),Vector2(2.6,.66),0.0],
  [Vector3(-1.15,.22,-11.22),Vector2(8.8,.44),PI]]:
  var mat:=StandardMaterial3D.new();mat.albedo_texture=load("res://assets/textures/mood/wall_base.png");mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color=Color(.68,.64,.51,.42);mat.roughness=1;mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
  var node:=patch(data[0],data[1],float(data[2]),mat);node.name="WallPatina";details.append(node)
 for data in [Vector3(-2.5,.017,-13.6),Vector3(4.45,.017,-11.9),Vector3(2.7,.017,-.5)]:
  var mat:=StandardMaterial3D.new();mat.albedo_texture=load("res://assets/textures/details/floor_wear.png");mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color=Color(.73,.69,.57,.38);mat.roughness=.9;mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
  var node:=patch(data,Vector2(1.85,1.2),0,mat);node.rotation=Vector3(-PI/2,.7,0);node.name="TrafficScuff";details.append(node)
 # Reuse the store's own printed offer on the otherwise bare display back.
 for display in get_parent().find_children("ThermalCupDisplay","Node3D",true,false):
  var offer:=SceneDetail.panel(display,Vector3(0,1.08,-.151),Vector2(.58,.85),"cup_offer",PI)
  offer.name="OldDisplayOffer";offer.material_override.albedo_color=Color("dfd8bc");offer.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  for x in [-.20,.20]:
   var tape:=Geo.box(display,Vector3(x,1.505,-.16),Vector3(.075,.028,.006),Geo.material(Color("aaa17e")),false);tape.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 # A metal strike plate makes the existing handle read as part of a real old door.
 var door: Node3D=get_parent().old_door
 var shift: float=.65 if int(Session.campaign.night)==2 else 0.0
 var plate:=Geo.box(door,Vector3(.44+shift,1.055,.080),Vector3(.11,.29,.012),SurfaceMaterials.make("steel",Color("9a9a83")),false);plate.name="OldHandlePlate";plate.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 # Low, unshadowed bounce belongs to the same circuits as the existing fixtures.
 add_bounce("CounterBounce",Vector3(-4.3,1.9,-1.7),Color("edcf9e"),.19,3.1)
 add_bounce("StockBounce",Vector3(-1.0,2.55,-13.7),Color("d8c7a6"),.12,3.6)
 Preferences.changed.connect(apply_quality);apply_quality()
func patch(at: Vector3,extent: Vector2,angle: float,material: Material) -> MeshInstance3D:
 var node:=MeshInstance3D.new();var mesh:=QuadMesh.new();mesh.size=extent;node.mesh=mesh;node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node);node.position=at;node.rotation.y=angle;return node
func add_bounce(id: String,at: Vector3,color: Color,energy: float,radius: float) -> void:
 var light:=Geo.light(self,at,color,energy,radius);light.name=id;light.set_meta("detail_light",true);light.set_meta("normal_energy",energy);bounce_lights.append(light)
func apply_quality() -> void:
 for mesh in details:mesh.visible=Preferences.pixel_scale<3
 for light in bounce_lights:light.visible=Preferences.pixel_scale<3 and light.get_meta("circuit_on",true)
