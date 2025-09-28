import 'dart:math' as math;
import 'package:flutter/material.dart';

class ChainPainter extends CustomPainter {
  ChainPainter({required this.words, required this.colors});

  final List<String> words;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = colors.surface;
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (words.isEmpty) return;

    final layout = _generateLayout(words);
    final bounds = _layoutBounds(layout);
    const margin = 80.0;
    final double width = bounds.width == 0 ? 1 : bounds.width;
    final double height = bounds.height == 0 ? 1 : bounds.height;
    final scale = math.max(
        0.2,
        math.min(
            (size.width - margin) / width, (size.height - margin) / height));
    final offset = Offset(
      (size.width - bounds.width * scale) / 2 - bounds.left * scale,
      (size.height - bounds.height * scale) / 2 - bounds.top * scale,
    );

    final linePaint = Paint()
      ..color = colors.primary.withAlpha((255 * 0.55).round())
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = colors.outline.withAlpha((255 * 0.65).round());

    final fillPaint = Paint();

    final textStyle = TextStyle(
      fontSize: 16,
      color: colors.onPrimaryContainer,
      fontWeight: FontWeight.w600,
    );

    final centers = layout
        .map((p) => Offset(p.dx * scale + offset.dx, p.dy * scale + offset.dy))
        .toList(growable: false);

    final radii = <double>[];
    final painters = <TextPainter>[];

    for (final word in words) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: textStyle),
        maxLines: 2,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 220);
      painters.add(painter);
      final r = math.max(painter.width, painter.height) / 2 + 18;
      radii.add(math.max(36, r));
    }

    for (var i = 1; i < centers.length; i++) {
      canvas.drawLine(centers[i - 1], centers[i], linePaint);
    }

    for (var i = 0; i < centers.length; i++) {
      final center = centers[i];
      final radius = radii[i];
      final isLast = i == centers.length - 1;
      final color = isLast
          ? colors.secondaryContainer
          : colors.primaryContainer.withAlpha((255 * 0.82).round());
      fillPaint.color = color;
      canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(center, radius, borderPaint);

      final painter = painters[i];
      final textOffset =
          Offset(center.dx - painter.width / 2, center.dy - painter.height / 2);
      painter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant ChainPainter oldDelegate) {
    return oldDelegate.words != words || oldDelegate.colors != colors;
  }
}

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
  if (positions.isEmpty) {
    return const Rect.fromLTWH(0, 0, 1, 1);
  }
  var minX = positions.first.dx;
  var maxX = positions.first.dx;
  var minY = positions.first.dy;
  var maxY = positions.first.dy;
  for (final p in positions.skip(1)) {
    minX = math.min(minX, p.dx);
    maxX = math.max(maxX, p.dx);
    minY = math.min(minY, p.dy);
    maxY = math.max(maxY, p.dy);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
