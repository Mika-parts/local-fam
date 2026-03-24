import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/family.dart';
import 'firestore_service.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();
  final Uuid _uuid = const Uuid();

  // Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // ============ INSCRIPTION AVEC CRÉATION DE FAMILLE ============

  Future<FamUser?> signUpWithFamily({
    required String email,
    required String password,
    required String displayName,
    required String familyName,
    String familyDescription = '',
  }) async {
    try {
      // 1. Créer l'utilisateur Firebase
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Erreur lors de la création du compte');
      }

      // 2. Mettre à jour le profil utilisateur
      await credential.user!.updateDisplayName(displayName);

      // 3. Générer un code d'invitation unique
      final inviteCode = await _firestore.generateUniqueInviteCode();

      // 4. Créer la famille
      final familyId = _uuid.v4();
      final family = Family(
        id: familyId,
        name: familyName,
        description: familyDescription,
        inviteCode: inviteCode,
        adminId: credential.user!.uid,
        memberIds: [credential.user!.uid],
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore.createFamily(family);

      // 5. Créer l'utilisateur dans Firestore
      final famUser = FamUser(
        id: credential.user!.uid,
        email: email,
        displayName: displayName,
        familyId: familyId,
        role: UserRole.admin,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isActive: true,
      );

      await _firestore.createUser(famUser);

      return famUser;
    } catch (e) {
      print('Erreur signUpWithFamily: $e');
      rethrow;
    }
  }

  // ============ INSCRIPTION AVEC CODE D'INVITATION ============

  Future<FamUser?> signUpWithInviteCode({
    required String email,
    required String password,
    required String displayName,
    required String inviteCode,
    required UserRole role,
  }) async {
    try {
      // 1. Vérifier que le code d'invitation existe
      final family = await _firestore.findFamilyByCode(inviteCode);
      if (family == null) {
        throw Exception('Code famille invalide ou inexistant');
      }

      // 2. Créer l'utilisateur Firebase
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Erreur lors de la création du compte');
      }

      // 3. Mettre à jour le profil
      await credential.user!.updateDisplayName(displayName);

      // 4. Créer une demande d'accès (pas d'ajout automatique)
      final requestId = await _firestore.createFamilyRequest(
        familyId: family.id,
        email: email,
        displayName: displayName,
        requestedRole: role,
        userId: credential.user!.uid,
      );

      // 5. Créer l'utilisateur en attente (sans famille pour l'instant)
      final famUser = FamUser(
        id: credential.user!.uid,
        email: email,
        displayName: displayName,
        familyId: '', // Vide en attendant validation
        role: UserRole.child, // Rôle temporaire
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isActive: true,
      );

      await _firestore.createUser(famUser);

      // 6. Notifier la famille de la demande
      await _firestore.notifyFamilyNewRequest(family.id, displayName);

      return famUser;
    } catch (e) {
      print('Erreur signUpWithInviteCode: $e');
      rethrow;
    }
  }

  // ============ CONNEXION ============

  Future<FamUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Connexion Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Erreur lors de la connexion');
      }

      // 2. Récupérer les données utilisateur
      final famUser = await _firestore.getUser(credential.user!.uid);
      if (famUser == null) {
        throw Exception('Utilisateur introuvable');
      }

      // 3. Mettre à jour lastSeen
      await _firestore.updateUserLastSeen(credential.user!.uid);

      return famUser;
    } catch (e) {
      print('Erreur signIn: $e');
      rethrow;
    }
  }

  // ============ DÉCONNEXION ============

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Erreur signOut: $e');
      rethrow;
    }
  }

  // ============ RÉINITIALISATION MOT DE PASSE ============

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Erreur resetPassword: $e');
      rethrow;
    }
  }

  // ============ GESTION DES DEMANDES FAMILLE ============

  Future<void> approveFamilyRequest(String requestId, String familyId) async {
    try {
      await _firestore.respondToFamilyRequest(requestId, true, familyId);
    } catch (e) {
      print('Erreur approveFamilyRequest: $e');
      rethrow;
    }
  }

  Future<void> rejectFamilyRequest(String requestId, String familyId) async {
    try {
      await _firestore.respondToFamilyRequest(requestId, false, familyId);
    } catch (e) {
      print('Erreur rejectFamilyRequest: $e');
      rethrow;
    }
  }

  // ============ UTILITAIRES ============

  Future<bool> isEmailAvailable(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isEmpty;
    } catch (e) {
      // Si l'email n'est pas valide, Firebase lance une exception
      return false;
    }
  }

  Future<bool> isFamilyCodeValid(String inviteCode) async {
    try {
      final family = await _firestore.findFamilyByCode(inviteCode);
      return family != null && family.isActive;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getFamilyNameByCode(String inviteCode) async {
    try {
      final family = await _firestore.findFamilyByCode(inviteCode);
      return family?.name;
    } catch (e) {
      return null;
    }
  }

  // ============ GESTION PROFIL ============

  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      // Mettre à jour dans Firestore
      final famUser = await _firestore.getUser(user.uid);
      if (famUser != null) {
        final updatedUser = famUser.copyWith(
          displayName: displayName ?? famUser.displayName,
          avatarUrl: avatarUrl ?? famUser.avatarUrl,
        );
        await _firestore.updateUser(updatedUser);
      }
    } catch (e) {
      print('Erreur updateProfile: $e');
      rethrow;
    }
  }

  // ============ VALIDATION EMAIL ============

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      print('Erreur sendEmailVerification: $e');
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      print('Erreur reloadUser: $e');
    }
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
}