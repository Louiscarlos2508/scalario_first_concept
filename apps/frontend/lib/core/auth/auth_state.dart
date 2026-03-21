import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'auth_repository.dart';
import 'user_profile.dart';

// Provider for the AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// Stream provider for auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  
  // Emit current session immediately
  final session = repo.currentSession;
  final event = session != null ? AuthChangeEvent.signedIn : AuthChangeEvent.signedOut;
  yield AuthState(event, session);
  
  // Then yield subsequent changes from the stream
  yield* repo.authStateChanges;
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (state) async {
      if (state.session == null) return null;
      final profile = await ref.read(authRepositoryProvider).getUserProfile();
      
      if (profile != null) {
        ref.read(activeTenantProvider.notifier).state = profile.primaryTenantId;
      } else {
        ref.read(activeTenantProvider.notifier).state = null;
      }
      
      return profile;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Currently selected branch/tenant ID
final activeTenantProvider = StateProvider<String?>((ref) => null);
