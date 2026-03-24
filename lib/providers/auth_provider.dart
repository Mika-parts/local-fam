import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../models/family.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class FamAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  FamUser? _currentUser;
  Family? _currentFamily;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  FamUser? get currentUser => _currentUser;
  Family? get currentFamily => _currentFamily;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  FamAuthProvider() {
    _initialize();
  }

  void _initialize() {
    // Écouter les changements d'authentification
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
        _currentFamily = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      _setLoading(true);
      
      // Charger les données utilisateur
      _currentUser = await _firestoreService.getUser(userId);
      
      if (_currentUser != null) {
        // Charger les données famille
        _currentFamily = await _firestoreService.getFamily(_currentUser!.familyId);
      }
      
      _clearError();
    } catch (e) {
      _setError('Erreur lors du chargement des données: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Inscription avec création de famille
  Future<bool> signUpWithFamily({
    required String email,
    required String password,
    required String displayName,
    required String familyName,
    String familyDescription = '',
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final famUser = await _authService.signUpWithFamily(
        email: email,
        password: password,
        displayName: displayName,
        familyName: familyName,
        familyDescription: familyDescription,
      );

      if (famUser != null) {
        _currentUser = famUser;
        _currentFamily = await _firestoreService.getFamily(famUser.familyId);
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Inscription avec code d'invitation
  Future<bool> signUpWithInviteCode({
    required String email,
    required String password,
    required String displayName,
    required String inviteCode,
    required UserRole role,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final famUser = await _authService.signUpWithInviteCode(
        email: email,
        password: password,
        displayName: displayName,
        inviteCode: inviteCode,
        role: role,
      );

      if (famUser != null) {
        _currentUser = famUser;
        _currentFamily = await _firestoreService.getFamily(famUser.familyId);
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Connexion
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final famUser = await _authService.signIn(
        email: email,
        password: password,
      );

      if (famUser != null) {
        _currentUser = famUser;
        _currentFamily = await _firestoreService.getFamily(famUser.familyId);
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      
      _currentUser = null;
      _currentFamily = null;
      _clearError();
    } catch (e) {
      _setError('Erreur lors de la déconnexion: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Réinitialiser mot de passe
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mettre à jour les données utilisateur
  Future<void> updateUserProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);
      
      final updatedUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      );

      await _firestoreService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la mise à jour: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Méthodes utilitaires
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cet email.';
        case 'wrong-password':
          return 'Mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé.';
        case 'weak-password':
          return 'Le mot de passe est trop faible.';
        case 'invalid-email':
          return 'L\'email n\'est pas valide.';
        default:
          return 'Erreur d\'authentification: ${error.message}';
      }
    }
    return error.toString();
  }

  // Vérifier les permissions
  bool canCreateEvents() {
    return _currentUser?.canCreateEvents() ?? false;
  }

  bool canDeleteEvents() {
    return _currentUser?.canDeleteEvents() ?? false;
  }

  bool canInviteMembers() {
    return _currentUser?.canInviteMembers() ?? false;
  }

  bool canModifyFamily() {
    return _currentUser?.canModifyFamily() ?? false;
  }
}