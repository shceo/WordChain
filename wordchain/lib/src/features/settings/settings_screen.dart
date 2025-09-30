import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/sound_manager.dart';
import 'game_settings_notifier.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(gameSettingsProvider);
    final settingsNotifier = ref.read(gameSettingsProvider.notifier);
    final soundSettings = ref.watch(soundSettingsProvider);
    final soundNotifier = ref.read(soundSettingsProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 88,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Sound & Music
          _SoftCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'Sound & Music'),
                  const SizedBox(height: 18),
                  _rowLabel(context, 'Music volume'),
                  const SizedBox(height: 8),
                  _VolumeSlider(
                    value: soundSettings.musicVolume,
                    onChanged: (v) => soundNotifier.setMusicVolume(v),
                  ),
                  const SizedBox(height: 16),
                  _rowLabel(context, 'Effects volume'),
                  const SizedBox(height: 8),
                  _VolumeSlider(
                    value: soundSettings.effectsVolume,
                    onChanged: (v) => soundNotifier.setEffectsVolume(v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Game Options
          _SoftCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'Game Options'),
                  const SizedBox(height: 10),
                  _OptionRow(
                    label: 'Timer (Challenge mode)',
                    trailing: _PillSwitch(
                      value: settings.timerEnabled,
                      onChanged: (v) => settingsNotifier.toggleTimer(v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _OptionRow(
                    label: 'Category mode',
                    trailing: _PillSwitch(
                      value: settings.categoryEnabled,
                      onChanged: (v) => settingsNotifier.toggleCategories(v),
                    ),
                  ),
                  if (settings.categoryEnabled) ...[
                    const SizedBox(height: 12),
                    _CategoryPicker(
                      value: settings.selectedCategory,
                      onChanged: (value) => settingsNotifier.setCategory(value),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // How to Play
          _SoftCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'How to Play'),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, c) {
                      final gap = 12.0;
                      final w = (c.maxWidth - gap * 2) / 3;
                      return Row(
                        children: [
                          SizedBox(
                            width: w,
                            child: const _PlayStepCard(
                              title: 'Pick a letter',
                            ),
                          ),
                          SizedBox(width: gap),
                          SizedBox(
                            width: w,
                            child: const _PlayStepCard(
                              title: 'Type a word',
                            ),
                          ),
                          SizedBox(width: gap),
                          SizedBox(
                            width: w,
                            child: const _PlayStepCard(
                              title: 'Watch it grow',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // About
          _SoftCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'About'),
                  const SizedBox(height: 10),
                  _aboutLine(context, 'WordChain v0.1.0'),
                  _aboutLine(context, 'Authors: Team WordChain'),
                  _aboutLine(context, 'Photo Blue UI • Minimal • Dark'),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: cs.surface,
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }

  Widget _rowLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
          ),
    );
  }

  Widget _aboutLine(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.8),
            ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.55), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 14,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  static const _photoBlue = Color(0xFF6DC7D1);

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 8,
        activeTrackColor: _photoBlue,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.16),
        thumbColor: const Color(0xFF16282E),
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),
      child: Slider(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = GameSettingsNotifier.categories;
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Active category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _PillSwitch extends StatelessWidget {
  const _PillSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const _photoBlue = Color(0xFF6DC7D1);

  @override
  Widget build(BuildContext context) {
    final trackW = 60.0;
    final trackH = 38.0;
    final knob = trackH - 12;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: trackW,
        height: trackH,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? _photoBlue : const Color(0xFF3C454B),
          borderRadius: BorderRadius.circular(trackH / 2),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          curve: Curves.easeOutCubic,
          child: Container(
            width: knob,
            height: knob,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2328),
              borderRadius: BorderRadius.circular(knob / 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
        );
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          trailing,
        ],
      ),
    );
  }
}

class _PlayStepCard extends StatelessWidget {
  const _PlayStepCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: CustomPaint(painter: _MiniGraphPainter()),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGraphPainter extends CustomPainter {
  static const _nodeFill = Color(0xFF125058);
  static const _edgeColor = Color(0xFF56969E);
  static const _stroke = Color(0xFFB0C2C6);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 8;

    final points = [
      Offset(cx - 60, cy + 8),
      Offset(cx, cy - 26),
      Offset(cx + 46, cy + 8),
    ];

    final edge = Paint()
      ..color = _edgeColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], edge);
    }

    final nodeFill = Paint()..color = _nodeFill;
    final nodeStroke = Paint()
      ..color = _stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final p in points) {
      canvas.drawCircle(p, 14, nodeFill);
      canvas.drawCircle(p, 14, nodeStroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
