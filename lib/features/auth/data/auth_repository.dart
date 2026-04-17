import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

class AuthRepository {
  final SupabaseClient _client;
  bool isDeletingAccount = false;

  AuthRepository(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, String ipAddress, String fullName, {String? role}) async {
    return _client.auth.signUp(
      email: email, 
      password: password,
      data: {
        if (role != null) 'role': role,
        'full_name': fullName,
        'zzpl_document_version': 'v1.0',
        'zzpl_ip_address': ipAddress,
      },
    );
  }

  // We rely on Supabase DB Trigger to insert the consent row using the metadata 
  // passed above! Doing it purely in Flutter can cause 403 race conditions.

  Future<void> signInWithGoogle({String? role}) async {
    if (kIsWeb) {
      // For Web, use Supabase's native OAuth flow as it's more reliable than the deprecated GIS package for idToken
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb 
            ? '${Uri.base.origin}/app/' 
            : 'io.supabase.stanomer://login-callback',
        queryParams: {
          'prompt': 'select_account',
        },
      );
      // Note: On Web, the method redirects away and subsequent code is not executed here.
      // After redirect back, Dashboard will handle missing role selection.
      return;
    }

    // --- Native (Android/iOS) Flow ---
    const webClientId = '878572868059-t4tv89jhp0knmv96o0ek9ui93del8qt7.apps.googleusercontent.com';
    const iosClientId = '878572868059-0rneslhna37ulnlkh689lqla5urg62pv.apps.googleusercontent.com';
    
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) throw Exception('No ID Token found');

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    // After login, if we have a role selection, update the user metadata
    if (role != null || googleUser.displayName != null) {
      await _client.auth.updateUser(UserAttributes(
        data: {
          if (role != null) 'role': role,
          if (googleUser.displayName != null) 'full_name': googleUser.displayName,
          'zzpl_document_version': 'v1.0',
        },
      ));
    }
  }

  Future<void> signInWithApple({String? role}) async {
    final rawNonce = _client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) throw Exception('No ID Token found from Apple');

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // After login, if we have a role selection or name, update user metadata
    // Note: Apple only provides fullName on the FIRST sign in
    final fullName = credential.givenName != null 
        ? '${credential.givenName} ${credential.familyName ?? ''}'.trim()
        : null;

    if (role != null || fullName != null) {
      await _client.auth.updateUser(UserAttributes(
        data: {
          if (role != null) 'role': role,
          if (fullName != null) 'full_name': fullName,
          'zzpl_document_version': 'v1.0',
        },
      ));
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await GoogleSignIn().signOut();
  }

  Future<void> reauthenticate(String password) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) throw Exception('No user logged in');
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> updateProfile({String? fullName, String? role}) async {
    final user = _client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) throw Exception('User not logged in');

    // 1. Update User Metadata (Auth) ONLY if changed
    // This prevents infinite loops with GoRouter listeners
    final currentMetadata = user?.userMetadata ?? {};
    final needsMetaUpdate = (role != null && currentMetadata['role'] != role) || 
                             (fullName != null && currentMetadata['full_name'] != fullName);

    if (needsMetaUpdate) {
      await _client.auth.updateUser(UserAttributes(
        data: {
          if (fullName != null) 'full_name': fullName,
          if (role != null) 'role': role,
        },
      ));
    }

    // 2. Update Public Profiles Table using upsert
    // upsert ensures the row is created if it doesn't exist (e.g., Google sign up with no trigger)
    try {
      await _client
          .from('profiles')
          .upsert({
            'id': userId, // Required for upsert to link to the correct row
            'email': user?.email, // Sync email for notification discovery
            if (fullName != null) 'full_name': fullName,
            if (role != null) 'role': role,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
    } on PostgrestException catch (e) {
      throw Exception('Database Error: ${e.message} (Code: ${e.code}). Please ensure RLS INSERT/UPDATE policies are enabled for "profiles" table.');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(
      password: newPassword,
    ));
  }

  Future<void> deleteAccount() async {
    await _client.rpc('delete_own_account');
    await signOut();
  }
}
