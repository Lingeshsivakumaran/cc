import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace these with your actual Supabase project credentials
  static const String supabaseUrl = 'https://umwhpmzmrgmevgpmklvx.supabase.co';
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_KEY'); // Fetch from environment variables
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}