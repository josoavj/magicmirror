import 'package:flutter/material.dart';

class OutfitCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final double temperature;

  const OutfitCard({
    super.key,
    required this.title,
    required this.items,
    required this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Items: ${items.join(", ")}'),
            const SizedBox(height: 8),
            Text('Température: ${temperature.toStringAsFixed(1)}°C'),
          ],
        ),
      ),
    );
  }
}
