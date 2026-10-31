extends RefCounted
## Offline periodic foot paths, with matching velocity and acceleration at joins.
static func smoother(value: float) -> float:
	var t:=clampf(value,0,1)
	return t*t*t*(10+t*(-15+6*t))
static func hermite(a: float,b: float,va: float,vb: float,t: float) -> float:
	var c:=b-a-va;var d:=vb-va
	return a+va*t+(10*c-4*d)*pow(t,3)+(-15*c+7*d)*pow(t,4)+(6*c-3*d)*pow(t,5)
static func foot(phase: float,stride: float,running: bool,scale: float) -> Dictionary:
	var stance:=.25 if running else .56
	var t:=fposmod(phase,1.0)
	var front:=stride*(.105 if running else .26);var back:=front-stride*stance
	var z:=front-stride*t;var lift:=0.0;var pitch:=0.0
	if t<stance:
		pitch=lerpf(-.16 if running else -.13,0,smoother(t/.075))
		pitch+=(.45 if running else .25)*smoother((t-(stance-.10))/.10)
	else:
		var u: float=(t-stance)/(1-stance);var edge:=.07
		var tangent: float=-stride*(1-stance);var overshoot: float=-tangent*edge*.5
		if u<edge:z=hermite(back,back-overshoot,tangent*edge,0,u/edge)
		elif u>1-edge:z=hermite(front+overshoot,front,0,tangent*edge,(u-1+edge)/edge)
		else:z=lerpf(back-overshoot,front+overshoot,smoother((u-edge)/(1-2*edge)))
		var peak:=.15 if running else .30
		var tail:=17 if running else 7
		var bell: float=pow(u,3)*pow(1-u,tail)/(pow(peak,3)*pow(1-peak,tail))
		lift=scale*(.15*bell+.07*64*pow(u,3)*pow(1-u,3) if running else .055*bell)
		pitch=lerpf(.45 if running else .25,-.16 if running else -.13,smoother(u))
	var contact:=smoother(t/.025)*(1-smoother((t-stance+.025)/.025)) if t<stance else 0.0
	return {"z":z,"lift":lift,"pitch":pitch,"contact":contact}
static func pelvis(time: float,running: bool,scale: float) -> float:
	return -(.04+.012*cos(TAU*2*(time-.14)) if running else .030+.020*cos(TAU*2*time))*scale
