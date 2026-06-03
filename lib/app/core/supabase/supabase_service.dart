import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static const String _defaultUrl =
      'https://vppjkwwdaobdnfazdtci.supabase.co';
  static const String _defaultAnonKey =
      'sb_publishable_RyxjYM1aZrt55_FYGuqEAw_vFcPavQi';

  static bool _isInitialized = false;
  static bool _isConfigured = false;
  static String _url = _defaultUrl;

  static bool get isConfigured => _isConfigured;
  static String get anonKey => _defaultAnonKey;
  static String get supabaseUrl => _url;

  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    const String envUrl = String.fromEnvironment('SUPABASE_URL');
    const String envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    _url = envUrl.isEmpty ? _defaultUrl : envUrl;
    final String anonKey = envAnonKey.isEmpty ? _defaultAnonKey : envAnonKey;

    if (_url.isEmpty || anonKey.isEmpty) {
      _isInitialized = true;
      _isConfigured = false;
      return;
    }

    await Supabase.initialize(url: _url, anonKey: anonKey);
    _isInitialized = true;
    _isConfigured = true;
  }

  static SupabaseClient get client {
    if (!_isConfigured) {
      throw StateError(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
      );
    }
    return Supabase.instance.client;
  }
}
