import 'package:cloud_firestore/cloud_firestore.dart';

class FamUser {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final String familyId;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? lastSeen;
  final List<String> permissions;

  FamUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.familyId,
    this.avatarUrl,
    required this.createdAt,
    this.isActive = true,
    this.lastSeen,
    this.permissions = const [],
  });

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'familyId': familyId,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'permissions': permissions,
    };
  }

  // Conversion depuis Map Firestore
  factory FamUser.fromMap(Map<String, dynamic> map) {
    return FamUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.child,
      ),
      familyId: map['familyId'] ?? '',
      avatarUrl: map['avatarUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      lastSeen: map['lastSeen'] != null ? (map['lastSeen'] as Timestamp).toDate() : null,
      permissions: List<String>.from(map['permissions'] ?? []),
    );
  }

  // Copie avec modifications
  FamUser copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    String? familyId,
    String? avatarUrl,
    DateTime? createdAt,
    bool? isActive,
    DateTime? lastSeen,
    List<String>? permissions,
  }) {
    return FamUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      lastSeen: lastSeen ?? this.lastSeen,
      permissions: permissions ?? this.permissions,
    );
  }

  // Vérifications des permissions
  bool canCreateEvents() {
    return role == UserRole.parent || role == UserRole.admin;
  }

  bool canDeleteEvents() {
    return role == UserRole.admin || 
           (role == UserRole.parent && permissions.contains('delete_events'));
  }

  bool canInviteMembers() {
    return role == UserRole.parent || role == UserRole.admin;
  }

  bool canModifyFamily() {
    return role == UserRole.admin;
  }

  String get initials {
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0].substring(0, names[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '??';
  }
}

enum UserRole {
  admin,    // Créateur famille - tous droits
  parent,   // Parent - peut créer événements, inviter
  teenager, // Ado - peut créer événements
  child,    // Enfant - lecture seule + ses propres événements
  guest,    // Invité temporaire - lecture seule
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.parent:
        return 'Parent';
      case UserRole.teenager:
        return 'Adolescent';
      case UserRole.child:
        return 'Enfant';
      case UserRole.guest:
        return 'Invité';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.admin:
        return '👑';
      case UserRole.parent:
        return '👨‍👩‍👧‍👦';
      case UserRole.teenager:
        return '🧑‍🎓';
      case UserRole.child:
        return '🧒';
      case UserRole.guest:
        return '👥';
    }
  }

  int get priority {
    switch (this) {
      case UserRole.admin:
        return 5;
      case UserRole.parent:
        return 4;
      case UserRole.teenager:
        return 3;
      case UserRole.child:
        return 2;
      case UserRole.guest:
        return 1;
    }
  }
}