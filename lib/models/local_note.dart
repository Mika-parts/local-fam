import 'dart:convert';

/// Modèle pour les notes/entrées du journal familial local
class LocalNote {
  final String id;
  final String title;
  final String content;
  final DateTime date; // Date de l'événement/souvenir
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags; // Tags pour catégoriser
  final List<String> people; // Personnes concernées
  final String mood; // Humeur du jour ('happy', 'sad', 'neutral', 'excited', 'tired')
  final int? weatherIconCode; // Code météo optionnel
  final List<String> photoAttachments; // IDs des photos liées
  final String category; // 'milestone', 'daily', 'special', 'memory', 'achievement'
  final bool isPrivate; // Note privée ou partagée avec la famille
  final bool isFavorite; // Note favorite/importante

  LocalNote({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.people = const [],
    this.mood = 'neutral',
    this.weatherIconCode,
    this.photoAttachments = const [],
    this.category = 'daily',
    this.isPrivate = false,
    this.isFavorite = false,
  });

  /// Constructeur factory pour créer une nouvelle note
  factory LocalNote.create({
    required String title,
    required String content,
    DateTime? date,
    List<String> tags = const [],
    List<String> people = const [],
    String mood = 'neutral',
    int? weatherIconCode,
    List<String> photoAttachments = const [],
    String category = 'daily',
    bool isPrivate = false,
    bool isFavorite = false,
  }) {
    final now = DateTime.now();
    return LocalNote(
      id: 'note_${now.millisecondsSinceEpoch}',
      title: title,
      content: content,
      date: date ?? now,
      createdAt: now,
      updatedAt: now,
      tags: tags,
      people: people,
      mood: mood,
      weatherIconCode: weatherIconCode,
      photoAttachments: photoAttachments,
      category: category,
      isPrivate: isPrivate,
      isFavorite: isFavorite,
    );
  }

  /// Créer une copie avec modifications
  LocalNote copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    List<String>? people,
    String? mood,
    int? weatherIconCode,
    List<String>? photoAttachments,
    String? category,
    bool? isPrivate,
    bool? isFavorite,
  }) {
    return LocalNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      people: people ?? this.people,
      mood: mood ?? this.mood,
      weatherIconCode: weatherIconCode ?? this.weatherIconCode,
      photoAttachments: photoAttachments ?? this.photoAttachments,
      category: category ?? this.category,
      isPrivate: isPrivate ?? this.isPrivate,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Conversion en JSON pour stockage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'people': people,
      'mood': mood,
      'weatherIconCode': weatherIconCode,
      'photoAttachments': photoAttachments,
      'category': category,
      'isPrivate': isPrivate,
      'isFavorite': isFavorite,
    };
  }

  /// Création depuis JSON
  factory LocalNote.fromJson(Map<String, dynamic> json) {
    return LocalNote(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      tags: List<String>.from(json['tags'] ?? []),
      people: List<String>.from(json['people'] ?? []),
      mood: json['mood'] ?? 'neutral',
      weatherIconCode: json['weatherIconCode'],
      photoAttachments: List<String>.from(json['photoAttachments'] ?? []),
      category: json['category'] ?? 'daily',
      isPrivate: json['isPrivate'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  /// Obtenir l'émoji selon l'humeur
  static String getMoodEmoji(String mood) {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'excited':
        return '🤩';
      case 'tired':
        return '😴';
      case 'angry':
        return '😠';
      case 'love':
        return '🥰';
      case 'surprised':
        return '😯';
      case 'worried':
        return '😟';
      default:
        return '😐'; // neutral
    }
  }

  /// Obtenir la couleur selon la catégorie
  static Map<String, dynamic> getCategoryInfo(String category) {
    switch (category) {
      case 'milestone':
        return {
          'color': 0xFFE53E3E,
          'name': 'Étape importante',
          'icon': '🎯'
        };
      case 'special':
        return {
          'color': 0xFF9F7AEA,
          'name': 'Événement spécial',
          'icon': '⭐'
        };
      case 'memory':
        return {
          'color': 0xFF38A169,
          'name': 'Souvenir',
          'icon': '💭'
        };
      case 'achievement':
        return {
          'color': 0xFFD69E2E,
          'name': 'Réussite',
          'icon': '🏆'
        };
      case 'travel':
        return {
          'color': 0xFF3182CE,
          'name': 'Voyage',
          'icon': '✈️'
        };
      default: // daily
        return {
          'color': 0xFF718096,
          'name': 'Quotidien',
          'icon': '📝'
        };
    }
  }

  /// Humeurs disponibles
  static List<Map<String, String>> get availableMoods => [
    {'key': 'happy', 'emoji': '😊', 'name': 'Content'},
    {'key': 'love', 'emoji': '🥰', 'name': 'Amoureux'},
    {'key': 'excited', 'emoji': '🤩', 'name': 'Excité'},
    {'key': 'neutral', 'emoji': '😐', 'name': 'Neutre'},
    {'key': 'tired', 'emoji': '😴', 'name': 'Fatigué'},
    {'key': 'worried', 'emoji': '😟', 'name': 'Inquiet'},
    {'key': 'sad', 'emoji': '😢', 'name': 'Triste'},
    {'key': 'angry', 'emoji': '😠', 'name': 'En colère'},
    {'key': 'surprised', 'emoji': '😯', 'name': 'Surpris'},
  ];

  /// Catégories disponibles
  static List<Map<String, dynamic>> get availableCategories => [
    {'key': 'daily', 'name': 'Quotidien', 'icon': '📝'},
    {'key': 'milestone', 'name': 'Étape importante', 'icon': '🎯'},
    {'key': 'special', 'name': 'Événement spécial', 'icon': '⭐'},
    {'key': 'memory', 'name': 'Souvenir', 'icon': '💭'},
    {'key': 'achievement', 'name': 'Réussite', 'icon': '🏆'},
    {'key': 'travel', 'name': 'Voyage', 'icon': '✈️'},
  ];

  /// Date formatée
  String get dateFormatted {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Vérifier si la note correspond à une recherche
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Recherche dans le titre
    if (title.toLowerCase().contains(lowerQuery)) return true;
    
    // Recherche dans le contenu
    if (content.toLowerCase().contains(lowerQuery)) return true;
    
    // Recherche dans les tags
    if (tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) return true;
    
    // Recherche dans les personnes
    if (people.any((person) => person.toLowerCase().contains(lowerQuery))) return true;
    
    return false;
  }

  /// Obtenir un extrait du contenu (pour les listes)
  String get excerpt {
    if (content.length <= 100) return content;
    return '${content.substring(0, 97)}...';
  }

  /// Tags suggérés populaires
  static List<String> get suggestedTags => [
    'famille',
    'anniversaire',
    'vacances',
    'école',
    'santé',
    'cuisine',
    'sortie',
    'amis',
    'sport',
    'lecture',
    'cinéma',
    'musique',
    'nature',
    'voyage',
    'fête',
    'travail',
    'loisirs',
    'apprentissage',
  ];

  @override
  String toString() {
    return 'LocalNote(id: $id, title: $title, date: $dateFormatted)';
  }
}