import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      return;
    }

    await client.auth.signInWithPassword(email: email, password: password);
  }

  bool get hasActiveSession => _client?.auth.currentSession != null;

  Stream<bool> get authStateChanges {
    final client = _client;
    if (client == null) {
      return const Stream<bool>.empty();
    }

    return client.auth.onAuthStateChange.map((event) => event.session != null);
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) {
      return;
    }

    await client.auth.signOut();
  }
}
