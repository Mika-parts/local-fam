import 'dart:convert';

/// Modèle pour les événements du calendrier familial local
class LocalEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final String category; // 'rdv_medical', 'ecole', 'loisirs', 'travail', 'famille'
  final String? location;
  final List<String> participants; // membres famille concernés
  final bool isAllDay;
  final String? recurrence; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime? recurrenceEnd;
  final int reminderMinutes; // notification X minutes avant
  final DateTime createdAt;
  final DateTime updatedAt;

  LocalEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    this.endTime,
    required this.category,
    this.location,
    required this.participants,
    this.isAllDay = false,
    this.recurrence,
    this.recurrenceEnd,
    this.reminderMinutes = 15,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Constructeur factory pour créer un nouvel événement
  factory LocalEvent.create({
    required String title,
    required String description,
    required DateTime startTime,
    DateTime? endTime,
    required String category,
    String? location,
    List<String> participants = const [],
    bool isAllDay = false,
    String? recurrence,
    DateTime? recurrenceEnd,
    int reminderMinutes = 15,
  }) {
    final now = DateTime.now();
    return LocalEvent(
      id: 'evt_${now.millisecondsSinceEpoch}',
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      category: category,
      location: location,
      participants: participants,
      isAllDay: isAllDay,
      recurrence: recurrence,
      recurrenceEnd: recurrenceEnd,
      reminderMinutes: reminderMinutes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Créer une copie avec modifications
  LocalEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? category,
    String? location,
    List<String>? participants,
    bool? isAllDay,
    String? recurrence,
    DateTime? recurrenceEnd,
    int? reminderMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      location: location ?? this.location,
      participants: participants ?? this.participants,
      isAllDay: isAllDay ?? this.isAllDay,
      recurrence: recurrence ?? this.recurrence,
      recurrenceEnd: recurrenceEnd ?? this.recurrenceEnd,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Conversion en JSON pour stockage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'category': category,
      'location': location,
      'participants': participants,
      'isAllDay': isAllDay,
      'recurrence': recurrence,
      'recurrenceEnd': recurrenceEnd?.toIso8601String(),
      'reminderMinutes': reminderMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Création depuis JSON
  factory LocalEvent.fromJson(Map<String, dynamic> json) {
    return LocalEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      category: json['category'],
      location: json['location'],
      participants: List<String>.from(json['participants'] ?? []),
      isAllDay: json['isAllDay'] ?? false,
      recurrence: json['recurrence'],
      recurrenceEnd: json['recurrenceEnd'] != null ? DateTime.parse(json['recurrenceEnd']) : null,
      reminderMinutes: json['reminderMinutes'] ?? 15,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Obtenir la couleur selon la catégorie
  static Map<String, dynamic> getCategoryColor(String category) {
    switch (category) {
      case 'rdv_medical':
        return {'color': 0xFFE53E3E, 'name': 'Médical'}; // Rouge
      case 'ecole':
        return {'color': 0xFF3182CE, 'name': 'École'}; // Bleu
      case 'loisirs':
        return {'color': 0xFF38A169, 'name': 'Loisirs'}; // Vert
      case 'travail':
        return {'color': 0xFF805AD5, 'name': 'Travail'}; // Violet
      case 'famille':
        return {'color': 0xFFD69E2E, 'name': 'Famille'}; // Orange
      default:
        return {'color': 0xFF718096, 'name': 'Autre'}; // Gris
    }
  }

  /// Vérifier si l'événement est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    return eventDate == today;
  }

  /// Vérifier si l'événement est demain
  bool get isTomorrow {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    return eventDate == tomorrow;
  }

  /// Obtenir une description formatée de la durée
  String get durationDescription {
    if (isAllDay) return 'Toute la journée';
    if (endTime == null) {
      return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    }
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} → '
        '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'LocalEvent(id: $id, title: $title, startTime: $startTime)';
  }
}