import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/event_model.dart';

final agendaEventsProvider = FutureProvider<List<AgendaEvent>>((ref) async {
  // Simulation de récupération de données
  await Future.delayed(const Duration(seconds: 1));
  
  final now = DateTime.now();
  return [
    AgendaEvent(
      id: '1',
      title: 'Réunion d\'équipe',
      description: 'Synchronisation hebdomadaire',
      startTime: now.add(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 2)),
      location: 'Salle de réunion A',
    ),
    AgendaEvent(
      id: '2',
      title: 'Déjeuner client',
      startTime: now.add(const Duration(hours: 4)),
      endTime: now.add(const Duration(hours: 5, minutes: 30)),
      location: 'Brasserie Lipp',
    ),
    AgendaEvent(
      id: '3',
      title: 'Présentations Projets',
      startTime: now.add(const Duration(days: 1, hours: 2)),
      endTime: now.add(const Duration(days: 1, hours: 4)),
      location: 'Amphithéâtre',
    ),
  ];
});
