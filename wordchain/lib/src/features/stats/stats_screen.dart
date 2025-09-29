import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({
    super.key,
    this.totalWords = 0,
    this.longestChain = 0,
    this.avgPerSession = 0.0,
    this.bestSession,
    this.recordsByMode = const {'Relax': 0, 'Challenge': 0, 'Themed': 0},
  });     

  final int totalWords;
  final int longestChain;
  final double avgPerSession;
  final int? bestSession;
  final Map<String, int?> recordsByMode;

  int _capInt(int? value) {
    if (value == null) return 0;
    if (value < 0) return 0;
    const max = 1 << 30;
    return value > max ? max : value;
  }

  Map<String, int> _sanitizeModes() {
    final base = {
      'Relax': 0,
      'Challenge': 0,
      'Themed': 0,
    };
    for (final entry in recordsByMode.entries) {
      base[entry.key] = _capInt(entry.value);
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeModes = _sanitizeModes();
    final double normalizedAvg =
        avgPerSession.isFinite ? avgPerSession.clamp(0.0, 9999.0) : 0.0;
    final best = _capInt(bestSession);

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
        builder: (context, c) {
          const horizontal = 16.0;
          const spacing = 16.0;
          final full = c.maxWidth - horizontal * 2;
          final colW = (full - spacing) / 2;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: horizontal, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _MetricCard(
                      width: colW,
                      title: 'Total words',
                      value: '$totalWords',
                    ),
                    _MetricCard(
                      width: colW,
                      title: 'Longest chain',
                      value: '$longestChain',
                    ),
                    _MetricCard(
                      width: colW,
                      title: 'Avg/session',
                      value: normalizedAvg.toStringAsFixed(1),
                    ),
                    _MetricCard(
                      width: colW,
                      title: 'Best session',
                      value: best > 0 ? '$best' : '0',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ModesCard(
                  width: full,
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: 0.72),
            cs.surfaceContainerHighest.withValues(alpha: 0.60),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
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
    final max = (values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b));
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
            (e) => _ModeRow(
              label: e.key,
              value: e.value,
              maxValue: max,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  static const _photoBlue = Color(0xFF6DC7D1);
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
              builder: (context, c) {
                const trackH = 22.0;
                final progress = (maxValue <= 0) ? 0.0 : value / maxValue;
                final cappedProgress = progress.clamp(0.0, 1.0);
                final fillW = c.maxWidth * cappedProgress;
                return Stack(
                  children: [
                    Container(
                      height: trackH,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      width: fillW,
                      height: trackH,
                      decoration: BoxDecoration(
                        color: _photoBlue,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _photoBlue.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    if (value > 0)
                      Positioned(
                        right: (c.maxWidth - fillW) + 6,
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
