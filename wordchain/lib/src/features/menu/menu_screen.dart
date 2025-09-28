import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _nodes;
  late final List<(int a, int b)> _edges;

  static const _kPhotoBlue = Color(0xFF6DC7D1);
  static const _kPlatinum = Color(0xFFE2F3F4);

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: false);

    // генерим лёгкий граф для декоративной анимации
    final rnd = Random(42);
    _nodes = List.generate(30, (_) {
      return Offset(rnd.nextDouble(), rnd.nextDouble()); // нормализованные 0..1
    });

    _edges = [];
    for (int i = 0; i < _nodes.length; i++) {
      // по 2–3 случайных связи на узел
      for (int k = 0; k < 2; k++) {
        final j = rnd.nextInt(_nodes.length);
        if (j != i) _edges.add((i, j));
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const onBlue = Color(0xFF16282E);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('WordChain'),
        toolbarHeight: 72,
        titleTextStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ) ??
            const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                children: [
                  _HeroGraphCard(
                    photoBlue: _kPhotoBlue,
                    platinum: _kPlatinum,
                    isDark: isDark,
                    animation: _ctrl,
                    nodes: _nodes,
                    edges: _edges,
                  ),
                  const SizedBox(height: 26),
                  _bigBtn(context, 'Play', onBlue,
                      () => Navigator.pushNamed(context, '/game')),
                  const SizedBox(height: 14),
                  _bigBtn(context, 'Gallery', onBlue,
                      () => Navigator.pushNamed(context, '/gallery')),
                  const SizedBox(height: 14),
                  _bigBtn(context, 'Achievements', onBlue,
                      () => Navigator.pushNamed(context, '/achievements')),
                  const SizedBox(height: 14),
                  _bigBtn(context, 'Statistics', onBlue,
                      () => Navigator.pushNamed(context, '/stats')),
                  const SizedBox(height: 14),
                  _bigBtn(context, 'Settings', onBlue,
                      () => Navigator.pushNamed(context, '/settings')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bigBtn(
      BuildContext ctx, String label, Color textColor, VoidCallback onTap) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 28,
              offset: const Offset(0, 10)),
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
        borderRadius: BorderRadius.circular(28),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: _kPhotoBlue,
            foregroundColor: textColor,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _HeroGraphCard extends StatelessWidget {
  final Color photoBlue;
  final Color platinum;
  final bool isDark;
  final Animation<double> animation;
  final List<Offset> nodes;
  final List<(int a, int b)> edges;

  const _HeroGraphCard({
    required this.photoBlue,
    required this.platinum,
    required this.isDark,
    required this.animation,
    required this.nodes,
    required this.edges,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 14 / 9,
      child: Container(
        decoration: BoxDecoration(
          // color: photoBlue,
          borderRadius: BorderRadius.circular(28),
          // boxShadow: [
          //   BoxShadow(
          //       color: Colors.black.withOpacity(0.18),
          //       blurRadius: 30,
          //       offset: const Offset(0, 14)),
          //   BoxShadow(
          //       color: Colors.black.withOpacity(0.12),
          //       blurRadius: 10,
          //       offset: const Offset(0, 4)),
          // ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return CustomPaint(
                painter: _GraphPainter(
                  progress: animation.value,
                  nodes: nodes,
                  edges: edges,
                  lineColor: Color.lerp(
                      photoBlue, Colors.black, isDark ? 0.45 : 0.38)!,
                  nodeColor: Color.lerp(
                      photoBlue, Colors.white, isDark ? 0.10 : 0.05)!,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final double progress;
  final List<Offset> nodes;
  final List<(int a, int b)> edges;
  final Color lineColor;
  final Color nodeColor;

  _GraphPainter({
    required this.progress,
    required this.nodes,
    required this.edges,
    required this.lineColor,
    required this.nodeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pLine = Paint()
      ..color = lineColor.withOpacity(0.75)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pNode = Paint()
      ..color = nodeColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final inset = 24.0;
    Offset map(Offset n) => Offset(
          lerpDouble(inset, size.width - inset, n.dx)!,
          lerpDouble(inset, size.height - inset, n.dy)!,
        );

    for (int i = 0; i < edges.length; i++) {
      final (a, b) = edges[i];
      final o1 = map(nodes[a]);
      final o2 = map(nodes[b]);

      final local = ((progress * 2) - i * 0.02).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final end = Offset(
        o1.dx + (o2.dx - o1.dx) * local,
        o1.dy + (o2.dy - o1.dy) * local,
      );
      canvas.drawLine(
          o1, end, pLine..color = lineColor.withOpacity(0.35 + 0.45 * local));
    }

    for (final n in nodes) {
      final o = map(n);
      canvas.drawCircle(o, 4.5, pNode);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) =>
      old.progress != progress ||
      old.nodes != nodes ||
      old.edges != edges ||
      old.lineColor != lineColor ||
      old.nodeColor != nodeColor;
}
