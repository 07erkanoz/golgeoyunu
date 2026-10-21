import 'dart:math' as math;
import 'dart:ui';
import 'character_motion.dart';
import 'vector_art.dart';

void drawLine(Canvas c,List<Offset> points,Color color,double width){
  if(points.isEmpty)return;
  final p=Path()..moveTo(points.first.dx,points.first.dy);
  for(final point in points.skip(1)){p.lineTo(point.dx,point.dy);}
  c.drawPath(p,Paint()..color=color..style=PaintingStyle.stroke
    ..strokeWidth=width..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round);
}

void drawBone(Canvas c,Offset a,Offset b,double r1,double r2,Color color){
  final v=b-a,l=math.max(.001,v.distance),n=Offset(-v.dy/l,v.dx/l);
  final p=Path()..addPolygon([a+n*r1,b+n*r2,b-n*r2,a-n*r1],true);
  c.drawPath(p,Paint()..color=color);
  c.drawPath(p,Paint()..color=const Color(0xff101822)
    ..style=PaintingStyle.stroke..strokeWidth=1.6);
  drawLine(c,[a+n*(r1*.6),b+n*(r2*.5)],const Color(0xff56505a),2);
  c.drawCircle(b,r2,Paint()..color=color);
}

/// Paints in the source SVG's 720x840 art coordinates.
/// The ground anchor is (275,777). Use the same transform for the lamp anchor.
void drawGuard(Canvas c,CharacterMotion m,VectorArt art,{bool debug=false,bool showBeam=true}){
  final p=m.guardPose();
  void leg(Offset h,Offset k,Offset a,Offset f,String id,double originX,Color color){
    drawBone(c,h,k,13,12,color);drawBone(c,k,a,11,9,color);
    c.save();c.translate(f.dx-originX,f.dy-777);art.draw(c,id);c.restore();
  }
  leg(p.backHip,p.backKnee,p.backAnkle,p.backFoot,'boot-back',224,const Color(0xff252631));
  leg(p.frontHip,p.frontKnee,p.frontAnkle,p.frontFoot,'boot-front',350,const Color(0xff38313d));
  c.save();c.translate(0,p.bob);
  c.save();c.translate(192,350);c.rotate(-.06*math.sin(tau*m.phase)*m.weight);
  c.translate(-192,-350);art.draw(c,'arm-back');c.restore();
  for(final id in ['torso','belt-and-pouch','coat-wear']){art.draw(c,id);}
  c.save();c.translate(251,459);c.rotate(.08*math.sin(tau*m.phase+.5)*m.weight);
  c.translate(-251,-459);art.draw(c,'keys');c.restore();
  c.save();c.translate(305,282);c.rotate(.012*math.sin(tau*m.phase)*m.weight);
  c.translate(-305,-282);art.draw(c,'head');c.restore();
  drawBone(c,p.shoulder,p.elbow,17,15,const Color(0xff292c38));
  drawBone(c,p.elbow,p.wrist,14,11,const Color(0xff333742));
  c.save();c.translate(p.shift.dx,p.shift.dy);art.draw(c,'staff');art.draw(c,'hand-front');
  c.save();c.translate(m.lampPivot.dx,m.lampPivot.dy);c.rotate(m.lampAngle);
  c.translate(-m.lampPivot.dx,-m.lampPivot.dy);art.draw(c,'lantern');c.restore();c.restore();
  if(showBeam){
   final beam=Path()..moveTo(p.lamp.dx,p.lamp.dy)
    ..lineTo(p.lamp.dx+260,p.lamp.dy-130)..lineTo(p.lamp.dx+260,p.lamp.dy+130)..close();
  c.drawPath(beam,Paint()..shader=Gradient.linear(p.lamp,p.lamp+const Offset(250,0),
    [const Color(0x33bfe0be),const Color(0x00bfe0be)]));
  }
  c.restore();
  if(debug){
    drawLine(c,[p.backHip,p.backKnee,p.backAnkle],const Color(0xfffa9a73),3);
    drawLine(c,[p.frontHip,p.frontKnee,p.frontAnkle],const Color(0xff8de5d4),3);
    final bob=Offset(0,p.bob);
    drawLine(c,[p.shoulder+bob,p.elbow+bob,p.wrist+bob],const Color(0xffffcf7d),3);
    for(final f in [p.backFoot,p.frontFoot]){
      drawLine(c,[f-const Offset(12,0),f+const Offset(12,0)],const Color(0xffffcf7d),4);
    }
    c.drawCircle(p.lamp+bob,6,Paint()..color=const Color(0xffffcf7d));
  }
}

/// Shares the exact art-space lamp transform used for the visible lamp.
/// worldFeet = Guard.position + Offset(gw/2, gh) for the existing project.
Offset guardLampWorld(CharacterMotion motion,Offset worldFeet){
  final p=motion.guardPose();
  final local=(p.lamp+Offset(0,p.bob)-const Offset(275,777))*motion.gameScale;
  return worldFeet+Offset(local.dx*motion.facing,local.dy);
}

/// Paints Medusa in the 760x820 source art coordinates.
void drawMedusa(Canvas c,CharacterMotion m,VectorArt art,{bool debug=false}){
  for(var i=0;i<9;i++){
    final s=m.snake(i),p=Path()..addPolygon(s.outline,true);
    c.drawPath(p,Paint()..color=hex(m.art['snakeColors'][i]));
    c.drawPath(p,Paint()..color=const Color(0xff263b39)
      ..style=PaintingStyle.stroke..strokeWidth=2);
    drawLine(c,s.samples,const Color(0xff91aa8b),2.5);
    c.save();c.translate(s.tip.dx,s.tip.dy);c.rotate(s.angle);
    art.draw(c,'snake-${(i+1).toString().padLeft(2,'0')}-head');c.restore();
    if(debug){
      drawLine(c,s.samples,const Color(0xffeabf79),1);
      c.drawCircle(s.samples.first,5,Paint()..color=const Color(0xffffd18c));
    }
  }
  for(final id in ['stone-base','face-planes','ears','eye-sockets']){art.draw(c,id);}
  final e=limit(m.eyes,0,1);
  // Only the eyelid crossfade uses an offscreen layer; static art is cached.
  if(e<1){
    c.saveLayer(const Rect.fromLTRB(280,360,450,430),Paint()..color=Color.fromRGBO(255,255,255,1-e));
    art.draw(c,'eyes-closed');c.restore();
  }
  if(e>0){
    c.save();c.translate(0,392);c.scale(1,math.max(.02,e));c.translate(0,-392);
    art.draw(c,'eyes-awake');c.restore();
  }
  for(final id in ['nose','mouth','carved-hair-band','temple-curls','cracks','medusa-face-texture','stone-edge-light']){
    art.draw(c,id);
  }
}
