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
