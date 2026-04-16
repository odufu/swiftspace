import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://krwkcilbitlsbivkcuns.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtyd2tjaWxiaXRsc2JpdmtjdW5zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNzIzMTAsImV4cCI6MjA5MTg0ODMxMH0.KWC6lP-fm5DYCQngG64zFDlj67Q3WpClGiBVM2XFPyA';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  SupabaseClient get client => Supabase.instance.client;
}
