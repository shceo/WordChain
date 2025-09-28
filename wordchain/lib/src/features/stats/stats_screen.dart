import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // �?�?�����: �?����>�?�?�<�� ���?�?�?��?���'�< ��� �>�?����>�?�?�?�� �'�".
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricCard(title: 'Total words', value: '0'),
            _MetricCard(title: 'Longest chain', value: '0'),
            _MetricCard(title: 'Avg/session', value: '0'),
            _MetricCard(title: 'Best Relax', value: '0'),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 100,
      child: Card(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
