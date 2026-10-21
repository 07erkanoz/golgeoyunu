// tools/import_nemrut_svg.py tarafından üretildi; elle değiştirmeyin.
// Her parça: SVG koordinatında sol üst köşe ve boyut.
import 'dart:ui';

const nemrutSprites = <String, Rect>{
  'giant_leg_back': Rect.fromLTWH(341.0, 469.0, 116.0, 143.0),
  'giant_shin_back': Rect.fromLTWH(352.0, 578.0, 94.0, 155.0),
  'giant_foot_back': Rect.fromLTWH(342.0, 701.0, 119.0, 78.0),
  'giant_arm_back': Rect.fromLTWH(407.0, 255.0, 100.0, 158.0),
  'giant_forearm_back': Rect.fromLTWH(439.0, 374.0, 88.0, 151.0),
  'giant_hand_back': Rect.fromLTWH(453.0, 484.0, 86.0, 92.0),
  'giant_pelvis': Rect.fromLTWH(226.0, 436.0, 208.0, 125.0),
  'giant_leg_front': Rect.fromLTWH(209.0, 501.0, 129.0, 136.0),
  'giant_shin_front': Rect.fromLTWH(205.0, 609.0, 112.0, 148.0),
  'giant_foot_front': Rect.fromLTWH(172.0, 720.0, 142.0, 85.0),
  'giant_torso': Rect.fromLTWH(200.0, 215.0, 256.0, 265.0),
  'giant_chest_carving': Rect.fromLTWH(235.0, 260.0, 164.0, 113.0),
  'giant_head': Rect.fromLTWH(273.0, 34.0, 130.0, 217.0),
  'giant_arm_front': Rect.fromLTWH(153.0, 265.0, 102.0, 141.0),
  'giant_shoulder_front': Rect.fromLTWH(139.0, 211.0, 123.0, 106.0),
  'giant_shoulder_back': Rect.fromLTWH(396.0, 216.0, 97.0, 90.0),
  'giant_forearm_front': Rect.fromLTWH(138.0, 385.0, 97.0, 152.0),
  'giant_hand_front': Rect.fromLTWH(113.0, 501.0, 102.0, 108.0),
  'zeus_head': Rect.fromLTWH(96.2, 45.0, 353.8, 640.0),
  'antiochos_head': Rect.fromLTWH(111.2, 106.2, 301.2, 568.8),
  'kommagene_head': Rect.fromLTWH(101.2, 83.8, 336.2, 591.2),
  'apollon_head': Rect.fromLTWH(110.0, 42.5, 316.2, 632.5),
  'herakles_head': Rect.fromLTWH(105.0, 50.0, 325.0, 630.0),
  'eagle_head': Rect.fromLTWH(95.0, 121.2, 341.2, 517.5),
  'lion_head': Rect.fromLTWH(70.0, 170.0, 376.2, 475.0),
};
