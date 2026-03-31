import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_event.dart';
import '../models/local_photo.dart';
import '../models/local_note.dart';

/// Service pour gérer le stockage 100% local des données
class LocalStorageService {
  static const String _eventsKey = 'local_events';
  static const String _photosKey = 'local_photos';
  static const String _notesKey = 'local_notes';

  // Singleton
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late SharedPreferences _prefs;
  late Directory _appDir;

  /// Initialiser le service de stockage local
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _appDir = await getApplicationDocumentsDirectory();
  }

  // === ÉVÉNEMENTS ===

  /// Sauvegarder les événements localement
  Future<void> saveEvents(List<LocalEvent> events) async {
    final eventsJson = events.map((e) => e.toJson()).toList();
    await _prefs.setString(_eventsKey, jsonEncode(eventsJson));
  }

  /// Charger les événements depuis le stockage local
  Future<List<LocalEvent>> loadEvents() async {
    final eventsString = _prefs.getString(_eventsKey);
    if (eventsString == null) return [];

    final eventsList = jsonDecode(eventsString) as List;
    return eventsList.map((e) => LocalEvent.fromJson(e)).toList();
  }

  /// Ajouter un événement
  Future<void> addEvent(LocalEvent event) async {
    final events = await loadEvents();
    events.add(event);
    await saveEvents(events);
  }

  /// Supprimer un événement
  Future<void> removeEvent(String eventId) async {
    final events = await loadEvents();
    events.removeWhere((e) => e.id == eventId);
    await saveEvents(events);
  }

  // === PHOTOS ===

  /// Sauvegarder une photo localement
  Future<String> savePhoto(File photoFile, String albumName) async {
    final albumDir = Directory('${_appDir.path}/albums/$albumName');
    if (!await albumDir.exists()) {
      await albumDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = File('${albumDir.path}/$fileName');
    await photoFile.copy(savedFile.path);

    return savedFile.path;
  }

  /// Sauvegarder les métadonnées des photos
  Future<void> savePhotos(List<LocalPhoto> photos) async {
    final photosJson = photos.map((p) => p.toJson()).toList();
    await _prefs.setString(_photosKey, jsonEncode(photosJson));
  }

  /// Charger les métadonnées des photos
  Future<List<LocalPhoto>> loadPhotos() async {
    final photosString = _prefs.getString(_photosKey);
    if (photosString == null) return [];

    final photosList = jsonDecode(photosString) as List;
    return photosList.map((p) => LocalPhoto.fromJson(p)).toList();
  }

  /// Ajouter une photo
  Future<void> addPhoto(LocalPhoto photo) async {
    final photos = await loadPhotos();
    photos.add(photo);
    await savePhotos(photos);
  }

  /// Supprimer une photo (fichier + métadonnées)
  Future<void> removePhoto(String photoId) async {
    final photos = await loadPhotos();
    final photo = photos.firstWhere((p) => p.id == photoId);
    
    // Supprimer le fichier
    final file = File(photo.localPath);
    if (await file.exists()) {
      await file.delete();
    }

    // Supprimer les métadonnées
    photos.removeWhere((p) => p.id == photoId);
    await savePhotos(photos);
  }

  // === NOTES/JOURNAL ===

  /// Sauvegarder les notes du journal
  Future<void> saveNotes(List<LocalNote> notes) async {
    final notesJson = notes.map((n) => n.toJson()).toList();
    await _prefs.setString(_notesKey, jsonEncode(notesJson));
  }

  /// Charger les notes du journal
  Future<List<LocalNote>> loadNotes() async {
    final notesString = _prefs.getString(_notesKey);
    if (notesString == null) return [];

    final notesList = jsonDecode(notesString) as List;
    return notesList.map((n) => LocalNote.fromJson(n)).toList();
  }

  /// Ajouter une note
  Future<void> addNote(LocalNote note) async {
    final notes = await loadNotes();
    notes.add(note);
    await saveNotes(notes);
  }

  /// Supprimer une note
  Future<void> removeNote(String noteId) async {
    final notes = await loadNotes();
    notes.removeWhere((n) => n.id == noteId);
    await saveNotes(notes);
  }

  /// Modifier une note
  Future<void> updateNote(LocalNote updatedNote) async {
    final notes = await loadNotes();
    final index = notes.indexWhere((n) => n.id == updatedNote.id);
    if (index != -1) {
      notes[index] = updatedNote;
      await saveNotes(notes);
    }
  }

  // === UTILITAIRES ===

  /// Obtenir la taille utilisée par l'app
  Future<int> getStorageSize() async {
    int totalSize = 0;

    // Taille des albums photos
    final albumsDir = Directory('${_appDir.path}/albums');
    if (await albumsDir.exists()) {
      await for (final entity in albumsDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
    }

    return totalSize;
  }

  /// Exporter toutes les données vers un fichier JSON
  Future<File> exportData() async {
    final events = await loadEvents();
    final photos = await loadPhotos();
    final notes = await loadNotes();

    final exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'events': events.map((e) => e.toJson()).toList(),
      'photos': photos.map((p) => p.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
    };

    final exportFile = File('${_appDir.path}/local_family_export.json');
    await exportFile.writeAsString(jsonEncode(exportData));
    return exportFile;
  }

  /// Nettoyer le stockage (pour debugging)
  Future<void> clearAllData() async {
    await _prefs.remove(_eventsKey);
    await _prefs.remove(_photosKey);
    await _prefs.remove(_notesKey);

    // Supprimer le dossier albums
    final albumsDir = Directory('${_appDir.path}/albums');
    if (await albumsDir.exists()) {
      await albumsDir.delete(recursive: true);
    }
  }
}