"""Authored in-place humanoid motion with analytic two-bone IK and stance phases.
Blender coordinates: +Z up, -Y forward. No external animation or mocap assets.
"""
import math
from mathutils import Vector, Quaternion, Matrix, Euler
TAU=math.tau
DURATIONS={'idle':8,'idle_shift':6,'idle_look':5,'idle_adjust':4,'idle_tired':4,'walk':1,'walk_back':1,'strafe_left':1,'strafe_right':1,'run':1,'crouch_idle':6,'crouch_walk':1,'carry':6,'carry_walk':1,'pickup':1.25,'place':1.0,'put_down':1.25,'talk':5,'cashier':6,'cashier_idle':7,'look':5,'startled':1.4,'attack':1.1}
STRIDES={'walk':1.12,'walk_back':.80,'strafe_left':.82,'strafe_right':.82,'run':2.35,'crouch_walk':.62,'carry_walk':.86}
ONESHOTS={'idle_shift','idle_look','idle_adjust','pickup','place','put_down','startled','attack'}
def smooth(t):t=max(0,min(1,t));return t*t*(3-2*t)
def mix(a,b,t):return a+(b-a)*t
def rot(x=0,y=0,z=0):return Euler((x,y,z),'XYZ').to_quaternion()
def ik(a,target,l1,l2,pole):
 delta=target-a;length=min(max(delta.length,.005),l1+l2-.001)
 direction=delta.normalized();target=a+direction*length
 projected=pole-a-direction*((pole-a).dot(direction))
 if projected.length<1e-4:projected=Vector((0,-1,0))
 projected.normalize();along=(l1*l1-l2*l2+length*length)/(2*length)
 bend=math.sqrt(max(.000001,l1*l1-along*along))
 return a+direction*along+projected*bend,target
class Motion:
 def __init__(self,rig,foot_points):
  self.foot_points=foot_points;self.height_cache={}
  self.rig=rig;self.rest={b.name:b.matrix_local.copy() for b in rig.data.bones};self.pose={}
 def foot_height(self,side,pitch):
  key=(side,round(pitch,5))
  if key not in self.height_cache:
   delta=rot(x=pitch,z=-.055 if side=='L' else .055)
   self.height_cache[key]=-min((delta @ p).z for p in self.foot_points[side])
  return self.height_cache[key]
 def fk(self,name,delta=Quaternion()):
  b=self.rig.data.bones[name]
  base=self.rest[name] if not b.parent else self.pose[b.parent.name]@self.rest[b.parent.name].inverted()@self.rest[name]
  self.pose[name]=Matrix.Translation(base.translation)@(delta@base.to_quaternion()).to_matrix().to_4x4()
 def segment(self,name,head,tail):
  b=self.rig.data.bones[name];rest_dir=(b.tail_local-b.head_local).normalized()
  q=rest_dir.rotation_difference((tail-head).normalized())@self.rest[name].to_quaternion()
  self.pose[name]=Matrix.Translation(head)@q.to_matrix().to_4x4()
 def child_head(self,name):
  b=self.rig.data.bones[name]
  return (self.pose[b.parent.name]@self.rest[b.parent.name].inverted()@self.rest[name]).translation
 def apply(self,clip,t):
  phase=t*TAU;breath=math.sin(t*TAU*(2 if DURATIONS[clip]>=6 else 1))
  moving=clip in STRIDES;running=clip=='run';crouch=clip.startswith('crouch');carrying=clip in ['carry','carry_walk']
  # Hip height is measured at the femoral heads, not the pelvis bone origin.
  hip=.855;lean=.025;sway=.009*math.sin(phase);hip_y=.0
  if moving:hip=(.79 if running else (.49 if crouch else .805))+.009*math.cos(phase*2);sway=.012*math.sin(phase);lean=.18 if running else (.32 if crouch else (.08 if carrying else .045))
  elif crouch:hip=.49;lean=.32
  elif carrying:hip=.84;lean=-.025
  if clip=='idle_shift':sway=.030*math.sin(phase);hip-=.008*math.sin(phase)**2
  if clip=='idle_tired':breath=math.sin(phase*2);lean=.065
  reach=0.0
  if clip in ['pickup','put_down']:
   # Reach -> grasp -> lift. put_down is its time reverse.
   u=t if clip=='pickup' else 1-t
   down=smooth(u/.36) if u<.45 else 1-smooth((u-.48)/.46)
   hip=mix(.855,.39,down);lean=mix(.025,.62,down);hip_y=.035*down;reach=down
  if clip=='place':lean+=.13*math.sin(math.pi*t);reach=math.sin(math.pi*t)
  if clip=='startled':hip-=.045*math.sin(math.pi*t);lean=-.10*math.sin(math.pi*t)
  root_delta=Vector((sway,hip_y,hip-.872))
  self.pose={}
  self.pose['pelvis']=Matrix.Translation(self.rest['pelvis'].translation+root_delta)@(rot(y=.012*math.sin(phase),z=.025*math.sin(phase) if moving else .006*breath)@self.rest['pelvis'].to_quaternion()).to_matrix().to_4x4()
  self.fk('spine',rot(x=lean*.55,y=-.008*breath,z=-.025*math.sin(phase) if moving else 0))
  self.fk('chest',rot(x=lean*.45+.006*breath,y=.005*breath,z=-.025*math.sin(phase) if moving else .008*math.sin(phase)))
  self.fk('neck',rot(x=-lean*.18))
  head_yaw=.035*math.sin(phase*.5)*math.sin(math.pi*t)**2
  if clip in ['idle_look','look']:head_yaw=.32*math.sin(phase)*math.sin(math.pi*t)**2
  if clip=='talk':head_yaw=.10*math.sin(phase);breath=math.sin(phase*2)
  self.fk('head',rot(x=(.10 if clip in ['cashier','cashier_idle'] else -.02)+(.022*math.sin(phase*3) if clip=='talk' else .008*breath),z=head_yaw))
  # Breathing expands the rib cage gently without scaling the entire character.
  chest_scale=1+.004*breath*(1.6 if clip=='idle_tired' else 1)
  self.pose['chest']@=Matrix.Diagonal((chest_scale,1.0,chest_scale,1))
  for side,sg in [('L',1),('R',-1)]:
   self.fk('shoulder_'+side,rot(x=.008*breath,y=sg*.012*math.sin(phase+.3)))
   # Feet remain on their authored support plane; knees bend toward the front.
   foot_phase=(t+(0 if side=='L' else .5))%1
   ankle=Vector((sg*.14,sg*.025,.1335));toe_pitch=0.0
   if moving:
    stride=STRIDES[clip];stance=.31 if running else .56
    front=-stride*(.125 if running else stance*.5)
    back=front+stride*stance
    if foot_phase<stance:
     u=foot_phase/stance;foreaft=mix(front,back,u)
     toe_pitch=-.09*max(0,1-u*6)+(.38 if running else .18)*smooth((u-.72)/.28)
    else:
     u=(foot_phase-stance)/(1-stance)
     # Hermite swing: velocity matches the support phase at the endpoints.
     h00=2*u**3-3*u*u+1;h10=u**3-2*u*u+u;h01=-2*u**3+3*u*u;h11=u**3-u*u
     tangent=stride*(1-stance)
     foreaft=h00*back+h10*tangent+h01*front+h11*tangent
     toeoff=.38 if running else .18
     toe_pitch=toeoff*(1-smooth(u/.25))+.12*math.sin(math.pi*u)-.09*smooth((u-.75)/.25)
    if clip.startswith('strafe'):
     ankle.x+=foreaft*(-1 if clip=='strafe_left' else 1);ankle.y=0
    elif clip=='walk_back':ankle.y=-foreaft
    else:ankle.y=foreaft
    ankle.z=self.foot_height(side,toe_pitch)
    if foot_phase>=stance:
     u=(foot_phase-stance)/(1-stance)
     ankle.z+=(.22 if running else (.07 if crouch else .095))*math.sin(math.pi*u)**1.25
   if not moving:ankle.z=self.foot_height(side,0)
   hip_point=self.child_head('thigh_'+side)
   thigh=self.rig.data.bones['thigh_'+side];shin=self.rig.data.bones['shin_'+side]
   l1=(self.rest['shin_'+side].translation-self.rest['thigh_'+side].translation).length
   l2=(self.rest['foot_'+side].translation-self.rest['shin_'+side].translation).length
   knee,end=ik(hip_point,ankle,l1,l2,hip_point+Vector((sg*.08,-1,0)))
   self.segment('thigh_'+side,hip_point,knee);self.segment('shin_'+side,knee,end)
   foot_q=rot(x=toe_pitch,z=-sg*.055)@self.rest['foot_'+side].to_quaternion()
   self.pose['foot_'+side]=Matrix.Translation(end)@foot_q.to_matrix().to_4x4()
   # Wrists define the arm pose; elbows use a restrained outward/backward pole.
   hand=Vector((sg*.275,-.045,.925))+root_delta*.45
   if moving and not carrying:
    swing=math.sin(phase+(0 if side=='L' else math.pi))
    if running:hand=Vector((sg*.25,swing*.20,.98+max(0,-swing)*.13))
    elif not crouch:hand.y+=swing*.105;hand.z+=.02*math.cos(phase*2)
    else:hand=Vector((sg*.27,-.18,.74))
   if carrying:hand=Vector((sg*.335,-.26,1.07))+Vector((sway,0,.004*breath+(.008*math.cos(phase*2) if moving else 0)))
   if clip in ['pickup','put_down']:
    u=t if clip=='pickup' else 1-t
    if u<.45:hand=Vector((sg*mix(.275,.335,smooth(u/.36)),mix(-.045,-.43,smooth(u/.36)),mix(.925,.43,smooth(u/.36))))
    else:hand=Vector((sg*.335,mix(-.43,-.26,smooth((u-.48)/.46)),mix(.43,1.07,smooth((u-.48)/.46))))
   if clip=='place':hand=Vector((sg*.335,-.26-.11*reach,1.07+.07*reach))
   if clip in ['cashier','cashier_idle']:
    amount=.015*math.sin(phase*12+sg) if clip=='cashier' else .004*breath
    hand=Vector((.08+sg*.14,-.27,1.22+amount))
   if clip=='talk' and side=='L':hand=Vector((.27,-.16-.10*math.sin(phase),.99+.09*math.sin(phase*2)))
   if clip=='idle_adjust' and side=='R':
    amount=math.sin(math.pi*t)**2;hand=hand.lerp(Vector((-.18,-.13,.99)),amount)
   hand+=Vector((.002*breath,-.003*breath,.003*breath))
   shoulder=self.child_head('arm_'+side)
   l1=(self.rest['forearm_'+side].translation-self.rest['arm_'+side].translation).length
   l2=(self.rest['hand_'+side].translation-self.rest['forearm_'+side].translation).length
   pole=shoulder+Vector((sg*.12,.45,-.30))
   elbow,wrist=ik(shoulder,hand,l1,l2,pole)
   self.segment('arm_'+side,shoulder,elbow);self.segment('forearm_'+side,elbow,wrist)
   hand_dir=Vector((0,-1,-.08)) if carrying or clip in ['pickup','put_down','place','cashier','cashier_idle'] else wrist-elbow
   self.segment('hand_'+side,wrist,wrist+hand_dir.normalized()*.08)
  for bone in self.rig.data.bones:
   local_rest=self.rest[bone.name] if not bone.parent else self.rest[bone.parent.name].inverted()@self.rest[bone.name]
   parent=self.pose[bone.parent.name] if bone.parent else Matrix.Identity(4)
   basis=local_rest.inverted()@parent.inverted()@self.pose[bone.name]
   pb=self.rig.pose.bones[bone.name];pb.rotation_mode='QUATERNION';pb.location=basis.translation;pb.rotation_quaternion=basis.to_quaternion();pb.scale=basis.to_scale()
