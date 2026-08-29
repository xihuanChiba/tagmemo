import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_config.dart';

class AuthService {
  Session? get session =>
      CloudConfig.enabled ? Supabase.instance.client.auth.currentSession : null;

  User? get user => session?.user;

  Stream<AuthState>? get authChanges => CloudConfig.enabled
      ? Supabase.instance.client.auth.onAuthStateChange
      : null;

  Future<void> signInWithGoogle() async {
    if (!CloudConfig.enabled) {
      throw StateError('Cloud sync is not configured.');
    }
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: CloudConfig.oauthRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    if (!CloudConfig.enabled) return;
    await Supabase.instance.client.auth.signOut();
  }
}
