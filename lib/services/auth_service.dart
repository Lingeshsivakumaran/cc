import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> signInWithGoogle() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google, // ✅ Correct usage in supabase_flutter v1.10+
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } catch (e) {
      print("Google sign-in error: $e");
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
   bool get isSignedIn {

    // Replace with your actual logic to check if the user is signed in

    return supabase.auth.currentSession != null;


  }
  Stream<bool> get authStateChanges {

    // Replace with actual implementation for auth state changes

    return Stream.value(isSignedIn);

  }


}


