import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://umwhpmzmrgmevgpmklvx.supabase.co';
  
  // Fallback for development - replace with your actual key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'your_actual_supabase_anon_key_here' // Replace this!
  );
  
  static Future<void> initialize() async {
    if (supabaseAnonKey == 'your_actual_supabase_anon_key_here') {
      if (kDebugMode) {
        print('WARNING: Using default Supabase key. Please set SUPABASE_KEY environment variable.');
      }
    }
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}
