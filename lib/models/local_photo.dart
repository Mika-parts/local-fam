import 'dart:convert';

/// Modèle pour les photos dans les albums familiaux locaux
class LocalPhoto {
  final String id;
  final String albumName;
  final String fileName;
  final String localPath;
  final String? caption; // Légende/description
  final List<String> tags; // Tags pour recherche
  final DateTime dateTaken; // Date de prise de vue (EXIF ou création)
  final DateTime dateAdded; // Date d'ajout à l'album
  final double? latitude; // GPS si disponible
  final double? longitude; // GPS si disponible
  final String? location; // Nom du lieu
  final List<String> people; // Personnes identifiées sur la photo
  final int fileSizeBytes;
  final int? width;
  final int? height;
  final bool isFavorite;
  final String? originalPath; // Chemin d'origine si importé

  LocalPhoto({
    required this.id,
    required this.albumName,
    required this.fileName,
    required this.localPath,
    this.caption,
    this.tags = const [],
    required this.dateTaken,
    required this.dateAdded,
    this.latitude,
    this.longitude,
    this.location,
    this.people = const [],
    required this.fileSizeBytes,
    this.width,
    this.height,
    this.isFavorite = false,
    this.originalPath,
  });

  /// Constructeur factory pour créer une nouvelle photo
  factory LocalPhoto.create({
    required String albumName,
    required String fileName,
    required String localPath,
    String? caption,
    List<String> tags = const [],
    DateTime? dateTaken,
    double? latitude,
    double? longitude,
    String? location,
    List<String> people = const [],
    required int fileSizeBytes,
    int? width,
    int? height,
    String? originalPath,
  }) {
    final now = DateTime.now();
    return LocalPhoto(
      id: 'photo_${now.millisecondsSinceEpoch}',
      albumName: albumName,
      fileName: fileName,
      localPath: localPath,
      caption: caption,
      tags: tags,
      dateTaken: dateTaken ?? now,
      dateAdded: now,
      latitude: latitude,
      longitude: longitude,
      location: location,
      people: people,
      fileSizeBytes: fileSizeBytes,
      width: width,
      height: height,
      originalPath: originalPath,
    );
  }

  /// Créer une copie avec modifications
  LocalPhoto copyWith({
    String? id,
    String? albumName,
    String? fileName,
    String? localPath,
    String? caption,
    List<String>? tags,
    DateTime? dateTaken,
    DateTime? dateAdded,
    double? latitude,
    double? longitude,
    String? location,
    List<String>? people,
    int? fileSizeBytes,
    int? width,
    int? height,
    bool? isFavorite,
    String? originalPath,
  }) {
    return LocalPhoto(
      id: id ?? this.id,
      albumName: albumName ?? this.albumName,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
      dateTaken: dateTaken ?? this.dateTaken,
      dateAdded: dateAdded ?? this.dateAdded,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      people: people ?? this.people,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      isFavorite: isFavorite ?? this.isFavorite,
      originalPath: originalPath ?? this.originalPath,
    );
  }

  /// Conversion en JSON pour stockage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'albumName': albumName,
      'fileName': fileName,
      'localPath': localPath,
      'caption': caption,
      'tags': tags,
      'dateTaken': dateTaken.toIso8601String(),
      'dateAdded': dateAdded.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'people': people,
      'fileSizeBytes': fileSizeBytes,
      'width': width,
      'height': height,
      'isFavorite': isFavorite,
      'originalPath': originalPath,
    };
  }

  /// Création depuis JSON
  factory LocalPhoto.fromJson(Map<String, dynamic> json) {
    return LocalPhoto(
      id: json['id'],
      albumName: json['albumName'],
      fileName: json['fileName'],
      localPath: json['localPath'],
      caption: json['caption'],
      tags: List<String>.from(json['tags'] ?? []),
      dateTaken: DateTime.parse(json['dateTaken']),
      dateAdded: DateTime.parse(json['dateAdded']),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      location: json['location'],
      people: List<String>.from(json['people'] ?? []),
      fileSizeBytes: json['fileSizeBytes'],
      width: json['width'],
      height: json['height'],
      isFavorite: json['isFavorite'] ?? false,
      originalPath: json['originalPath'],
    );
  }

  /// Obtenir la taille formatée du fichier
  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1048576) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / 1048576).toStringAsFixed(1)} MB';
  }

  /// Obtenir les dimensions formatées
  String get dimensionsFormatted {
    if (width == null || height == null) return 'Dimensions inconnues';
    return '${width}x$height px';
  }

  /// Vérifier si la photo a une localisation GPS
  bool get hasGpsLocation => latitude != null && longitude != null;

  /// Obtenir la date de prise de vue formatée
  String get dateTakenFormatted {
    return '${dateTaken.day.toString().padLeft(2, '0')}/'
        '${dateTaken.month.toString().padLeft(2, '0')}/'
        '${dateTaken.year}';
  }

  /// Obtenir l'heure de prise de vue formatée
  String get timeTakenFormatted {
    return '${dateTaken.hour.toString().padLeft(2, '0')}:'
        '${dateTaken.minute.toString().padLeft(2, '0')}';
  }

  /// Vérifier si la photo correspond à une recherche
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Recherche dans le nom de fichier
    if (fileName.toLowerCase().contains(lowerQuery)) return true;
    
    // Recherche dans la légende
    if (caption?.toLowerCase().contains(lowerQuery) == true) return true;
    
    // Recherche dans les tags
    if (tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) return true;
    
    // Recherche dans les personnes
    if (people.any((person) => person.toLowerCase().contains(lowerQuery))) return true;
    
    // Recherche dans le lieu
    if (location?.toLowerCase().contains(lowerQuery) == true) return true;
    
    // Recherche dans le nom d'album
    if (albumName.toLowerCase().contains(lowerQuery)) return true;
    
    return false;
  }

  /// Albums prédéfinis suggérés
  static List<String> get suggestedAlbums => [
    'Vacances 2025',
    'Anniversaires',
    'École & Activités',
    'Sorties Famille',
    'Fêtes & Célébrations',
    'Quotidien',
    'Nature & Animaux',
    'Cuisine',
    'DIY & Bricolage',
    'Amis',
  ];

  /// Tags populaires suggérés
  static List<String> get suggestedTags => [
    'famille',
    'vacances',
    'anniversaire',
    'nature',
    'cuisine',
    'bricolage',
    'sport',
    'école',
    'amis',
    'fête',
    'sortie',
    'animaux',
    'voyage',
    'maison',
    'jardinage',
  ];

  @override
  String toString() {
    return 'LocalPhoto(id: $id, fileName: $fileName, album: $albumName)';
  }
}