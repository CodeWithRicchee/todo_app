import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  String? _token;
  String? _userId;

  AuthProvider({required AuthService authService}) : _authService = authService;

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get userId => _userId;

  Future<void> signUp(String email, String password) async {
    final data = await _authService.signUp(email, password);
    _token = data['idToken'];
    _userId = data['localId'];
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final data = await _authService.signIn(email, password);
    _token = data['idToken'];
    _userId = data['localId'];
    notifyListeners();
  }

  /// Google sign-in using google_sign_in package and Firebase REST API
  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      // user cancelled
      return;
    }
    final googleAuth = await googleUser.authentication;
    final data = await _authService.signInWithGoogle(idToken: googleAuth.idToken!, accessToken: googleAuth.accessToken);
    _token = data['idToken'];
    _userId = data['localId'];
    notifyListeners();
  }

  void signOut() {
    _token = null;
    _userId = null;
    notifyListeners();
  }
}
