import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common.dart';

enum Pose { idle, run, jump, eat, sleep }

const _ink = Color(0xFF22282A);
const _fur = Color(0xFFFFFDF6);
const _farLeg = Color(0xFF14191A);

/// Draws a four-legged side-view giant panda. [base] = ground contact point, [u] = size unit (panda ~2.5u tall).
void drawPanda(Canvas c, Offset base, double u, Pose pose, double t, {int hat = 0, bool sad = false, bool shadow = true}) {
  c.save();
  c.translate(base.dx, base.dy);
  c.scale(u);
  if (shadow) c.drawOval(Rect.fromCenter(center: const Offset(.1, .03), width: 3.0, height: .36), fill(Colors.black.withOpacity(.18)));
  if (pose == Pose.sleep) {
    _sleeping(c, t, hat, u);
    c.restore();
    return;
  }
  final run = pose == Pose.run, air = pose == Pose.jump;
  final ph = t * 14;
  final bob = run ? -math.sin(ph).abs() * .08 : pose == Pose.idle ? math.sin(t * 2.2) * .02 : 0.0;

  double ang(double phase, bool front) {
    if (air) return front ? -.9 : .8;
    return run ? math.sin(ph + phase) * .75 : 0.0;
  }

  void leg(double hx, double a, Color col) {
    c.save();
    c.translate(hx, -.78 + bob);
    c.rotate(a);
    c.drawRRect(RRect.fromLTRBR(-.24, -.1, .24, .8 - bob, const Radius.circular(.24)), fill(col));
    c.restore();
  }

  leg(-.30, ang(math.pi, false), _farLeg);
  leg(.95, ang(0, true), _farLeg);
  c.drawCircle(Offset(-1.04, -1.3 + bob + math.sin(t * 5) * .05), .24, fill(_fur));
  final body = Rect.fromCenter(center: Offset(0, -1.08 + bob), width: 2.1, height: 1.4);
  c.drawOval(body, Paint()..shader = const RadialGradient(center: Alignment(-.3, -.5), radius: 1.0, colors: [_fur, Color(0xFFE2DCCB)]).createShader(body));
  c.save();
  c.clipPath(Path()..addOval(body));
  c.translate(.62, -1.1 + bob);
  c.rotate(.12);
  c.drawOval(Rect.fromCenter(center: Offset.zero, width: .9, height: 2.2), fill(_ink));
  c.restore();
  leg(-.62, ang(0, false), _ink);
  leg(.62, ang(math.pi, true), _ink);

  final chew = pose == Pose.eat ? math.sin(t * 12) * .05 : 0.0;
  final hc = Offset(1.02, -1.62 + bob + (pose == Pose.eat ? .12 : 0.0) + chew + (run ? math.sin(ph) * .03 : 0.0));
  _head(c, hc, t, pose, hat, sad);
  if (pose == Pose.eat) {
    c.save();
    c.translate(1.38, -.78 + bob);
    c.rotate(-.15);
    c.drawRRect(RRect.fromLTRBR(-.09, -.5, .09, .3, const Radius.circular(.09)), fill(const Color(0xFF5DAA55)));
    final np = Paint()..color = const Color(0xFFBFE58F)..strokeWidth = .05;
    for (final y in const [-.25, .05]) {
      c.drawLine(Offset(-.09, y), Offset(.09, y), np);
    }
    c.restore();
    c.drawCircle(Offset(1.3, -.78 + bob), .2, fill(_ink));
  }
  c.restore();
}

void _head(Canvas c, Offset hc, double t, Pose pose, int hat, bool sad) {
  c.save();
  c.translate(hc.dx, hc.dy);
  c.drawCircle(const Offset(-.58, -.58), .27, fill(_ink));
  c.drawCircle(const Offset(.58, -.58), .27, fill(_ink));
  const face = Rect.fromLTRB(-.78, -.78, .78, .78);
  c.drawOval(face, Paint()..shader = const RadialGradient(center: Alignment(-.3, -.4), radius: .95, colors: [_fur, Color(0xFFEBE5D6)]).createShader(face));
  final closed = pose == Pose.eat || pose == Pose.sleep || (t % 3.4) < .12;
  for (final s in const [-1.0, 1.0]) {
    c.save();
    c.translate(s * .30, 0);
    c.rotate(-s * .5);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: .32, height: .46), fill(_ink));
    c.restore();
    final e = Offset(s * .30 + .03, sad ? .04 : 0.0);
    if (closed) {
      c.drawArc(Rect.fromCenter(center: e, width: .16, height: .12), math.pi, math.pi, false,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = .035..strokeCap = StrokeCap.round);
    } else {
      c.drawCircle(e, .085, fill(Colors.white));
      c.drawCircle(e + const Offset(.015, .01), .05, fill(_ink));
      c.drawCircle(e + const Offset(0, -.03), .02, fill(Colors.white));
    }
  }
  c.drawCircle(const Offset(-.5, .22), .09, fill(const Color(0xFFFF9AA2).withOpacity(.4)));
  c.drawCircle(const Offset(.62, .22), .09, fill(const Color(0xFFFF9AA2).withOpacity(.4)));
  c.drawOval(Rect.fromCenter(center: const Offset(.1, .26), width: .56, height: .38), fill(const Color(0xFFF6F1E4)));
  c.drawOval(Rect.fromCenter(center: const Offset(.1, .15), width: .24, height: .15), fill(_ink));
  final mp = Path();
  if (sad) {
    mp.moveTo(-.04, .39);
    mp.quadraticBezierTo(.1, .30, .24, .39);
  } else {
    mp.moveTo(-.04, .30);
    mp.quadraticBezierTo(.1, .42, .24, .30);
  }
  c.drawPath(mp, Paint()..color = _ink..style = PaintingStyle.stroke..strokeWidth = .035..strokeCap = StrokeCap.round);
  if (hat == 1) {
    final bow = fill(const Color(0xFFFF7FA8));
    c.drawPath(Path()..moveTo(0, -.8)..lineTo(-.34, -1.0)..lineTo(-.34, -.62)..close(), bow);
    c.drawPath(Path()..moveTo(0, -.8)..lineTo(.34, -1.0)..lineTo(.34, -.62)..close(), bow);
    c.drawCircle(const Offset(0, -.8), .09, fill(const Color(0xFFFF4F86)));
  } else if (hat == 2) {
    c.drawPath(Path()..moveTo(-.34, -.7)..lineTo(-.38, -1.1)..lineTo(-.17, -.92)..lineTo(0, -1.18)..lineTo(.17, -.92)..lineTo(.38, -1.1)..lineTo(.34, -.7)..close(), fill(gold));
  }
  c.restore();
}

void _sleeping(Canvas c, double t, int hat, double u) {
  final br = math.sin(t * 2) * .03;
  c.drawCircle(const Offset(-1.3, -.7), .22, fill(_fur));
  final body = Rect.fromCenter(center: const Offset(-.1, -.62), width: 2.5, height: 1.15 + br);
  c.drawOval(body, Paint()..shader = const RadialGradient(center: Alignment(-.3, -.5), radius: 1.0, colors: [_fur, Color(0xFFE2DCCB)]).createShader(body));
  c.save();
  c.clipPath(Path()..addOval(body));
  c.translate(.7, -.62);
  c.drawOval(Rect.fromCenter(center: Offset.zero, width: .9, height: 1.8), fill(_ink));
  c.restore();
  c.drawOval(Rect.fromCenter(center: const Offset(.6, -.1), width: .6, height: .34), fill(_ink));
  c.drawOval(Rect.fromCenter(center: const Offset(-.7, -.08), width: .6, height: .32), fill(_ink));
  _head(c, const Offset(1.0, -.8), t, Pose.sleep, hat, false);
  for (var i = 0; i < 3; i++) {
    final k = (t * .5 + i / 3) % 1;
    c.save();
    c.scale(1 / u);
    drawText(c, 'Z', Offset((1.5 + k * .5) * u, (-1.5 - k * 1.1) * u), (.3 + .25 * k) * u, const Color(0xFF5B6FB0).withOpacity(1 - k));
    c.restore();
  }
}
