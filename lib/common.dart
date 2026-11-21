import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const forest = Color(0xFF173D31);
const leaf = Color(0xFF78B96A);
const cream = Color(0xFFFFF5DF);
const coral = Color(0xFFFF9C79);
const gold = Color(0xFFFFC94D);

Paint fill(Color c) => Paint()..color = c;
double cl(double v) => v.clamp(0.0, 100.0).toDouble();
double wrap(double v, double m) => ((v % m) + m) % m;

/// Everything the game remembers, saved on the device only.
class Save {
  int bamboo = 0, total = 0, meals = 0, naps = 0, hat = 0;
  List<int> lv = [0, 0, 0, 0, 0];
  double fed = 80, rest = 80, fun = 80;
  bool sound = true, seen = false;
  SharedPreferences? _p;

  int get starSum => lv.fold(0, (a, b) => a + b);
  bool hatUnlocked(int h) => h == 0 || (h == 1 && total >= 20) || (h == 2 && starSum >= 8);

  double _dec(double v, double mins) => v <= 15 ? v : math.max(15.0, v - mins * .3);

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _p = p;
      bamboo = p.getInt('bamboo') ?? 0;
      total = p.getInt('total') ?? 0;
      meals = p.getInt('meals') ?? 0;
      naps = p.getInt('naps') ?? 0;
      hat = p.getInt('hat') ?? 0;
      sound = p.getBool('sound') ?? true;
      seen = p.getBool('seen') ?? false;
      final l = p.getStringList('lv');
      if (l != null && l.length == 5) lv = l.map(int.parse).toList();
      fed = p.getDouble('fed') ?? 80;
      rest = p.getDouble('rest') ?? 80;
      fun = p.getDouble('fun') ?? 80;
      final last = p.getInt('last');
      if (last != null) {
        final mins = (DateTime.now().millisecondsSinceEpoch - last) / 60000;
        fed = _dec(fed, mins);
        rest = _dec(rest, mins);
        fun = _dec(fun, mins);
      }
    } catch (_) {}
  }

  void store() {
    final p = _p;
    if (p == null) return;
    try {
      p.setInt('bamboo', bamboo);
      p.setInt('total', total);
      p.setInt('meals', meals);
      p.setInt('naps', naps);
      p.setInt('hat', hat);
      p.setBool('sound', sound);
      p.setBool('seen', seen);
      p.setStringList('lv', lv.map((e) => '$e').toList());
      p.setDouble('fed', fed);
      p.setDouble('rest', rest);
      p.setDouble('fun', fun);
      p.setInt('last', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  void reset() {
    bamboo = total = meals = naps = hat = 0;
    lv = [0, 0, 0, 0, 0];
    fed = rest = fun = 80;
    store();
  }
}

final save = Save();

void sfx([bool heavy = false]) {
  if (!save.sound) return;
  SystemSound.play(SystemSoundType.click);
  if (heavy) {
    HapticFeedback.mediumImpact();
  } else {
    HapticFeedback.selectionClick();
  }
}

/// Screens that animate every frame extend this; [t] is seconds, [update] gets dt.
abstract class TickState<T extends StatefulWidget> extends State<T> with SingleTickerProviderStateMixin {
  double t = 0;
  Duration _prev = Duration.zero;
  late final Ticker _tk;
  void update(double dt) {}

  @override
  void initState() {
    super.initState();
    _tk = createTicker((d) {
      final dt = math.min(.05, (d - _prev).inMicroseconds / 1e6);
      _prev = d;
      t += dt;
      update(dt);
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _tk.dispose();
    super.dispose();
  }
}

void drawText(Canvas c, String s, Offset o, double size, Color col) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontSize: size, color: col, fontWeight: FontWeight.w900)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
}

void drawStar(Canvas c, Offset o, double r, Color color) {
  final path = Path();
  for (int i = 0; i < 10; i++) {
    final rad = i.isEven ? r : r * .45;
    final a = -math.pi / 2 + i * math.pi / 5;
    final x = o.dx + math.cos(a) * rad, y = o.dy + math.sin(a) * rad;
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  c.drawPath(path, fill(color));
}

class WorldTheme {
  final String name;
  final List<Color> sky;
  final Color hillA, hillB, ground, dark, stalk;
  final double night;
  const WorldTheme(this.name, this.sky, this.hillA, this.hillB, this.ground, this.dark, this.stalk, this.night);
}

const themes = [
  WorldTheme('Sunny Grove', [Color(0xFF8FD3E8), Color(0xFFDFF3C7), Color(0xFFFFF0C4)], Color(0xFF86BE83), Color(0xFF6CA978), Color(0xFF75B96C), Color(0xFF4D9659), Color(0xFF3F9B58), 0),
  WorldTheme('Golden Afternoon', [Color(0xFFF9C784), Color(0xFFFFE3A3), Color(0xFFFFF3D0)], Color(0xFFC9B36A), Color(0xFFA8A25F), Color(0xFF9DB45A), Color(0xFF7B9A4A), Color(0xFF6F9A3F), 0),
  WorldTheme('Sunset Ridge', [Color(0xFF6C5B9E), Color(0xFFE98A7B), Color(0xFFFFD5A0)], Color(0xFF5E7A8A), Color(0xFF4C6A7A), Color(0xFF5E9E6A), Color(0xFF3E7E55), Color(0xFF2F7D52), .15),
  WorldTheme('Moonlit Forest', [Color(0xFF14264F), Color(0xFF2B4C7E), Color(0xFF5A7FA8)], Color(0xFF2E5A6B), Color(0xFF244B5C), Color(0xFF2F6E57), Color(0xFF1F5545), Color(0xFF2A7A5A), 1),
  WorldTheme('Misty Peaks', [Color(0xFFB8D4E3), Color(0xFFDCE9F0), Color(0xFFF5F8FA)], Color(0xFF9DB8C6), Color(0xFF86A4B5), Color(0xFF8FBF9B), Color(0xFF6BA27F), Color(0xFF5FA37A), 0),
];

void _ridge(Canvas c, Size s, double base, double amp, double freq, double off, Color col) {
  final p = Path()..moveTo(0, s.height);
  for (double x = 0; x <= s.width + 10; x += 10) {
    p.lineTo(x, base + math.sin((x + off) * freq) * amp + math.sin((x + off) * freq * 2.3) * amp * .4);
  }
  p.lineTo(s.width + 10, s.height);
  p.close();
  c.drawPath(p, fill(col));
}

void _stalks(Canvas c, Size s, WorldTheme th, double off, double gap, double wd, double alpha, double gy) {
  final n = (s.width / gap).ceil() + 3;
  final per = n * gap;
  for (var i = 0; i < n; i++) {
    final x = wrap(i * gap - off, per) - gap;
    final top = s.height * ((i * 29 % 15) / 100);
    c.drawRRect(RRect.fromLTRBR(x, top, x + wd, gy, Radius.circular(wd / 2)), fill(th.stalk.withOpacity(alpha)));
    final np = Paint()..color = Colors.white.withOpacity(.25 * alpha)..strokeWidth = 2;
    for (double y = top + s.height * .1; y < gy; y += s.height * .13) {
      c.drawLine(Offset(x, y), Offset(x + wd, y), np);
    }
    c.save();
    c.translate(x + wd / 2, top + s.height * (.12 + (i * 17 % 20) / 100));
    c.rotate(i.isEven ? -.7 : .7);
    c.drawOval(Rect.fromLTWH(0, -4, wd * 3.2, 8), fill(th.stalk.withOpacity(alpha * .9)));
    c.restore();
  }
}

/// Scrolling parallax bamboo forest. [sc] is the scroll in pixels, ground line is at 78% height.
void paintWorld(Canvas c, Size s, WorldTheme th, double sc, double t) {
  final w = s.width, h = s.height, gy = h * .78;
  final rect = Offset.zero & s;
  c.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: th.sky).createShader(rect));
  if (th.night > .5) {
    for (var i = 0; i < 28; i++) {
      final tw = .5 + .5 * math.sin(t * 3 + i * 1.7);
      c.drawCircle(Offset(w * ((i * 37 % 100) / 100), h * (.02 + (i * 53 % 40) / 100)), 1.6, fill(Colors.white.withOpacity(th.night * (.35 + .6 * tw))));
    }
    c.drawCircle(Offset(w * .8, h * .17), h * .07, fill(const Color(0xFFF4F1DE)));
    c.drawCircle(Offset(w * .8 + h * .03, h * .17 - h * .015), h * .06, fill(th.sky[0]));
  } else {
    c.drawCircle(Offset(w * .8, h * .17), h * .11, fill(const Color(0xFFFFE89A).withOpacity(.28)));
    c.drawCircle(Offset(w * .8, h * .17), h * .06, fill(const Color(0xFFFFE89A)));
  }
  for (var i = 0; i < 3; i++) {
    final cx = wrap(i * w / 3 - t * 14, w + 240) - 120, cy = h * (.1 + i * .07);
    final cp = fill(Colors.white.withOpacity(.8 * (1 - th.night * .7)));
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w * .18, height: h * .06), cp);
    c.drawOval(Rect.fromCenter(center: Offset(cx + w * .05, cy - h * .02), width: w * .11, height: h * .05), cp);
  }
  _ridge(c, s, h * .52, h * .07, .006, sc * .1, th.hillA);
  _ridge(c, s, h * .60, h * .06, .009, sc * .2 + 300, th.hillB);
  _stalks(c, s, th, sc * .3, 70, 8, .5, gy * .97);
  _stalks(c, s, th, sc * .6, 150, 16, .85, gy);
  c.drawRect(Rect.fromLTRB(0, gy, w, h), fill(th.ground));
  c.drawRect(Rect.fromLTRB(0, gy + h * .07, w, h), fill(th.dark));
  final gp = Paint()..color = th.dark..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;
  for (var i = 0; i < w / 38 + 3; i++) {
    final x = wrap(i * 38.0 - sc, w + 80) - 40, y = gy + h * .012 * (i % 3);
    c.drawPath(Path()..moveTo(x, y + 8)..quadraticBezierTo(x - 6, y - 4, x - 2, y - 11)..moveTo(x, y + 8)..quadraticBezierTo(x + 7, y - 3, x + 4, y - 12), gp);
  }
  if (th.night > 0) {
    c.drawRect(rect, fill(const Color(0xFF0B1B3A).withOpacity(.25 * th.night)));
    if (th.night > .5) {
      for (var i = 0; i < 14; i++) {
        final fx = w * ((i * .0731 + .03 * math.sin(t * .8 + i)) % 1), fy = h * (.45 + .3 * (i * 37 % 10) / 10 + .03 * math.cos(t + i));
        final a = .5 + .5 * math.sin(t * 3 + i * 2);
        c.drawCircle(Offset(fx, fy), 6, fill(const Color(0xFFFFF59D).withOpacity(a * .25)));
        c.drawCircle(Offset(fx, fy), 2.2, fill(const Color(0xFFFFF59D).withOpacity(a)));
      }
    }
  }
}

Widget chip(String icon, String v) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
  decoration: BoxDecoration(color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(16)),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Text(icon, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 5),
    Text(v, style: const TextStyle(color: forest, fontWeight: FontWeight.w900)),
  ]),
);

Widget pill(String text, Color bg, VoidCallback onTap, {String? icon, double pad = 22}) => Material(
  color: bg,
  elevation: 3,
  borderRadius: BorderRadius.circular(22),
  child: InkWell(
    borderRadius: BorderRadius.circular(22),
    onTap: () { sfx(); onTap(); },
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 13),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) Text(icon, style: const TextStyle(fontSize: 20)),
        if (icon != null) const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: forest, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: .4)),
      ]),
    ),
  ),
);
