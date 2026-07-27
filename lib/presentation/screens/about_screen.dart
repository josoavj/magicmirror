import 'package:flutter/material.dart';
import 'package:magicmirror/presentation/widgets/about_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEnglish ? 'About' : 'À propos'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                AboutHeader(isEnglish: isEnglish),
                const SizedBox(height: 32),
                AboutCard(isEnglish: isEnglish),
                const SizedBox(height: 24),
                AboutFeatureList(isEnglish: isEnglish),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
