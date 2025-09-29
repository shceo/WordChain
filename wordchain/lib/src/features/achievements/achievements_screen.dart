import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const <_Achievement>[
      _Achievement(title: 'First Web', subtitle: 'Create your first web'),
      _Achievement(title: 'Brainstormer', subtitle: '50 words in one session'),
      _Achievement(title: 'Color Master', subtitle: '5 categories in one web'),
      _Achievement(title: 'Speed Thinker', subtitle: '10 words in a minute'),
    ];

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

class _Achievement {
  final String title;
  final String subtitle;
  final bool unlocked;
  const _Achievement({
    required this.title,
    required this.subtitle,
    this.unlocked = false,
  });
}

/// Карточка в стиле макета: мягкий фон, закругления, тонкий бордер и «блик» сверху.
class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.item});
  final _Achievement item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _SoftCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _TitleBlock(title: item.title, subtitle: item.subtitle),
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
  const _TitleBlock({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: onSurface.withOpacity(0.75),
                height: 1.2,
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
        color: cs.surface.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6), width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 26,
        color: locked ? cs.onSurface.withOpacity(0.75) : cs.primary,
      ),
    );
  }
}

/// Универсальная «мягкая» карточка с тонким бордером и лёгким верхним блик-градиентом.
class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child, this.radius = 22});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.66),
        borderRadius: BorderRadius.circular(radius),
        border:
            Border.all(color: cs.outlineVariant.withOpacity(0.55), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
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
                color: Colors.white.withOpacity(0.05),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(radius)),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
