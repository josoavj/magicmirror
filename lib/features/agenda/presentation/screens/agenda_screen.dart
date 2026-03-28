import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';
import '../providers/agenda_provider.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaState = ref.watch(agendaEventsProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 600;

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
                padding: EdgeInsets.all(isMobile ? 18 : 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planning',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 30 : 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'Aujourd\'hui',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.58),
                            fontSize: isMobile ? 16 : 18,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                    ),
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
                padding: EdgeInsets.all(isMobile ? 16 : 24),
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
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        borderRadius: 24,
        blur: isNow ? 36 : 32,
        opacity: isNow ? 0.13 : 0.1,
        tintColor: isNow ? Colors.blue : Colors.white,
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(width: isMobile ? 16 : 24),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 18,
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
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      blur: 16,
      opacity: 0.12,
      padding: EdgeInsets.zero,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
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
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        borderRadius: 24,
        blur: 28,
        opacity: 0.11,
        padding: EdgeInsets.symmetric(vertical: isMobile ? 18 : 20),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
