import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/backend_config.dart';

class SupabaseService {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static SupabaseClient? get client {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (_initialized || !BackendConfig.isConfigured) return;

    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabasePublishableKey,
    );
    _initialized = true;
  }
}
