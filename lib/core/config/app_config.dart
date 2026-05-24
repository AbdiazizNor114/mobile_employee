class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'SHAQONET_API_BASE_URL',
        defaultValue: 'http://localhost:4000',
      ),
      supabaseUrl: String.fromEnvironment('SHAQONET_SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SHAQONET_SUPABASE_ANON_KEY'),
    );
  }

  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
