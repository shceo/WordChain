import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/models.dart';
import 'stats_notifier.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  int _capInt(int value) {
    if (value < 0) return 0;
    const max = 1 << 30;
    return value > max ? max : value;
  }

  Map<String, int> _recordsForDisplay(Map<GameMode, int> source) {
    final map = <String, int>{};
    for (final mode in GameMode.values) {
      final label = _modeLabel(mode);
      map[label] = _capInt(source[mode] ?? 0);
    }
    return map;
  }

  static String _modeLabel(GameMode mode) {
    switch (mode) {
      case GameMode.relax:
        return 'Relax';
      case GameMode.challenge:
        return 'Challenge';
      case GameMode.themed:
        return 'Themed';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final theme = Theme.of(context);

    final totalWords = _capInt(stats.totalWords);
    final longestChain = _capInt(stats.longestChain);
    final average = stats.averageWordsPerSession.isFinite
        ? stats.averageWordsPerSession.clamp(0.0, 9999.0)
        : 0.0;
    final best = _capInt(stats.bestSession);
    final safeModes = _recordsForDisplay(stats.bestByMode);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 80,
        title: const Text('Statistics'),
        titleTextStyle: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const horizontal = 16.0;
          const spacing = 16.0;
          final fullWidth = constraints.maxWidth - horizontal * 2;
          final columnWidth = (fullWidth - spacing) / 2;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontal,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _MetricCard(
                      width: columnWidth,
                      title: 'Total words',
                      value: '$totalWords',
                    ),
                    _MetricCard(
                      width: columnWidth,
                      title: 'Longest chain',
                      value: '$longestChain',
                    ),
                    _MetricCard(
                      width: columnWidth,
                      title: 'Avg/session',
                      value: average.toStringAsFixed(1),
                    ),
                    _MetricCard(
                      width: columnWidth,
                      title: 'Best session',
                      value: best > 0 ? '$best' : '0',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ModesCard(
                  width: fullWidth,
                  title: 'Records by mode',
                  entries: safeModes,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.width,
  });

  final String title;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: 160,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.75),
                  ),
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModesCard extends StatelessWidget {
  const _ModesCard({
    required this.title,
    required this.entries,
    required this.width,
  });

  final String title;
  final Map<String, int> entries;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final values = entries.values.toList();
    final max = values.isEmpty ? 0 : values.reduce(math.max);

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 14),
          ...entries.entries.map(
            (entry) => _ModeRow(
              label: entry.key,
              value: entry.value,
              maxValue: max,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  final String label;
  final int value;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const barColor = Color(0xFF6DC7D1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.85),
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const trackHeight = 22.0;
                final progress = maxValue <= 0 ? 0.0 : value / maxValue;
                final cappedProgress = progress.clamp(0.0, 1.0);
                final fillWidth = constraints.maxWidth * cappedProgress;
                return Stack(
                  children: [
                    Container(
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      width: fillWidth,
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: barColor.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    if (value > 0)
                      Positioned(
                        right: (constraints.maxWidth - fillWidth) + 6,
                        top: -2,
                        child: Text(
                          '$value',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16282E),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
