import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Мини-заглушка. Позже — вычисление прогресса из хранилища.
    final items = [
      ('First Web', 'Create your first web', false),
      ('Brainstormer', '50 words in one session', false),
      ('Color Master', '5 categories in one web', false),
      ('Speed Thinker', '10 words in a minute', false),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final it = items[i];
          return Card(
            child: ListTile(
              title: Text(it.$1),
              subtitle: Text(it.$2),
              trailing: Icon(it.$3 ? Icons.verified : Icons.lock_outline),
            ),
          );
        },
      ),
    );
  }
}
