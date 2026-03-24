import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family.dart';
import '../models/user.dart';
import '../models/event.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============ FAMILIES ============

  Future<void> createFamily(Family family) async {
    await _db.collection('families').doc(family.id).set(family.toMap());
  }

  Future<Family?> getFamily(String familyId) async {
    final doc = await _db.collection('families').doc(familyId).get();
    if (doc.exists) {
      return Family.fromMap(doc.data()!);
    }
    return null;
  }

  Future<Family?> getFamilyByInviteCode(String inviteCode) async {
    final query = await _db
        .collection('families')
        .where('inviteCode', isEqualTo: inviteCode)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return Family.fromMap(query.docs.first.data());
    }
    return null;
  }

  Future<void> addMemberToFamily(String familyId, String userId) async {
    await _db.collection('families').doc(familyId).update({
      'memberIds': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> removeMemberFromFamily(String familyId, String userId) async {
    await _db.collection('families').doc(familyId).update({
      'memberIds': FieldValue.arrayRemove([userId])
    });
  }

  Stream<Family?> getFamilyStream(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .snapshots()
        .map((doc) => doc.exists ? Family.fromMap(doc.data()!) : null);
  }

  // ============ USERS ============

  Future<void> createUser(FamUser user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<FamUser?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      return FamUser.fromMap(doc.data()!);
    }
    return null;
  }

  Future<List<FamUser>> getFamilyMembers(String familyId) async {
    final query = await _db
        .collection('users')
        .where('familyId', isEqualTo: familyId)
        .where('isActive', isEqualTo: true)
        .orderBy('role')
        .get();

    return query.docs
        .map((doc) => FamUser.fromMap(doc.data()))
        .toList();
  }

  Stream<List<FamUser>> getFamilyMembersStream(String familyId) {
    return _db
        .collection('users')
        .where('familyId', isEqualTo: familyId)
        .where('isActive', isEqualTo: true)
        .orderBy('role')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => FamUser.fromMap(doc.data()))
            .toList());
  }

  Future<void> updateUserLastSeen(String userId) async {
    await _db.collection('users').doc(userId).update({
      'lastSeen': Timestamp.now(),
    });
  }

  Future<void> updateUser(FamUser user) async {
    await _db.collection('users').doc(user.id).update(user.toMap());
  }

  // ============ EVENTS ============

  Future<void> createEvent(Event event) async {
    await _db.collection('events').doc(event.id).set(event.toMap());
  }

  Future<Event?> getEvent(String eventId) async {
    final doc = await _db.collection('events').doc(eventId).get();
    if (doc.exists) {
      return Event.fromMap(doc.data()!);
    }
    return null;
  }

  Future<List<Event>> getFamilyEvents(String familyId) async {
    final query = await _db
        .collection('events')
        .where('familyId', isEqualTo: familyId)
        .orderBy('startDate')
        .get();

    return query.docs
        .map((doc) => Event.fromMap(doc.data()))
        .toList();
  }

  Future<List<Event>> getFamilyEventsForMonth(String familyId, DateTime month) async {
    // Premier jour du mois
    final startOfMonth = DateTime(month.year, month.month, 1);
    // Premier jour du mois suivant
    final endOfMonth = DateTime(month.year, month.month + 1, 1);

    final query = await _db
        .collection('events')
        .where('familyId', isEqualTo: familyId)
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('startDate', isLessThan: Timestamp.fromDate(endOfMonth))
        .orderBy('startDate')
        .get();

    return query.docs
        .map((doc) => Event.fromMap(doc.data()))
        .toList();
  }

  Stream<List<Event>> getFamilyEventsStream(String familyId) {
    return _db
        .collection('events')
        .where('familyId', isEqualTo: familyId)
        .orderBy('startDate')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => Event.fromMap(doc.data()))
            .toList());
  }

  Stream<List<Event>> getFamilyEventsForDateStream(String familyId, DateTime date) {
    // Début de la journée
    final startOfDay = DateTime(date.year, date.month, date.day);
    // Fin de la journée
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _db
        .collection('events')
        .where('familyId', isEqualTo: familyId)
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('startDate')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => Event.fromMap(doc.data()))
            .toList());
  }

  Future<void> updateEvent(Event event) async {
    await _db.collection('events').doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
  }

  Future<List<Event>> getUserEvents(String userId) async {
    final query = await _db
        .collection('events')
        .where('createdBy', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .get();

    return query.docs
        .map((doc) => Event.fromMap(doc.data()))
        .toList();
  }

  // ============ QUERIES AVANCÉES ============

  Future<List<Event>> getUpcomingEvents(String familyId, {int limit = 10}) async {
    final now = Timestamp.now();
    
    final query = await _db
        .collection('events')
        .where('familyId', isEqualTo: familyId)
        .where('startDate', isGreaterThanOrEqualTo: now)
        .orderBy('startDate')
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => Event.fromMap(doc.data()))
        .toList();
  }

  Future<List<Event>> getEventsByType(String familyId, EventType type) async {
    final query = await _db
        .collection('events')
        .where('familyId', isEqualTo: familyId)
        .where('type', isEqualTo: type.name)
        .orderBy('startDate', descending: true)
        .get();

    return query.docs
        .map((doc) => Event.fromMap(doc.data()))
        .toList();
  }

  // ============ STATISTIQUES ============

  Future<Map<EventType, int>> getEventTypeStats(String familyId) async {
    final query = await _db
        .collection('events')
        .where('familyId', isEqualTo: familyId)
        .get();

    final Map<EventType, int> stats = {};
    
    for (final type in EventType.values) {
      stats[type] = 0;
    }

    for (final doc in query.docs) {
      final event = Event.fromMap(doc.data());
      stats[event.type] = (stats[event.type] ?? 0) + 1;
    }

    return stats;
  }
}