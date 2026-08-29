import 'package:supabase_flutter/supabase_flutter.dart';

class CloudConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const oauthRedirectUrl = String.fromEnvironment(
    'OAUTH_REDIRECT_URL',
    defaultValue: 'tagmemo://login-callback',
  );

  static bool get enabled =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!enabled) return;
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
}
