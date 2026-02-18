import 'package:flutter/material.dart';

class OutfitSuggestionScreen extends StatelessWidget {
  const OutfitSuggestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suggestions de Tenue')),
      body: const Center(child: Text('Écran de suggestions de tenue')),
    );
  }
}
