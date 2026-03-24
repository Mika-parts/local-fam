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

  // Stream de l'utilisateur connecté
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Inscription avec création de famille
  Future<FamUser?> signUpWithFamily({
    required String email,
    required String password,
    required String displayName,
    required String familyName,
    String familyDescription = '',
  }) async {
    try {
      // Créer compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Mettre à jour le profil
        await credential.user!.updateDisplayName(displayName);

        // Générer invite code unique
        final inviteCode = _generateInviteCode();

        // Créer la famille
        final family = Family(
          id: _uuid.v4(),
          name: familyName,
          description: familyDescription,
          adminId: credential.user!.uid,
          inviteCode: inviteCode,
          createdAt: DateTime.now(),
          memberIds: [credential.user!.uid],
          settings: FamilySettings(),
        );

        await _firestore.createFamily(family);

        // Créer l'utilisateur FamUser
        final famUser = FamUser(
          id: credential.user!.uid,
          email: email,
          displayName: displayName,
          role: UserRole.admin,
          familyId: family.id,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
        );

        await _firestore.createUser(famUser);
        return famUser;
      }
    } catch (e) {
      print('Erreur inscription: $e');
      rethrow;
    }
    return null;
  }

  // Inscription avec rejoin famille existante
  Future<FamUser?> signUpWithInviteCode({
    required String email,
    required String password,
    required String displayName,
    required String inviteCode,
    required UserRole role,
  }) async {
    try {
      // Vérifier que le code d'invitation existe
      final family = await _firestore.getFamilyByInviteCode(inviteCode);
      if (family == null) {
        throw Exception('Code d\'invitation invalide');
      }

      // Créer compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Mettre à jour le profil
        await credential.user!.updateDisplayName(displayName);

        // Créer l'utilisateur FamUser
        final famUser = FamUser(
          id: credential.user!.uid,
          email: email,
          displayName: displayName,
          role: role,
          familyId: family.id,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
        );

        await _firestore.createUser(famUser);

        // Ajouter l'utilisateur à la famille
        await _firestore.addMemberToFamily(family.id, credential.user!.uid);

        return famUser;
      }
    } catch (e) {
      print('Erreur inscription avec code: $e');
      rethrow;
    }
    return null;
  }

  // Connexion
  Future<FamUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Récupérer les données utilisateur
        final famUser = await _firestore.getUser(credential.user!.uid);
        
        if (famUser != null) {
          // Mettre à jour lastSeen
          await _firestore.updateUserLastSeen(famUser.id);
        }

        return famUser;
      }
    } catch (e) {
      print('Erreur connexion: $e');
      rethrow;
    }
    return null;
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Réinitialiser mot de passe
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Générer code d'invitation unique
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    
    for (int i = 0; i < 6; i++) {
      code += chars[(random + i) % chars.length];
    }
    
    return code;
  }

  // Obtenir données utilisateur actuel
  Future<FamUser?> getCurrentFamUser() async {
    final user = currentUser;
    if (user != null) {
      return await _firestore.getUser(user.uid);
    }
    return null;
  }
}