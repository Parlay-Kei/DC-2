import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Direct Cuts Supabase Project (shared with DC-1)
  static const String url = 'https://dskpfnjbgocieoqyiznf.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza3BmbmpiZ29jaWVvcXlpem5mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxMTkyODcsImV4cCI6MjA3OTY5NTI4N30.PzxcwYFGRYkTHMynjj389AfGmc3iFF9iN49gm0Tainc';

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static String? get currentUserId => currentUser?.id;

  static bool get isAuthenticated => currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
