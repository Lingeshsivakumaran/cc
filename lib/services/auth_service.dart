// lib/services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '526220793959-iv8rcb9vc9s9asj4vsqp9moh36ulm9nh.apps.googleusercontent.com', // Replace with your actual server client ID
  );

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _supabase.auth.currentUser != null;

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user != null) {
        await _createUserProfile(response.user!);
      }

      return response;
    } on AuthException catch (e) {
      print('Supabase Auth Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> _createUserProfile(User user) async {
    try {
      // Check if profile already exists
      final existingProfile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Create new profile
        await _supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'full_name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'Unknown User',
          'avatar_url': user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error creating user profile: $e');
      // Don't throw here as the user is already signed in
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }
}