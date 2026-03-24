import 'package:flutter/foundation.dart';
import '../models/event.dart';

class EventProvider extends ChangeNotifier {
  // Mode local pour démonstration
  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  // Getters
  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  // Ajouter un événement
  void addEvent(Event event) {
    _events.add(event);
    _events.sort((a, b) => a.startDate.compareTo(b.startDate));
    notifyListeners();
  }

  // Supprimer un événement
  void deleteEvent(String eventId) {
    _events.removeWhere((event) => event.id == eventId);
    notifyListeners();
  }

  // Mettre à jour un événement
  void updateEvent(Event updatedEvent) {
    final index = _events.indexWhere((event) => event.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      _events.sort((a, b) => a.startDate.compareTo(b.startDate));
      notifyListeners();
    }
  }

  // Obtenir les événements pour un jour donné
  List<Event> getEventsForDay(DateTime day) {
    return _events.where((event) {
      final eventDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final targetDate = DateTime(day.year, day.month, day.day);
      return eventDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  // Sélectionner une date
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Vérifier si une date a des événements
  bool hasEventsOnDate(DateTime date) {
    return getEventsForDay(date).isNotEmpty;
  }

  // Événements du jour
  List<Event> get todayEvents {
    return getEventsForDay(DateTime.now());
  }

  // Événements à venir (prochains 7 jours)
  List<Event> get upcomingEvents {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    
    return _events.where((event) {
      return event.startDate.isAfter(now) && 
             event.startDate.isBefore(nextWeek);
    }).take(5).toList();
  }

  // Prochain événement
  Event? get nextEvent {
    final now = DateTime.now();
    final upcoming = _events
        .where((event) => event.startDate.isAfter(now))
        .toList();
    
    if (upcoming.isEmpty) return null;
    
    upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
    return upcoming.first;
  }

  // Rechercher des événements
  List<Event> searchEvents(String query) {
    if (query.isEmpty) return _events;
    
    final lowerQuery = query.toLowerCase();
    return _events.where((event) {
      return event.title.toLowerCase().contains(lowerQuery) ||
             event.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Statistiques par type
  Map<EventType, int> getEventTypeStats() {
    final Map<EventType, int> stats = {};
    
    for (final type in EventType.values) {
      stats[type] = 0;
    }

    for (final event in _events) {
      stats[event.type] = (stats[event.type] ?? 0) + 1;
    }

    return stats;
  }

  // Événements de la semaine
  List<Event> get weekEvents {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return _events.where((event) {
      final eventDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      return eventDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             eventDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  // Méthodes utilitaires privées
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Réinitialiser le provider
  void clear() {
    _events.clear();
    _selectedDate = DateTime.now();
    _clearError();
    notifyListeners();
  }

  // Ajouter des événements de démonstration
  void addSampleEvents() {
    final now = DateTime.now();
    
    // Événement aujourd'hui
    addEvent(Event(
      id: 'demo-1',
      familyId: 'local-family',
      title: 'Réunion équipe',
      description: 'Réunion hebdomadaire de l\'équipe projet',
      startDate: DateTime(now.year, now.month, now.day, 14, 0),
      endDate: DateTime(now.year, now.month, now.day, 15, 30),
      type: EventType.work,
      createdBy: 'local-user',
      createdByName: 'Utilisateur Local',
      createdAt: DateTime.now(),
    ));
    
    // Événement demain
    final tomorrow = now.add(const Duration(days: 1));
    addEvent(Event(
      id: 'demo-2',
      familyId: 'local-family',
      title: 'Rendez-vous médecin',
      description: 'Consultation annuelle',
      startDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 30),
      endDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 30),
      type: EventType.medical,
      createdBy: 'local-user',
      createdByName: 'Utilisateur Local',
      createdAt: DateTime.now(),
    ));
    
    // Événement familial weekend
    final weekend = now.add(Duration(days: 6 - now.weekday));
    addEvent(Event(
      id: 'demo-3',
      familyId: 'local-family',
      title: 'Sortie parc',
      description: 'Balade en famille au parc',
      startDate: DateTime(weekend.year, weekend.month, weekend.day, 15, 0),
      endDate: DateTime(weekend.year, weekend.month, weekend.day, 17, 0),
      type: EventType.family,
      createdBy: 'local-user',
      createdByName: 'Utilisateur Local',
      createdAt: DateTime.now(),
    ));
  }
}