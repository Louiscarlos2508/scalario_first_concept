import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_repository.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _StubAuthRepo implements AuthRepository {
  @override
  Session? get currentSession => null;
  @override
  User? get currentUser => null;
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
  @override
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> signOut() async {}
  @override
  Future<UserProfile?> getUserProfile() async => null;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateFullName(String fullName) async {}

  @override
  Future<void> changePassword(String newPassword) async {}

  @override
  Future<void> verifyPassword(String currentPassword) async {}
}

void main() {
  testWidgets('App starts with LoginScreen when unauthenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_StubAuthRepo()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
