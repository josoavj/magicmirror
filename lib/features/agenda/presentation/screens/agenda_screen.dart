import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:magicmirror/core/theme/app_colors.dart';
import '../providers/agenda_provider.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaState = ref.watch(agendaEventsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Planning',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'Aujourd\'hui',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    _GlassIconButton(
                      icon: Icons.sync,
                      onPressed: () => ref
                          .read(agendaEventsProvider.notifier)
                          .syncWithGoogle(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: agendaState.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Erreur: $err',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  data: (events) => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final now = DateTime.now();
                      final isNow =
                          now.isAfter(event.startTime) &&
                          now.isBefore(event.endTime);

                      return _AgendaGlassTile(
                        time:
                            '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}',
                        title: event.title,
                        type: event.eventType,
                        isNow: isNow,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _GlassButton(
                  label: 'Retour au Miroir',
                  onPressed: () => Navigator.pop(context),
                  icon: Icons.arrow_back_ios_new,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaGlassTile extends StatelessWidget {
  final String time;
  final String title;
  final String type;
  final bool isNow;

  const _AgendaGlassTile({
    required this.time,
    required this.title,
    required this.type,
    this.isNow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppColors.getOptimizedBlur(30),
            sigmaY: AppColors.getOptimizedBlur(30),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isNow
                  ? Colors.blue.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isNow
                    ? Colors.blue.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      type,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isNow)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.getOptimizedBlur(10),
          sigmaY: AppColors.getOptimizedBlur(10),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const _GlassButton({
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppColors.getOptimizedBlur(20),
            sigmaY: AppColors.getOptimizedBlur(20),
          ),
          child: Container(
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
