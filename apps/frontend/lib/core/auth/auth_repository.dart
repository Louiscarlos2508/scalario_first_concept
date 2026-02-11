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

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Method to get all tenant IDs and Roles from organization_members
  Future<UserProfile?> getUserProfile() async {
    final user = currentUser;
    if (user == null) {
      print('[AuthRepo] No current user found.');
      return null;
    }

    try {
      print('[AuthRepo] Fetching profile for user: ${user.id}');
      final response = await _supabase
          .from('organization_members')
          .select('*, tenant:tenants(name)')
          .eq('user_id', user.id);

      if (response == null) {
        print('[AuthRepo] Null response from organization_members fetch.');
        return null;
      }
      
      final rows = List<Map<String, dynamic>>.from(response as List);
      if (rows.isEmpty) {
        print('[AuthRepo] No organization memberships found for user: ${user.id}. Confirm RLS or manual data entry.');
        return null;
      }

      print('[AuthRepo] Found ${rows.length} memberships.');
      return UserProfile.fromMemberships(rows, user.email ?? '', user.id);
    } catch (e) {
      print('[AuthRepo] Error fetching user profile: $e');
      rethrow; // Rethrow to let FutureProvider handle the error state
    }
  }
}
