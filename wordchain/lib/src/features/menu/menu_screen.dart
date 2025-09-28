import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WordChain')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _bigBtn(context, 'Play', () => Navigator.pushNamed(context, '/game')),
              const SizedBox(height: 12),
              _bigBtn(context, 'Gallery', () => Navigator.pushNamed(context, '/gallery')),
              const SizedBox(height: 12),
              _bigBtn(context, 'Achievements', () => Navigator.pushNamed(context, '/achievements')),
              const SizedBox(height: 12),
              _bigBtn(context, 'Statistics', () => Navigator.pushNamed(context, '/stats')),
              const SizedBox(height: 12),
              _bigBtn(context, 'Settings', () => Navigator.pushNamed(context, '/settings')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigBtn(BuildContext ctx, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(label),
        ),
      ),
    );
  }
}
