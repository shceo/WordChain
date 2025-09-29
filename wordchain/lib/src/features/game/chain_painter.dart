import 'dart:math' as math;
import 'package:flutter/material.dart';

class ChainPainter extends CustomPainter {
  ChainPainter({
    required this.words,
    required this.colors,
    this.growth = 1.0, // 0..1 — насколько дорисована последняя ветвь/узел
  });

  final List<String> words;
  final ColorScheme colors;
  final double growth;

  static const _photoBlue = Color(0xFF6DC7D1);
  static const _nodeFill = Color(0xFF125058); // глубокий тиль
  static const _edgeColor = Color(0xFF56969E); // линия

  @override
  void paint(Canvas canvas, Size size) {
    // фон карточки
    final bgPaint = Paint()..color = colors.surface;
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (words.isEmpty) return;

    // раскладка точек в «естественном» диагональном росте
    final layout = _generateLayout(words);
    final bounds = _layoutBounds(layout);

    const margin = 80.0;
    final width = bounds.width == 0 ? 1 : bounds.width;
    final height = bounds.height == 0 ? 1 : bounds.height;
    final scale = math.max(
      0.2,
      math.min(
        (size.width - margin) / width,
        (size.height - margin) / height,
      ),
    );

    final offset = Offset(
      (size.width - bounds.width * scale) / 2 - bounds.left * scale,
      (size.height - bounds.height * scale) / 2 - bounds.top * scale,
    );

    // центры узлов в координатах канвы
    final centers = layout
        .map((p) => Offset(p.dx * scale + offset.dx, p.dy * scale + offset.dy))
        .toList(growable: false);

    // тексты + радиусы (минимализм, но читаемо)
    final textStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: _photoBlue,
    );

    final painters = <TextPainter>[];
    final radii = <double>[];
    for (final w in words) {
      final tp = TextPainter(
        text: TextSpan(text: w, style: textStyle),
        maxLines: 2,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 220);
      painters.add(tp);
      final r = math.max(tp.width, tp.height) / 2 + 18;
      radii.add(math.max(36, r));
    }

    // кисти
    final edgePaint = Paint()
      ..color = _edgeColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final haloPaint = Paint()
      ..color = const Color(0xFFAEC6C9).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final nodeFill = Paint()..color = _nodeFill;

    final nodeStroke = Paint()
      ..color = const Color(0xFFB0C2C6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // рёбра: все полные, последнее — с анимацией роста
    for (var i = 1; i < centers.length; i++) {
      final p1 = centers[i - 1];
      final p2 = centers[i];

      if (i < centers.length - 1) {
        canvas.drawLine(p1, p2, edgePaint);
      } else {
        final t = growth.clamp(0.0, 1.0);
        final end = Offset(
          p1.dx + (p2.dx - p1.dx) * t,
          p1.dy + (p2.dy - p1.dy) * t,
        );

        canvas.drawLine(p1, end,
            edgePaint..color = _edgeColor.withOpacity(0.35 + 0.65 * t));
      }
    }

    // узлы: мягкое «подрастание» последнего
    for (var i = 0; i < centers.length; i++) {
      final c = centers[i];
      final baseR = radii[i];
      final isLast = i == centers.length - 1;
      final scaleR = isLast ? (0.85 + 0.15 * growth.clamp(0, 1)) : 1.0;
      final r = baseR * scaleR;

      // легкий ореол
      canvas.drawCircle(c, r * 1.12, haloPaint);

      // диск + обводка
      canvas.drawCircle(c, r, nodeFill);
      canvas.drawCircle(c, r, nodeStroke);

      final tp = painters[i];
      tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant ChainPainter old) =>
      old.words != words || old.colors != colors || old.growth != growth;
}

// ——————————————————— helpers ———————————————————

List<Offset> _generateLayout(List<String> words) {
  if (words.isEmpty) return const [];
  final seed = words.join('|').hashCode;
  final rng = math.Random(seed);
  const baseStep = 200.0;

  var current = Offset.zero;
  var currentAngle = rng.nextDouble() * math.pi * 2;
  final positions = <Offset>[current];

  for (var i = 1; i < words.length; i++) {
    var step = baseStep * (0.65 + rng.nextDouble() * 0.7);
    var tries = 0;
    Offset? next;

    // лёгкая «ветвистость», но преимущественно диагональный рост
    while (next == null && tries < 12) {
      final delta = (rng.nextDouble() - 0.5) * (math.pi / 1.2);
      final angle = currentAngle + delta;
      final candidate = Offset(
        current.dx + math.cos(angle) * step,
        current.dy + math.sin(angle) * step,
      );
      next = candidate;
      tries++;
      step *= 0.96;
      currentAngle = angle;
    }
    current = next ?? current.translate(baseStep, baseStep * 0.3);
    positions.add(current);
  }

  return positions;
}

Rect _layoutBounds(List<Offset> positions) {
  if (positions.isEmpty) return const Rect.fromLTWH(0, 0, 1, 1);
  var minX = positions.first.dx, maxX = positions.first.dx;
  var minY = positions.first.dy, maxY = positions.first.dy;
  for (final p in positions.skip(1)) {
    minX = math.min(minX, p.dx);
    maxX = math.max(maxX, p.dx);
    minY = math.min(minY, p.dy);
    maxY = math.max(maxY, p.dy);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
