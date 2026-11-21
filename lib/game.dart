import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'common.dart';
import 'panda_art.dart';

class _Obj {
  _Obj(this.x, this.y, this.kind);
  double x, y;
  final int kind; // 0 rock, 1 log, 2 bamboo, 3 star
}

class _Pop {
  _Pop(this.x, this.y, this.star);
  final double x, y;
  final bool star;
  double life = 1;
}

const goals = [16.0, 22.0, 28.0, 34.0, 40.0];
const speeds = [.55, .6, .65, .7, .75];

class RunnerScreen extends StatefulWidget {
  final int level;
  const RunnerScreen({super.key, required this.level});
  @override
  State<RunnerScreen> createState() => _RunnerState();
}

class _RunnerState extends TickState<RunnerScreen> {
  late int lvl = widget.level;
  double scroll = 0, py = 0, vy = 0, invul = 0, aspect = 1.8, nextSpawn = 1.4;
  int jumps = 0, lives = 3, got = 0;
  String phase = 'ready';
  bool paused = false;
  final objs = <_Obj>[], pops = <_Pop>[];
  final rng = math.Random();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _reset() => setState(() {
    scroll = 0; py = 0; vy = 0; invul = 0; nextSpawn = 1.4; jumps = 0; lives = 3; got = 0;
    phase = 'ready'; paused = false;
    objs.clear();
    pops.clear();
  });

  void _jump() {
    if (paused) return;
    if (phase == 'ready') { phase = 'run'; return; }
    if (phase != 'run') return;
    if (jumps < 2) {
      vy = jumps == 0 ? 1.3 : 1.1;
      jumps++;
      sfx();
    }
  }

  void _spawn(double x) {
    objs.add(_Obj(x, 0, rng.nextBool() ? 0 : 1));
    final star = rng.nextInt(4) == 0;
    for (var i = 0; i < 5; i++) {
      objs.add(_Obj(x - .2 + i * .1, .07 + .2 * math.sin(math.pi * i / 4), star && i == 2 ? 3 : 2));
    }
  }

  void _finish(bool won) {
    phase = won ? 'won' : 'lost';
    save.bamboo += got;
    save.total += got;
    if (won && lives > save.lv[lvl]) save.lv[lvl] = lives;
    save.store();
    sfx(true);
  }

  @override
  void update(double dt) {
    if (phase != 'run' || paused) return;
    scroll += (speeds[lvl] + math.min(.12, scroll * .003)) * dt;
    vy -= 3.4 * dt;
    py += vy * dt;
    if (py <= 0) { py = 0; vy = 0; jumps = 0; }
    if (invul > 0) invul -= dt;
    while (nextSpawn < scroll + aspect + 1) {
      _spawn(nextSpawn);
      nextSpawn += 1.05 + rng.nextDouble() * .7 - lvl * .04;
    }
    final px = scroll + aspect * .22;
    for (final o in List<_Obj>.of(objs)) {
      final dx = (o.x - px).abs();
      if (o.kind <= 1) {
        final w = o.kind == 0 ? .08 : .13, h = o.kind == 0 ? .07 : .06;
        if (invul <= 0 && dx < w / 2 + .04 && py < h - .005) {
          lives--;
          invul = 1.4;
          vy = .9;
          sfx(true);
          if (lives <= 0) { _finish(false); return; }
        }
      } else if (dx < .07 && ((py + .12) - o.y).abs() < .13) {
        objs.remove(o);
        got += o.kind == 3 ? 3 : 1;
        pops.add(_Pop(o.x, o.y, o.kind == 3));
        sfx();
      }
    }
    objs.removeWhere((o) => o.x < scroll - .5);
    for (final p in pops) { p.life -= dt * 1.6; }
    pops.removeWhere((p) => p.life <= 0);
    if (px >= goal) _finish(true);
  }

  double get goal => goals[lvl];

  Widget _bubble(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(color: forest.withOpacity(.85), borderRadius: BorderRadius.circular(24)),
    child: Text(s, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
  );

  Widget _hud() {
    final prog = ((scroll + aspect * .22) / goal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.85), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [for (var i = 0; i < 3; i++) Icon(i < lives ? Icons.favorite : Icons.favorite_border, color: coral, size: 24)]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: prog, minHeight: 12, backgroundColor: Colors.white54, color: gold)),
          )),
          const SizedBox(width: 12),
          chip('🎋', '$got'),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => paused = !paused),
              child: const SizedBox(width: 38, height: 38, child: Icon(Icons.pause_rounded, color: forest)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _overlay() {
    if (phase == 'ready' && !paused) {
      return IgnorePointer(child: Align(alignment: const Alignment(0, .1), child: _bubble('${themes[lvl].name}  •  Tap to start, tap again to jump (twice = double jump!)')));
    }
    final won = phase == 'won';
    final title = paused ? 'Paused' : won ? 'Level complete!' : 'Oh no! Try again';
    final buttons = <Widget>[];
    if (paused) {
      buttons.add(pill('RESUME', const Color(0xFFCDE8B8), () => setState(() => paused = false), icon: '▶', pad: 16));
      buttons.add(pill('QUIT', const Color(0xFFFFD1C5), () => Navigator.pop(context), icon: '🏠', pad: 16));
    } else {
      if (won && lvl < 4) buttons.add(pill('NEXT', const Color(0xFFCDE8B8), () { lvl++; _reset(); }, icon: '➡', pad: 16));
      buttons.add(pill('RETRY', const Color(0xFFFFD9A8), _reset, icon: '🔄', pad: 16));
      buttons.add(pill('MENU', const Color(0xFFD6E9FF), () => Navigator.pop(context), icon: '🏠', pad: 16));
    }
    return Container(
      color: Colors.black54,
      child: Center(child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cream, borderRadius: BorderRadius.circular(28)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: const TextStyle(color: forest, fontSize: 24, fontWeight: FontWeight.w900)),
          if (won) Row(mainAxisSize: MainAxisSize.min, children: [for (var k = 0; k < 3; k++) Icon(k < lives ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFFE5A52F), size: 40)]),
          if (!paused) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Bamboo collected: $got 🎋${won && lvl == 4 ? '\nYou finished every adventure!' : ''}', textAlign: TextAlign.center, style: const TextStyle(color: forest))),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center, children: buttons),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (n, e) {
          if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.space || e.logicalKey == LogicalKeyboardKey.arrowUp)) {
            _jump();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: LayoutBuilder(builder: (ctx, b) {
          aspect = b.maxWidth / b.maxHeight;
          return Stack(fit: StackFit.expand, children: [
            Listener(behavior: HitTestBehavior.opaque, onPointerDown: (_) => _jump(), child: CustomPaint(painter: _RunPainter(this))),
            SafeArea(child: _hud()),
            if (phase != 'run' || paused) _overlay(),
          ]);
        }),
      ),
    );
  }
}

class _RunPainter extends CustomPainter {
  final _RunnerState s;
  _RunPainter(this.s);

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height, gy = h * .78;
    paintWorld(c, size, themes[s.lvl], s.scroll * h, s.t);
    for (final o in s.objs) {
      final x = (o.x - s.scroll) * h;
      if (x < -80 || x > w + 80) continue;
      if (o.kind == 0) {
        _rock(c, x, gy, h);
      } else if (o.kind == 1) {
        _log(c, x, gy, h);
      } else {
        _pick(c, Offset(x, gy - o.y * h), o.kind == 3, h, s.t + o.x * 7);
      }
    }
    for (final p in s.pops) {
      drawText(c, p.star ? '+3' : '+1', Offset((p.x - s.scroll) * h, gy - p.y * h - (1 - p.life) * h * .12), h * .05, Colors.white.withOpacity(p.life));
    }
    final u = h * .1, px = w * .22;
    c.drawOval(Rect.fromCenter(center: Offset(px + u * .1, gy + 3), width: u * 3 * (1 - s.py), height: u * .3), fill(Colors.black.withOpacity(.18)));
    final active = s.phase == 'run';
    final pose = !active ? Pose.idle : (s.py > .004 ? Pose.jump : Pose.run);
    if (!(s.invul > 0 && (s.t * 14).floor().isEven)) {
      drawPanda(c, Offset(px, gy - s.py * h), u, pose, s.t, hat: save.hat, sad: s.phase == 'lost', shadow: false);
    }
  }

  void _rock(Canvas c, double x, double gy, double h) {
    final rw = h * .08, rh = h * .07;
    c.drawOval(Rect.fromLTWH(x - rw / 2, gy - rh, rw, rh * 1.15), fill(const Color(0xFF7C8186)));
    c.drawOval(Rect.fromLTWH(x - rw * .35, gy - rh * .9, rw * .5, rh * .4), fill(const Color(0xFFA6ABB0)));
  }

  void _log(Canvas c, double x, double gy, double h) {
    final lw = h * .13, lh = h * .06;
    c.drawRRect(RRect.fromLTRBR(x - lw / 2, gy - lh, x + lw / 2, gy + 2, Radius.circular(lh / 2)), fill(const Color(0xFF8D5E3B)));
    c.drawOval(Rect.fromLTWH(x + lw / 2 - lh * .75, gy - lh, lh * .9, lh), fill(const Color(0xFFD9A66B)));
    c.drawOval(Rect.fromLTWH(x + lw / 2 - lh * .5, gy - lh * .7, lh * .45, lh * .45), fill(const Color(0xFFB98350)));
  }

  void _pick(Canvas c, Offset o, bool star, double h, double t) {
    final p = o + Offset(0, math.sin(t * 5) * h * .01);
    if (star) {
      c.drawCircle(p, h * .05, fill(gold.withOpacity(.3)));
      drawStar(c, p, h * .035, gold);
    } else {
      final bw = h * .024, bh = h * .07;
      c.drawCircle(p, h * .045, fill(const Color(0xFFB7E08A).withOpacity(.3)));
      c.drawRRect(RRect.fromLTRBR(p.dx - bw / 2, p.dy - bh / 2, p.dx + bw / 2, p.dy + bh / 2, Radius.circular(bw / 2)), fill(const Color(0xFF4FA14F)));
      final np = Paint()..color = const Color(0xFFC6EA9A)..strokeWidth = 2;
      c.drawLine(Offset(p.dx - bw / 2, p.dy - bh * .1), Offset(p.dx + bw / 2, p.dy - bh * .1), np);
      c.drawLine(Offset(p.dx - bw / 2, p.dy + bh * .25), Offset(p.dx + bw / 2, p.dy + bh * .25), np);
      c.drawOval(Rect.fromLTWH(p.dx, p.dy - bh * .45, bw * 1.8, bw * .8), fill(const Color(0xFF6CBB5A)));
    }
  }

  @override
  bool shouldRepaint(covariant _RunPainter old) => true;
}
