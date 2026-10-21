import 'dart:math' as math;
import 'dart:ui';

const tau = 2 * math.pi;
double limit(double x, double lo, double hi) => x.clamp(lo, hi).toDouble();
double mix(double a, double b, double t) => a + (b - a) * t;
Offset point(List p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble());
Offset rotate(Offset p, double a) => Offset(
  p.dx * math.cos(a) - p.dy * math.sin(a),
  p.dx * math.sin(a) + p.dy * math.cos(a),
);

/// Two bones, with the bend direction chosen explicitly.
Offset solveJoint(Offset hip, Offset ankle, double l1, double l2, {double bend = 1}) {
  final d = ankle - hip;
  final r = limit(d.distance, .001, l1 + l2 - .001);
  final base = math.atan2(d.dy, d.dx);
  final angle = base - bend * math.acos(limit((l1*l1+r*r-l2*l2)/(2*l1*r), -1, 1));
  return hip + Offset(math.cos(angle)*l1, math.sin(angle)*l1);
}

class GuardPose {
  GuardPose({required this.bob,required this.backHip,required this.frontHip,
    required this.backFoot,required this.frontFoot,required this.backAnkle,
    required this.frontAnkle,required this.backKnee,required this.frontKnee,
    required this.shift,required this.shoulder,required this.wrist,
    required this.elbow,required this.lamp});
  final double bob;
  final Offset backHip,frontHip,backFoot,frontFoot,backAnkle,frontAnkle;
  final Offset backKnee,frontKnee,shift,shoulder,wrist,elbow,lamp;
}

class SnakePose {
  SnakePose(this.samples,this.outline,this.tip,this.angle);
  final List<Offset> samples,outline;
  final Offset tip;
  final double angle;
}

/// Pass actual world displacement, after collision/movement resolution.
/// This is visual state only; it does not replace the game's AI or physics.
class CharacterMotion {
  CharacterMotion(this.art);
  final Map<String,dynamic> art;
  Map<String,dynamic> get cfg => art['config'] as Map<String,dynamic>;
  double phase=0,distance=0,velocity=0,previousVelocity=0,weight=0;
  double lampAngle=0,lampVelocity=0,time=0,snakeTime=0,snakeEnergy=.25;
  bool sealed=false;
  /// In MedusaHead set this to its existing eyes getter, avoiding a second clock.
  double? externalEyes;
  int facing=1;
  double get gameScale => (cfg['gameScale'] as num).toDouble();
  Offset get lampPivot => point(cfg['lampPivot'] as List);

  double get eyes {
    if(sealed)return 0;
    if(externalEyes!=null)return limit(externalEyes!,0,1);
    final t=time%7.6;
    if(t<3.6)return 0;
    if(t<4.5)return (t-3.6)/.9;
    if(t<7.1)return 1;
    return 1-(t-7.1)/.5;
  }

  void update(double dt,{required double actualDx}) {
    if(dt<=0)return;
    velocity=actualDx/dt;distance+=actualDx;
    phase+=actualDx.abs()/(cfg['cycleDistance'] as num);
    weight=mix(weight,velocity.abs()>.03?1:0,1-math.exp(-dt*9));
    final acceleration=limit((velocity-previousVelocity)/dt,-220,220);
    previousVelocity=velocity;
    final target=limit(-acceleration*.0015,-.27,.27)+.022*math.sin(tau*phase*2)*weight;
    final count=math.max(1,(dt*120).ceil());final h=dt/count;
    for(var i=0;i<count;i++){
      lampVelocity+=(30*(target-lampAngle)-6*lampVelocity)*h;
      lampAngle+=lampVelocity*h;
    }
    if(!sealed){
      time+=dt;snakeTime+=dt;
      snakeEnergy=mix(snakeEnergy,.25+.75*eyes,1-math.exp(-dt*4));
    }
  }

  /// During stance: dxLocal/dDistance = -1/artScale.
  /// Actor translation cancels this exactly, so the planted foot stays put.
  Offset foot(double phaseValue) {
    final p=phaseValue%1;
    final duty=(cfg['duty'] as num).toDouble();
    final cycle=(cfg['cycleDistance'] as num)/gameScale;
    final span=cycle*duty;
    if(p<duty)return Offset(span*(.5-p/duty),0);
    final u=(p-duty)/(1-duty),u2=u*u,u3=u2*u;
    final m=-cycle*(1-duty);
    final x=(2*u3-3*u2+1)*(-span/2)+(u3-2*u2+u)*m+
      (-2*u3+3*u2)*(span/2)+(u3-u2)*m;
    final wave=math.sin(math.pi*u);
    return Offset(x,-(cfg['footLift'] as num).toDouble()*wave*wave*weight);
  }

  GuardPose guardPose() {
    final bob=-math.cos(tau*phase*2)*3.4*weight;
    final b=foot(phase+.5),f=foot(phase);
    final bh=Offset(244,588+bob),fh=Offset(309,588+bob);
    final bf=Offset(244+b.dx,777+b.dy),ff=Offset(309+f.dx,777+f.dy);
    final ba=bf-const Offset(0,46),fa=ff-const Offset(0,46);
    final shift=Offset(math.sin(tau*phase)*4*weight,math.cos(tau*phase)*2.5*weight);
    const shoulder=Offset(301,341);
    final wrist=const Offset(440,350)+shift;
    final lamp=lampPivot+rotate(point(cfg['lampCenter'] as List)-lampPivot,lampAngle)+shift;
    return GuardPose(bob:bob,backHip:bh,frontHip:fh,backFoot:bf,frontFoot:ff,
      backAnkle:ba,frontAnkle:fa,backKnee:solveJoint(bh,ba,94,90),
      frontKnee:solveJoint(fh,fa,94,90),shift:shift,shoulder:shoulder,
      wrist:wrist,elbow:solveJoint(shoulder,wrist,90,87,bend:-1),lamp:lamp);
  }

  SnakePose snake(int index) {
    final raw=(art['snakes'][index] as List);
    final pts=<Offset>[];
    for(var j=0;j<raw.length;j++){
      final p=point(raw[j] as List);
      if(j==0){pts.add(p);continue;}
      final w=math.pow(j/6,1.2).toDouble();
      pts.add(p+Offset(
        math.sin(snakeTime*(1.15+index*.071)+index*1.7+j*.6)*10*w*snakeEnergy,
        math.sin(snakeTime*(.86+index*.053)+index+j*.8)*8*w*snakeEnergy));
    }
    final samples=<Offset>[];
    for(var seg=0;seg<pts.length-1;seg++){
      final a=pts[math.max(0,seg-1)],b=pts[seg],c=pts[seg+1],d=pts[math.min(pts.length-1,seg+2)];
      for(var j=0;j<6;j++){
        final t=j/6,t2=t*t,t3=t2*t;
        samples.add((b*2+(c-a)*t+(a*2-b*5+c*4-d)*t2+(-a+b*3-c*3+d)*t3)*.5);
      }
    }
    samples.add(pts.last);
    final left=<Offset>[],right=<Offset>[];
    for(var i=0;i<samples.length;i++){
      final v=samples[math.min(i+1,samples.length-1)]-samples[math.max(i-1,0)];
      final l=math.max(.001,v.distance),r=mix(16,10,i/(samples.length-1));
      final normal=Offset(-v.dy/l*r,v.dx/l*r);
      left.add(samples[i]+normal);right.add(samples[i]-normal);
    }
    final tangent=samples.last-samples[samples.length-2];
    return SnakePose(samples,[...left,...right.reversed],samples.last,math.atan2(tangent.dy,tangent.dx));
  }
}
