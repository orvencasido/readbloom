class BackendConfig {
  static const supabaseUrl = 'https://msicdkvxjocwhabmybem.supabase.co';
  static const supabasePublishableKey =
      'sb_publishable_taTBXwu8i0PEeg11Dz-2BA_4DG7XJ_b';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
