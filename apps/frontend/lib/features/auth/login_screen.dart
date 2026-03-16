import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_logos.dart';

// ---------------------------------------------------------------------------
// State notifier local — isole la logique métier du widget.
// ---------------------------------------------------------------------------

class _LoginState {
  const _LoginState({
    this.isLoading = false,
    this.emailError,
    this.passwordError,
  });

  final bool isLoading;
  final String? emailError;
  final String? passwordError;

  _LoginState copyWith({
    bool? isLoading,
    // null = pas de changement, const _sentinel = effacer l'erreur
    Object? emailError = _sentinel,
    Object? passwordError = _sentinel,
  }) {
    return _LoginState(
      isLoading: isLoading ?? this.isLoading,
      emailError:
          emailError == _sentinel ? this.emailError : emailError as String?,
      passwordError: passwordError == _sentinel
          ? this.passwordError
          : passwordError as String?,
    );
  }

  bool get canSubmit =>
      !isLoading && emailError == null && passwordError == null;
}

const _sentinel = Object();

class _LoginNotifier extends StateNotifier<_LoginState> {
  _LoginNotifier() : super(const _LoginState());

  void validateEmail(String value) {
    final trimmed = value.trim();
    final error = trimmed.isEmpty
        ? 'Adresse e-mail requise'
        : !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)
            ? 'Format d\'e-mail invalide'
            : null;
    state = state.copyWith(emailError: error);
  }

  void validatePassword(String value) {
    final error = value.isEmpty
        ? 'Mot de passe requis'
        : value.length < 8
            ? 'Minimum 8 caractères'
            : null;
    state = state.copyWith(passwordError: error);
  }

  Future<void> signIn({
    required String email,
    required String password,
    required AuthRepository repo,
    required void Function(String) onError,
  }) async {
    validateEmail(email);
    validatePassword(password);
    if (state.emailError != null || state.passwordError != null) return;

    state = state.copyWith(isLoading: true);
    try {
      await repo.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // La navigation est gérée par authStateProvider dans main.dart.
    } on AuthException catch (e) {
      onError(e.message);
    } catch (_) {
      onError('Une erreur inattendue s\'est produite. Réessayez.');
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }
}

final _loginProvider =
    StateNotifierProvider.autoDispose<_LoginNotifier, _LoginState>(
  (_) => _LoginNotifier(),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) {
        ref
            .read(_loginProvider.notifier)
            .validateEmail(_emailController.text);
      }
    });
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) {
        ref
            .read(_loginProvider.notifier)
            .validatePassword(_passwordController.text);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit(_LoginState loginState, AuthRepository repo,
      ColorScheme colorScheme) {
    ref.read(_loginProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
          repo: repo,
          onError: (msg) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  msg,
                  style: TextStyle(color: colorScheme.onError),
                ),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
  }

  void _onForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réinitialisation du mot de passe — bientôt disponible.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(_loginProvider);
    final repo = ref.read(authRepositoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 64),

                // --- Logo ---
                SvgPicture.asset(
                  AppLogos.wordmarkPath(context),
                  width: 200,
                  fit: BoxFit.contain,
                  semanticsLabel: 'Scalario',
                ),

                const SizedBox(height: 48),

                // --- Formulaire ---
                Card(
                  color: colorScheme.surfaceContainerHigh,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email
                        Semantics(
                          label: 'Champ adresse e-mail',
                          child: TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            onFieldSubmitted: (_) => FocusScope.of(context)
                                .requestFocus(_passwordFocus),
                            decoration: _fieldDecoration(
                              colorScheme: colorScheme,
                              label: 'Adresse e-mail',
                              hint: 'exemple@domaine.com',
                              icon: Icons.email_outlined,
                              errorText: loginState.emailError,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Mot de passe
                        Semantics(
                          label: 'Champ mot de passe',
                          child: TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) =>
                                _submit(loginState, repo, colorScheme),
                            decoration: _fieldDecoration(
                              colorScheme: colorScheme,
                              label: 'Mot de passe',
                              icon: Icons.lock_outline,
                              errorText: loginState.passwordError,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                tooltip: _obscurePassword
                                    ? 'Afficher le mot de passe'
                                    : 'Masquer le mot de passe',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Mot de passe oublié
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: loginState.isLoading
                                ? null
                                : _onForgotPassword,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bouton Se connecter
                        Semantics(
                          label: loginState.isLoading
                              ? 'Connexion en cours'
                              : 'Se connecter',
                          button: true,
                          child: SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: loginState.isLoading
                                  ? null
                                  : () => _submit(loginState, repo, colorScheme),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: loginState.isLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required ColorScheme colorScheme,
    required String label,
    required IconData icon,
    String? hint,
    String? errorText,
    Widget? suffixIcon,
  }) {
    final radius = BorderRadius.circular(8);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      floatingLabelStyle: TextStyle(color: colorScheme.primary),
    );
  }
}
