import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple wrapper around Firebase Authentication REST API.
class AuthService {
  final String apiKey;

  AuthService({required this.apiKey});

  Future<Map<String, dynamic>> signUp(String email, String password) async {
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
    final resp = await http.post(
      url,
      body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      throw Exception(data['error']['message']);
    }
    return data;
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
    final resp = await http.post(
      url,
      body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      throw Exception(data['error']['message']);
    }
    return data;
  }
}
