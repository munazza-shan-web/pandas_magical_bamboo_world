import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common.dart';
import 'game.dart';
import 'legal.dart';
import 'panda_art.dart';

void showHelp(BuildContext context) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    backgroundColor: cream,
    title: const Text('How to play', style: TextStyle(color: forest, fontWeight: FontWeight.w900)),
    content: const SingleChildScrollView(child: Text(
      '• Adventure: tap to jump, tap again in the air for a double jump!\n'
      '• Collect bamboo 🎋 and stars ⭐. Avoid rocks and logs. You have 3 hearts.\n'
      '• Reach the end to win 1–3 stars and unlock the next adventure.\n'
      '• Panda Home: feed Bao, play, and tuck Bao into bed. Tap Bao for cuddles.\n'
      '• Earn badges, and unlock a bow and a crown.\n'
      '• Keyboard: Space or Up arrow to jump.',
      style: TextStyle(color: forest, height: 1.5),
    )),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it!'))],
  ),
);

void showSettings(BuildContext context) {
  Widget tile(IconData i, String t, VoidCallback f) => ListTile(leading: Icon(i, color: forest), title: Text(t, style: const TextStyle(color: forest)), onTap: f);
  void open(BuildContext ctx, Widget page) { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => page)); }
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: cream,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(child: StatefulBuilder(builder: (ctx, set) => SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Settings', style: TextStyle(fontSize: 21, color: forest, fontWeight: FontWeight.w900)),
        SwitchListTile(
          title: const Text('Sound & vibration', style: TextStyle(color: forest)),
          value: save.sound,
          onChanged: (v) { set(() => save.sound = v); save.store(); },
        ),
        tile(Icons.help_outline, 'How to play', () { Navigator.pop(ctx); showHelp(context); }),
        tile(Icons.restart_alt, 'Reset progress', () {
          Navigator.pop(ctx);
          showDialog<void>(context: context, builder: (d) => AlertDialog(
            backgroundColor: cream,
            title: const Text('Reset everything?'),
            content: const Text('This erases your stars, bamboo, badges and Bao\'s stats.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
              TextButton(onPressed: () { save.reset(); Navigator.pop(d); }, child: const Text('Reset')),
            ],
          ));
        }),
        tile(Icons.privacy_tip_outlined, 'Privacy Policy', () => open(ctx, const LegalPage(title: 'Privacy Policy', asset: 'legal/privacy_policy.md'))),
        tile(Icons.description_outlined, 'Terms & Conditions', () => open(ctx, const LegalPage(title: 'Terms & Conditions', asset: 'legal/terms_and_conditions.md'))),
        tile(Icons.mail_outline, 'Contact support', () => open(ctx, const ContactPage())),
      ]),
    ))),
  );
}

// ───────────────────────── Menu ─────────────────────────
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuState();
}

class _MenuState extends TickState<MenuScreen> {
  @override
  void initState() {
    super.initState();
    if (!save.seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        save.seen = true;
        save.store();
        showHelp(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        CustomPaint(painter: _MenuPainter(t)),
        SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(children: [
              chip('🎋', '${save.bamboo}'),
              const SizedBox(width: 8),
              chip('⭐', '${save.starSum}'),
              const Spacer(),
              Material(color: Colors.white, borderRadius: BorderRadius.circular(14), child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => showSettings(context),
                child: const SizedBox(width: 40, height: 40, child: Icon(Icons.settings, color: forest)),
              )),
            ]),
          ),
          const SizedBox(height: 8),
          const Text("PANDA'S", style: TextStyle(fontSize: 12, letterSpacing: 4, color: forest, fontWeight: FontWeight.w900)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('MAGICAL BAMBOO WORLD', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, color: forest, fontWeight: FontWeight.w900, height: 1.1)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
              pill('ADVENTURE', const Color(0xFFCDE8B8), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelSelect())), icon: '🏃'),
              pill('PANDA HOME', const Color(0xFFFFD9A8), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen())), icon: '🏡'),
              pill('BADGES', const Color(0xFFD6E9FF), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesScreen())), icon: '🏅'),
            ]),
          ),
        ])),
      ]),
    );
  }
}

class _MenuPainter extends CustomPainter {
  final double t;
  _MenuPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    paintWorld(c, s, themes[0], t * s.height * .5, t);
    final u = math.min(s.height * .14, s.width * .2);
    drawPanda(c, Offset(s.width * .42, s.height * .8), u, Pose.run, t, hat: save.hat);
  }
  @override
  bool shouldRepaint(covariant _MenuPainter old) => true;
}

// ───────────────────────── Level select ─────────────────────────
class LevelSelect extends StatefulWidget {
  const LevelSelect({super.key});
  @override
  State<LevelSelect> createState() => _LevelSelectState();
}

class _LevelSelectState extends State<LevelSelect> {
  @override
  Widget build(BuildContext context) {
    final next = save.lv.indexWhere((s) => s == 0);
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Choose an adventure'), backgroundColor: cream, foregroundColor: forest),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (ctx, i) {
          final th = themes[i];
          final locked = i > 0 && save.lv[i - 1] == 0;
          final fg = th.night > .5 ? Colors.white : forest;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: locked ? null : () async {
                sfx();
                await Navigator.push(context, MaterialPageRoute(builder: (_) => RunnerScreen(level: i)));
                if (mounted) setState(() {});
              },
              child: Opacity(opacity: locked ? .5 : 1, child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: th.sky),
                  borderRadius: BorderRadius.circular(22),
                  border: i == next ? Border.all(color: coral, width: 3) : null,
                ),
                child: Row(children: [
                  CircleAvatar(backgroundColor: forest, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(th.name, style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w900)),
                    Text(locked ? 'Finish the previous adventure to unlock' : i == next ? 'Up next! Continue your journey' : 'Replay for 3 stars', style: TextStyle(color: fg, fontSize: 12)),
                  ])),
                  if (locked)
                    Icon(Icons.lock, color: fg)
                  else
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      for (var k = 0; k < 3; k++) Icon(k < save.lv[i] ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFFE5A52F)),
                    ]),
                ]),
              )),
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────── Panda Home ─────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends TickState<HomeScreen> {
  Pose pose = Pose.idle;
  double act = 0, saveT = 5, warnT = 6;
  bool sleeping = false, playing = false;
  String msg = 'Bao is happy to see you!';
  final hearts = <List<double>>[]; // x, y (0..1), life

  @override
  void update(double dt) {
    final sv = save;
    if (sleeping) {
      sv.rest = cl(sv.rest + 3 * dt);
      sv.fed = cl(sv.fed - .02 * dt);
      if (sv.rest >= 100) { sleeping = false; msg = 'Bao woke up refreshed!'; }
    } else {
      sv.fed = cl(sv.fed - .10 * dt);
      sv.rest = cl(sv.rest - .05 * dt);
      sv.fun = cl(sv.fun - .08 * dt);
    }
    if (act > 0) {
      act -= dt;
      if (act <= 0) { pose = Pose.idle; playing = false; }
    }
    for (final h in hearts) { h[1] -= .2 * dt; h[2] -= dt; }
    hearts.removeWhere((h) => h[2] <= 0);
    saveT -= dt;
    if (saveT <= 0) { sv.store(); saveT = 5; }
    warnT -= dt;
    if (warnT <= 0 && !sleeping && act <= 0) {
      warnT = 8;
      if (sv.fed < 25) {
        msg = 'Bao is hungry! Feed some bamboo 🎋';
      } else if (sv.rest < 25) {
        msg = 'Bao is sleepy... time for a nap 💤';
      } else if (sv.fun < 25) {
        msg = 'Bao wants to play! ⚽';
      }
    }
  }

  @override
  void dispose() {
    save.store();
    super.dispose();
  }

  void _eat() {
    if (save.bamboo <= 0) { setState(() => msg = 'No bamboo left! Collect some in Adventure.'); return; }
    setState(() {
      sleeping = false; save.bamboo--; save.fed = cl(save.fed + 25); save.meals++;
      pose = Pose.eat; act = 2.4; playing = false; msg = 'Crunch crunch! Bao loves bamboo!';
    });
    save.store();
  }

  void _play() => setState(() {
    if (sleeping) { msg = 'Shh... Bao is sleeping. Wake Bao first!'; return; }
    if (save.rest < 12) { msg = 'Bao is too sleepy to play.'; return; }
    pose = Pose.run; act = 3; playing = true;
    save.fun = cl(save.fun + 25); save.rest = cl(save.rest - 6);
    msg = 'Wheee! Bao is playing with the ball!';
  });

  void _sleep() {
    setState(() {
      sleeping = !sleeping;
      if (sleeping) { save.naps++; act = 0; playing = false; msg = 'Sweet dreams, Bao...'; } else { msg = 'Bao woke up!'; }
    });
    save.store();
  }

  void _pet(Offset p, Size s) {
    if (sleeping) { setState(() => msg = 'Shh... Bao is sleeping'); return; }
    sfx();
    save.fun = cl(save.fun + 3);
    for (var i = 0; i < 3; i++) { hearts.add([p.dx / s.width + (i - 1) * .04, p.dy / s.height, 1]); }
    msg = 'Bao loves cuddles! 💕';
  }

  Widget _meter(String icon, double v, Color col) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Text(icon),
      const SizedBox(width: 6),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: v / 100, minHeight: 9, backgroundColor: const Color(0xFFE9E2D5), color: col))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    const hatNames = ['No hat', 'Bow', 'Crown'];
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
          child: Row(children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: forest)),
            const Text('Panda Home', style: TextStyle(color: forest, fontSize: 20, fontWeight: FontWeight.w900)),
            const Spacer(),
            chip('🎋', '${save.bamboo}'),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(children: [
            Expanded(child: _meter('🍽', save.fed, const Color(0xFF6FBF73))),
            const SizedBox(width: 8),
            Expanded(child: _meter('💤', save.rest, const Color(0xFF7F8FE8))),
            const SizedBox(width: 8),
            Expanded(child: _meter('⚽', save.fun, const Color(0xFFFFB04D))),
          ]),
        ),
        Expanded(child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: ClipRRect(borderRadius: BorderRadius.circular(26), child: Stack(fit: StackFit.expand, children: [
            LayoutBuilder(builder: (ctx, b) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _pet(d.localPosition, b.biggest),
              child: CustomPaint(size: b.biggest, painter: _HomePainter(this)),
            )),
            Positioned(left: 12, right: 12, bottom: 10, child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(color: forest.withOpacity(.82), borderRadius: BorderRadius.circular(30)),
              child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ))),
          ])),
        )),
        Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
          for (var h = 0; h < 3; h++)
            ChoiceChip(
              label: Text(save.hatUnlocked(h) ? hatNames[h] : '🔒 ${hatNames[h]}'),
              selected: save.hat == h,
              onSelected: save.hatUnlocked(h) ? (_) { save.hat = h; save.store(); } : null,
            ),
        ]),
        Text('Bow: collect 20 bamboo  •  Crown: earn 8 stars', style: TextStyle(color: forest.withOpacity(.6), fontSize: 11)),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            pill('EAT', const Color(0xFFCDE8B8), _eat, icon: '🎋', pad: 14),
            pill('PLAY', const Color(0xFFFFD1C5), _play, icon: '⚽', pad: 14),
            pill(sleeping ? 'WAKE' : 'SLEEP', const Color(0xFFD9D8F5), _sleep, icon: sleeping ? '☀' : '💤', pad: 14),
          ]),
        ),
      ])),
    );
  }
}

class _HomePainter extends CustomPainter {
  final _HomeState s;
  _HomePainter(this.s);
  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height, gy = h * .78;
    paintWorld(c, size, themes[s.sleeping ? 3 : 0], 0, s.t);
    final u = math.min(h * .14, w * .17);
    final bx = w * .42, by = gy + h * .05;
    c.drawOval(Rect.fromCenter(center: Offset(bx, by), width: u * 4.2, height: u * .7), fill(const Color(0xFFE88A7A)));
    c.drawOval(Rect.fromCenter(center: Offset(bx, by - 3), width: u * 3.6, height: u * .5), fill(const Color(0xFFF4A99B)));
    for (var k = 0; k < math.min(save.bamboo, 8); k++) {
      final x = w * .12 + k * 7.0;
      c.drawRRect(RRect.fromLTRBR(x, gy + h * .02 - 26, x + 6, gy + h * .06, const Radius.circular(3)), fill(const Color(0xFF4FA14F)));
    }
    final ballY = s.playing ? gy + h * .05 - math.sin(s.t * 6).abs() * h * .25 : gy + h * .06;
    c.drawCircle(Offset(w * .78, ballY - 12), 13, fill(const Color(0xFFFF9C79)));
    c.drawArc(Rect.fromCircle(center: Offset(w * .78, ballY - 12), radius: 13), s.t * 4, 2.2, false, Paint()..color = Colors.white.withOpacity(.7)..style = PaintingStyle.stroke..strokeWidth = 2);
    final mood = (save.fed + save.rest + save.fun) / 3;
    final hop = s.playing && !s.sleeping ? math.sin(s.t * 8).abs() * h * .08 : 0.0;
    final pose = s.sleeping ? Pose.sleep : s.act > 0 ? s.pose : Pose.idle;
    drawPanda(c, Offset(bx, by - hop - 4), u, pose, s.t, hat: save.hat, sad: mood < 35 && !s.sleeping);
    for (final hr in s.hearts) {
      drawText(c, '♥', Offset(hr[0] * w, hr[1] * h), 22, coral.withOpacity(hr[2].clamp(0.0, 1.0)));
    }
  }
  @override
  bool shouldRepaint(covariant _HomePainter old) => true;
}

// ───────────────────────── Badges ─────────────────────────
class Medal {
  final String icon, title, desc;
  final bool Function() ok;
  Medal(this.icon, this.title, this.desc, this.ok);
}

final medals = <Medal>[
  Medal('🎋', 'First Crunch', 'Collect your first bamboo', () => save.total >= 1),
  Medal('🧺', 'Bamboo Collector', 'Collect 50 bamboo', () => save.total >= 50),
  Medal('🏆', 'Bamboo Boss', 'Collect 300 bamboo', () => save.total >= 300),
  Medal('🍽', 'Yummy Tummy', 'Feed Bao 10 times', () => save.meals >= 10),
  Medal('😴', 'Sleepyhead', 'Put Bao to bed 3 times', () => save.naps >= 3),
  Medal('🌲', 'Forest Hero', 'Finish adventure 1', () => save.lv[0] > 0),
  Medal('🗺', 'Explorer', 'Finish all 5 adventures', () => save.lv.every((s) => s > 0)),
  Medal('⭐', 'Star Collector', 'Earn 10 stars', () => save.starSum >= 10),
  Medal('💎', 'Perfect Panda', 'Get 3 stars on any adventure', () => save.lv.any((s) => s == 3)),
];

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final got = medals.where((m) => m.ok()).length;
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: Text('Badges  $got / ${medals.length}'), backgroundColor: cream, foregroundColor: forest),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(14),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
        children: [
          for (final m in medals)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: m.ok() ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(20),
                border: m.ok() ? Border.all(color: gold, width: 3) : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Opacity(opacity: m.ok() ? 1 : .3, child: Text(m.icon, style: const TextStyle(fontSize: 40))),
                const SizedBox(height: 6),
                Text(m.ok() ? m.title : '🔒 ${m.title}', textAlign: TextAlign.center, style: const TextStyle(color: forest, fontWeight: FontWeight.w900)),
                Text(m.desc, textAlign: TextAlign.center, style: TextStyle(color: forest.withOpacity(.7), fontSize: 11)),
              ]),
            ),
        ],
      ),
    );
  }
}
