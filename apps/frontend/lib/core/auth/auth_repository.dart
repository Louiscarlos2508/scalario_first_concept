import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profile.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> updateFullName(String fullName) async {
    // Stored in Supabase Auth user_metadata — no extra table column needed.
    await _supabase.auth.updateUser(
      UserAttributes(data: {'full_name': fullName}),
    );
  }

  /// Verifies [currentPassword] by re-authenticating. Throws if wrong.
  Future<void> verifyPassword(String currentPassword) async {
    final email = currentUser?.email;
    if (email == null) throw Exception('Utilisateur non connecté');
    await _supabase.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
  }

  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
  
  // Method to get all tenant IDs and Roles from organization_members
  Future<UserProfile?> getUserProfile() async {
    final user = currentUser;
    if (user == null) {
      debugPrint('[AuthRepo] No current user found.');
      return null;
    }

    try {
      debugPrint('[AuthRepo] Fetching profile for user: ${user.id}');
      final response = await _supabase
          .useSchema('kernel')
          .from('organization_members')
          .select('*, tenant:tenants(name), role:roles(name)')
          .eq('user_id', user.id);

      if (response == null) {
        debugPrint('[AuthRepo] Null response from organization_members fetch.');
        return null;
      }
      
      final rows = List<Map<String, dynamic>>.from(response as List);
      if (rows.isEmpty) {
        debugPrint('[AuthRepo] No organization memberships found for user: ${user.id}. Confirm RLS or manual data entry.');
        return null;
      }

      debugPrint('[AuthRepo] Found ${rows.length} memberships.');
      // full_name comes from Supabase Auth user_metadata, not the members table.
      final fullName = user.userMetadata?['full_name'] as String?;
      return UserProfile.fromMemberships(
          rows, user.email ?? '', user.id, fullName: fullName);
    } catch (e) {
      debugPrint('[AuthRepo] Error fetching user profile: $e');
      rethrow; // Rethrow to let FutureProvider handle the error state
    }
  }
}
