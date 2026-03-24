import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  final String id;
  final String name;
  final String description;
  final String adminId;
  final String inviteCode;
  final DateTime createdAt;
  final bool isActive;
  final List<String> memberIds;
  final FamilySettings settings;

  Family({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.inviteCode,
    required this.createdAt,
    this.isActive = true,
    this.memberIds = const [],
    required this.settings,
  });

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'adminId': adminId,
      'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'memberIds': memberIds,
      'settings': settings.toMap(),
    };
  }

  // Conversion depuis Map Firestore
  factory Family.fromMap(Map<String, dynamic> map) {
    return Family(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      adminId: map['adminId'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      memberIds: List<String>.from(map['memberIds'] ?? []),
      settings: FamilySettings.fromMap(map['settings'] ?? {}),
    );
  }

  // Copie avec modifications
  Family copyWith({
    String? id,
    String? name,
    String? description,
    String? adminId,
    String? inviteCode,
    DateTime? createdAt,
    bool? isActive,
    List<String>? memberIds,
    FamilySettings? settings,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      memberIds: memberIds ?? this.memberIds,
      settings: settings ?? this.settings,
    );
  }

  int get memberCount => memberIds.length;
}

class FamilySettings {
  final bool allowChildrenCreateEvents;
  final bool requireApprovalForEvents;
  final bool enableNotifications;
  final bool enableEmailNotifications;
  final List<String> allowedEventTypes;
  final int maxMembers;
  final bool isPublic;

  FamilySettings({
    this.allowChildrenCreateEvents = false,
    this.requireApprovalForEvents = false,
    this.enableNotifications = true,
    this.enableEmailNotifications = false,
    this.allowedEventTypes = const [],
    this.maxMembers = 10,
    this.isPublic = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'allowChildrenCreateEvents': allowChildrenCreateEvents,
      'requireApprovalForEvents': requireApprovalForEvents,
      'enableNotifications': enableNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'allowedEventTypes': allowedEventTypes,
      'maxMembers': maxMembers,
      'isPublic': isPublic,
    };
  }

  factory FamilySettings.fromMap(Map<String, dynamic> map) {
    return FamilySettings(
      allowChildrenCreateEvents: map['allowChildrenCreateEvents'] ?? false,
      requireApprovalForEvents: map['requireApprovalForEvents'] ?? false,
      enableNotifications: map['enableNotifications'] ?? true,
      enableEmailNotifications: map['enableEmailNotifications'] ?? false,
      allowedEventTypes: List<String>.from(map['allowedEventTypes'] ?? []),
      maxMembers: map['maxMembers'] ?? 10,
      isPublic: map['isPublic'] ?? false,
    );
  }

  FamilySettings copyWith({
    bool? allowChildrenCreateEvents,
    bool? requireApprovalForEvents,
    bool? enableNotifications,
    bool? enableEmailNotifications,
    List<String>? allowedEventTypes,
    int? maxMembers,
    bool? isPublic,
  }) {
    return FamilySettings(
      allowChildrenCreateEvents: allowChildrenCreateEvents ?? this.allowChildrenCreateEvents,
      requireApprovalForEvents: requireApprovalForEvents ?? this.requireApprovalForEvents,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      allowedEventTypes: allowedEventTypes ?? this.allowedEventTypes,
      maxMembers: maxMembers ?? this.maxMembers,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}