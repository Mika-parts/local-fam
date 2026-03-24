import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final EventType type;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final String familyId;
  final bool isAllDay;
  final String? location;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.type,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.familyId,
    this.isAllDay = false,
    this.location,
  });

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'type': type.name,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'familyId': familyId,
      'isAllDay': isAllDay,
      'location': location,
    };
  }

  // Conversion depuis Map Firestore
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      type: EventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EventType.personal,
      ),
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      familyId: map['familyId'] ?? '',
      isAllDay: map['isAllDay'] ?? false,
      location: map['location'],
    );
  }

  // Copie avec modifications
  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    EventType? type,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    String? familyId,
    bool? isAllDay,
    String? location,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      familyId: familyId ?? this.familyId,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
    );
  }
}

enum EventType {
  medical,    // 🏥 Médical (rouge)
  school,     // 🎓 École (bleu)
  sport,      // ⚽ Sport (vert)
  personal,   // 👤 Personnel (gris)
  family,     // 👨‍👩‍👧‍👦 Famille (orange)
  work,       // 💼 Travail (violet)
  birthday,   // 🎂 Anniversaire (rose)
  vacation,   // 🏖️ Vacances (cyan)
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.medical:
        return 'Médical';
      case EventType.school:
        return 'École';
      case EventType.sport:
        return 'Sport';
      case EventType.personal:
        return 'Personnel';
      case EventType.family:
        return 'Famille';
      case EventType.work:
        return 'Travail';
      case EventType.birthday:
        return 'Anniversaire';
      case EventType.vacation:
        return 'Vacances';
    }
  }

  String get emoji {
    switch (this) {
      case EventType.medical:
        return '🏥';
      case EventType.school:
        return '🎓';
      case EventType.sport:
        return '⚽';
      case EventType.personal:
        return '👤';
      case EventType.family:
        return '👨‍👩‍👧‍👦';
      case EventType.work:
        return '💼';
      case EventType.birthday:
        return '🎂';
      case EventType.vacation:
        return '🏖️';
    }
  }
}