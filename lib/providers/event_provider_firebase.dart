import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class EventProviderFirebase extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();

  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  Set<EventType> _selectedTypes = {};

  // Getters
  List<Event> get events => _events;
  List<Event> get filteredEvents => _filteredEvents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;
  Set<EventType> get selectedTypes => _selectedTypes;

  // Événements pour une date donnée
  List<Event> getEventsForDate(DateTime date) {
    return _events.where((event) {
      final eventDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return eventDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  // Alias pour compatibilité
  List<Event> getEventsForDay(DateTime day) => getEventsForDate(day);

  // Événements à venir
  List<Event> get upcomingEvents {
    final now = DateTime.now();
    return _events
        .where((event) => event.startDate.isAfter(now))
        .take(5)
        .toList();
  }

  // Charger les événements d'une famille
  Future<void> loadFamilyEvents(String familyId) async {
    try {
      _setLoading(true);
      _clearError();

      _events = await _firestoreService.getFamilyEvents(familyId);
      _applyFilters();

    } catch (e) {
      _setError('Erreur lors du chargement des événements: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Charger les événements pour un mois donné
  Future<void> loadFamilyEventsForMonth(String familyId, DateTime month) async {
    try {
      _setLoading(true);
      _clearError();

      _events = await _firestoreService.getFamilyEventsForMonth(familyId, month);
      _applyFilters();

    } catch (e) {
      _setError('Erreur lors du chargement des événements du mois: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Écouter les événements en temps réel
  void listenToFamilyEvents(String familyId) {
    _firestoreService.getFamilyEventsStream(familyId).listen(
      (events) {
        _events = events;
        _applyFilters();
        notifyListeners();
      },
      onError: (error) {
        _setError('Erreur sync temps réel: $error');
      },
    );
  }

  // Créer un nouvel événement
  Future<bool> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    required EventType type,
    required String familyId,
    required String createdBy,
    required String createdByName,
    bool isAllDay = false,
    String? location,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final event = Event(
        id: _uuid.v4(),
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        type: type,
        familyId: familyId,
        createdBy: createdBy,
        createdByName: createdByName,
        createdAt: DateTime.now(),
        isAllDay: isAllDay,
        location: location,
      );

      await _firestoreService.createEvent(event);
      
      // Ajouter à la liste locale
      _events.add(event);
      _events.sort((a, b) => a.startDate.compareTo(b.startDate));
      _applyFilters();

      return true;
    } catch (e) {
      _setError('Erreur lors de la création de l\'événement: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Ajouter un événement (version simplifiée)
  Future<void> addEvent(Event event) async {
    try {
      await _firestoreService.createEvent(event);
      _events.add(event);
      _events.sort((a, b) => a.startDate.compareTo(b.startDate));
      _applyFilters();
    } catch (e) {
      _setError('Erreur lors de l\'ajout: $e');
    }
  }

  // Mettre à jour un événement
  Future<bool> updateEvent(Event event) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestoreService.updateEvent(event);
      
      // Mettre à jour dans la liste locale
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event;
        _events.sort((a, b) => a.startDate.compareTo(b.startDate));
        _applyFilters();
      }

      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour de l\'événement: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer un événement
  Future<bool> deleteEvent(String eventId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestoreService.deleteEvent(eventId);
      
      // Supprimer de la liste locale
      _events.removeWhere((event) => event.id == eventId);
      _applyFilters();

      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression de l\'événement: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sélectionner une date
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Filtrer par types d'événements
  void toggleEventTypeFilter(EventType type) {
    if (_selectedTypes.contains(type)) {
      _selectedTypes.remove(type);
    } else {
      _selectedTypes.add(type);
    }
    _applyFilters();
  }

  void clearTypeFilters() {
    _selectedTypes.clear();
    _applyFilters();
  }

  void setTypeFilters(Set<EventType> types) {
    _selectedTypes = types;
    _applyFilters();
  }

  // Appliquer les filtres
  void _applyFilters() {
    if (_selectedTypes.isEmpty) {
      _filteredEvents = List.from(_events);
    } else {
      _filteredEvents = _events
          .where((event) => _selectedTypes.contains(event.type))
          .toList();
    }
    notifyListeners();
  }

  // Recherche d'événements
  List<Event> searchEvents(String query) {
    if (query.isEmpty) return _events;
    
    final lowerQuery = query.toLowerCase();
    return _events.where((event) {
      return event.title.toLowerCase().contains(lowerQuery) ||
             event.description.toLowerCase().contains(lowerQuery) ||
             event.location?.toLowerCase().contains(lowerQuery) == true ||
             event.createdByName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Statistiques
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

  // Événements par créateur
  Map<String, int> getEventsByCreator() {
    final Map<String, int> stats = {};

    for (final event in _events) {
      stats[event.createdByName] = (stats[event.createdByName] ?? 0) + 1;
    }

    return stats;
  }

  // Obtenir le prochain événement
  Event? get nextEvent {
    final now = DateTime.now();
    final upcoming = _events
        .where((event) => event.startDate.isAfter(now))
        .toList();
    
    if (upcoming.isEmpty) return null;
    
    upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
    return upcoming.first;
  }

  // Événements du jour
  List<Event> get todayEvents {
    return getEventsForDate(DateTime.now());
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
    _filteredEvents.clear();
    _selectedTypes.clear();
    _selectedDate = DateTime.now();
    _clearError();
    notifyListeners();
  }

  // Vérifier si une date a des événements
  bool hasEventsOnDate(DateTime date) {
    return getEventsForDate(date).isNotEmpty;
  }
}