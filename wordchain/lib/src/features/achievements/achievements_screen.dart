import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'achievements_notifier.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsProvider);
    final items = _itemsFromState(state);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 88,
        title: Text(
          'Achievements',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemBuilder: (_, i) => _AchievementTile(item: items[i]),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: items.length,
      ),
    );
  }
}

List<_Achievement> _itemsFromState(AchievementsState state) {
  final firstWebUnlocked = state.isUnlocked(AchievementType.firstWeb);
  final firstWebCurrent = state.chainLength > 0 ? 1 : 0;
  final firstWebProgress = firstWebUnlocked ? 1.0 : firstWebCurrent.toDouble();
  final firstWebLabel =
      firstWebUnlocked ? 'Completed' : '$firstWebCurrent/1 web created';

  final brainstormUnlocked = state.isUnlocked(AchievementType.brainstormer);
  final brainstormCurrent = state.chainLength > 50 ? 50 : state.chainLength;
  final brainstormProgress =
      brainstormUnlocked ? 1.0 : brainstormCurrent / 50.0;
  final brainstormLabel = brainstormUnlocked
      ? 'Completed'
      : '$brainstormCurrent/50 words in this chain';

  final colorUnlocked = state.isUnlocked(AchievementType.colorMaster);
  final colorCurrent = state.uniqueCategories > 5 ? 5 : state.uniqueCategories;
  final colorProgress = colorUnlocked ? 1.0 : colorCurrent / 5.0;
  final colorLabel =
      colorUnlocked ? 'Completed' : '$colorCurrent/5 categories connected';

  final speedUnlocked = state.isUnlocked(AchievementType.speedThinker);
  final speedCurrent = state.wordsLastMinute > 10 ? 10 : state.wordsLastMinute;
  final speedProgress = speedUnlocked ? 1.0 : speedCurrent / 10.0;
  final speedLabel =
      speedUnlocked ? 'Completed' : '$speedCurrent/10 words in the last minute';

  return [
    _Achievement(
      title: 'First Web',
      subtitle: 'Create your first web',
      unlocked: firstWebUnlocked,
      progress: firstWebProgress,
      progressLabel: firstWebLabel,
    ),
    _Achievement(
      title: 'Brainstormer',
      subtitle: '50 words in one session',
      unlocked: brainstormUnlocked,
      progress: brainstormProgress,
      progressLabel: brainstormLabel,
    ),
    _Achievement(
      title: 'Color Master',
      subtitle: '5 categories in one web',
      unlocked: colorUnlocked,
      progress: colorProgress,
      progressLabel: colorLabel,
    ),
    _Achievement(
      title: 'Speed Thinker',
      subtitle: '10 words in a minute',
      unlocked: speedUnlocked,
      progress: speedProgress,
      progressLabel: speedLabel,
    ),
  ];
}

class _Achievement {
  final String title;
  final String subtitle;
  final bool unlocked;
  final double progress;
  final String progressLabel;
  const _Achievement({
    required this.title,
    required this.subtitle,
    required this.unlocked,
    required this.progress,
    required this.progressLabel,
  });
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.item});
  final _Achievement item;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _TitleBlock(
                title: item.title,
                subtitle: item.subtitle,
                progress: item.progress,
                progressLabel: item.progressLabel,
                unlocked: item.unlocked,
              ),
            ),
            const SizedBox(width: 12),
            _LockBadge(locked: !item.unlocked),
          ],
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressLabel,
    required this.unlocked,
  });
  final String title;
  final String subtitle;
  final double progress;
  final String progressLabel;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final barColor = unlocked
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.75);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: onSurface.withValues(alpha: 0.75),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          progressLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge({required this.locked});
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = locked ? Icons.lock_outline_rounded : Icons.verified_rounded;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.6), width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 26,
        color: locked ? cs.onSurface.withValues(alpha: 0.75) : cs.primary,
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});
  final Widget child;

  static const double _radius = 22;
  static const BorderRadius _cardRadius =
      BorderRadius.all(Radius.circular(_radius));
  static const BorderRadius _topRadius =
      BorderRadius.vertical(top: Radius.circular(_radius));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.66),
        borderRadius: _cardRadius,
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
                borderRadius: _topRadius,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
