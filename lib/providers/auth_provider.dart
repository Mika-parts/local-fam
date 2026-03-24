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

  // ============ GESTION DEMANDES FAMILLE (NOUVEAU) ============

  Future<List<Map<String, dynamic>>> getFamilyRequests() async {
    if (_currentFamily == null) return [];

    try {
      return await _firestoreService.getFamilyRequests(_currentFamily!.id);
    } catch (e) {
      _setError('Erreur lors du chargement des demandes: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getFamilyRequestsStream() {
    if (_currentFamily == null) {
      return Stream.value([]);
    }

    return _firestoreService.getFamilyRequestsStream(_currentFamily!.id)
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }).toList());
  }

  Future<bool> approveFamilyRequest(String requestId) async {
    if (_currentFamily == null) return false;

    try {
      _setLoading(true);
      await _authService.approveFamilyRequest(requestId, _currentFamily!.id);
      
      // Recharger la famille pour mettre à jour la liste des membres
      await _loadFamilyData(_currentFamily!.id);
      
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'acceptation: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectFamilyRequest(String requestId) async {
    if (_currentFamily == null) return false;

    try {
      _setLoading(true);
      await _authService.rejectFamilyRequest(requestId, _currentFamily!.id);
      return true;
    } catch (e) {
      _setError('Erreur lors du refus: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<int> countPendingRequests() async {
    if (_currentFamily == null) return 0;

    try {
      return await _firestoreService.countPendingRequests(_currentFamily!.id);
    } catch (e) {
      return 0;
    }
  }

  Future<bool> isFamilyCodeValid(String code) async {
    try {
      return await _authService.isFamilyCodeValid(code);
    } catch (e) {
      return false;
    }
  }

  Future<String?> getFamilyNameByCode(String code) async {
    try {
      return await _authService.getFamilyNameByCode(code);
    } catch (e) {
      return null;
    }
  }

  // ============ MÉTHODES UTILITAIRES FAMILLE ============

  Future<void> _loadFamilyData(String familyId) async {
    try {
      _currentFamily = await _firestoreService.getFamily(familyId);
      notifyListeners();
    } catch (e) {
      print('Erreur _loadFamilyData: $e');
    }
  }

  Future<void> regenerateInviteCode() async {
    if (_currentFamily == null || !canModifyFamily()) return;

    try {
      _setLoading(true);
      final newCode = await _firestoreService.generateUniqueInviteCode();
      
      // Mettre à jour la famille avec le nouveau code
      final updatedFamily = _currentFamily!.copyWith(inviteCode: newCode);
      await _firestoreService.createFamily(updatedFamily); // Utilise set pour mettre à jour
      
      _currentFamily = updatedFamily;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la génération du nouveau code: $e');
    } finally {
      _setLoading(false);
    }
  }

  String? get familyInviteCode => _currentFamily?.inviteCode;
  
  List<String> get familyMembers => _currentFamily?.memberIds ?? [];
  
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  
  bool get isParent => _currentUser?.role == UserRole.parent || isAdmin;
}