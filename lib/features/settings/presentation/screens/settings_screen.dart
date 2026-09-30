import 'package:flutter/material.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'package:magicmirror/features/settings/presentation/widgets/camera_settings_section.dart';
import 'package:magicmirror/features/settings/presentation/widgets/location_calendar_settings_section.dart';
import 'package:magicmirror/features/settings/presentation/widgets/settings_display_sections.dart';
import 'package:magicmirror/features/settings/presentation/widgets/settings_general_sections.dart';
import 'package:magicmirror/features/settings/presentation/widgets/tts_settings_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 32),
            children: const [
              DisplaySettingsSection(),
              NotificationSettingsSection(),
              TtsSettingsSection(),
              LocationCalendarSettingsSection(),
              CameraSettingsSection(),
              SettingsGeneralSections(),
            ],
          ),
        ),
      ),
    );
  }
}
