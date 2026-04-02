import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_logos.dart';

// ── Palette (matches login-prototype.html) ────────────────────────────────────

const _kBg        = Colors.white;
const _kSlate900  = Color(0xFF0F172A);
const _kSlate700  = Color(0xFF374151);
const _kSlate400  = Color(0xFF94A3B8);
const _kSlate200  = Color(0xFFE2E8F0);
const _kSlate100  = Color(0xFFF1F5F9);
const _kSlate50   = Color(0xFFF8FAFC);
const _kBlue      = Color(0xFF1A73E8);

// ── Tab enum ──────────────────────────────────────────────────────────────────

enum _Tab { login, signup }

// ── Screen ────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  _Tab _tab = _Tab.login;
  bool _loading = false;

  // Login
  final _loginEmailCtrl    = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  bool _obscureLoginPwd    = true;
  String? _loginEmailError;
  String? _loginPasswordError;

  // Signup
  final _signupNameCtrl     = TextEditingController();
  final _signupEmailCtrl    = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  bool _obscureSignupPwd    = true;

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submitLogin() async {
    final email    = _loginEmailCtrl.text.trim();
    final password = _loginPasswordCtrl.text;
    setState(() {
      _loginEmailError = email.isEmpty
          ? 'Adresse e-mail requise'
          : !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
              ? 'Format invalide'
              : null;
      _loginPasswordError = password.isEmpty ? 'Mot de passe requis' : null;
    });
    if (_loginEmailError != null || _loginPasswordError != null) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Navigation handled by authStateProvider in main.dart
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitSignup() async {
    final name     = _signupNameCtrl.text.trim();
    final email    = _signupEmailCtrl.text.trim();
    final password = _signupPasswordCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Tous les champs sont requis.');
      return;
    }
    if (password.length < 8) {
      _showError('Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signUp(
        email: email,
        password: password,
        fullName: name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé ! Vérifiez votre e-mail pour confirmer.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Une erreur inattendue s\'est produite.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(onBack: Navigator.of(context).canPop()
                  ? () => Navigator.of(context).pop()
                  : null),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        _tab == _Tab.login
                            ? 'Bon retour !'
                            : 'Créez votre compte',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _kSlate900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tab == _Tab.login
                            ? 'Connectez-vous pour accéder à votre espace.'
                            : 'Rejoignez Scalario et commencez à gérer votre boutique.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: _kSlate400,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tab switcher
                      _TabSwitcher(
                        active: _tab,
                        onSelect: (t) => setState(() {
                          _tab = t;
                          _loginEmailError = null;
                          _loginPasswordError = null;
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Form (no animation — instant swap, simpler)
                      if (_tab == _Tab.login)
                        _buildLoginForm()
                      else
                        _buildSignupForm(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('Adresse e-mail'),
        const SizedBox(height: 6),
        _InputField(
          controller: _loginEmailCtrl,
          hint: 'exemple@domaine.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: _loginEmailError,
          onChanged: (_) => setState(() => _loginEmailError = null),
        ),
        const SizedBox(height: 16),

        _FieldLabel('Mot de passe'),
        const SizedBox(height: 6),
        _PasswordField(
          controller: _loginPasswordCtrl,
          obscure: _obscureLoginPwd,
          hint: '8 caractères minimum',
          errorText: _loginPasswordError,
          onToggle: () => setState(() => _obscureLoginPwd = !_obscureLoginPwd),
          onChanged: (_) => setState(() => _loginPasswordError = null),
          onSubmit: _loading ? null : _submitLogin,
        ),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _onForgotPassword,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Mot de passe oublié ?',
              style: TextStyle(fontSize: 13, color: _kBlue),
            ),
          ),
        ),

        const SizedBox(height: 8),
        _PrimaryButton(
          label: 'Se connecter',
          onPressed: _loading ? null : _submitLogin,
          loading: _loading,
        ),
        const SizedBox(height: 20),
        const _Divider(),
        const SizedBox(height: 20),
        _OtpButton(onTap: _onOtpTap),
        const SizedBox(height: 20),
        const _LegalText(),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _InviteBanner(),
        const SizedBox(height: 20),

        _FieldLabel('Votre nom complet'),
        const SizedBox(height: 6),
        _InputField(
          controller: _signupNameCtrl,
          hint: 'Ex : Bernard Ouédraogo',
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        _FieldLabel('Adresse e-mail'),
        const SizedBox(height: 6),
        _InputField(
          controller: _signupEmailCtrl,
          hint: 'exemple@domaine.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        _FieldLabel('Mot de passe'),
        const SizedBox(height: 6),
        _PasswordField(
          controller: _signupPasswordCtrl,
          obscure: _obscureSignupPwd,
          hint: '8 caractères minimum',
          onToggle: () => setState(() => _obscureSignupPwd = !_obscureSignupPwd),
          onSubmit: _loading ? null : _submitSignup,
        ),
        const SizedBox(height: 4),
        const Text(
          'Utilisé pour sécuriser votre compte',
          style: TextStyle(fontSize: 12, color: _kSlate400),
        ),

        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Créer mon compte',
          onPressed: _loading ? null : _submitSignup,
          loading: _loading,
        ),
        const SizedBox(height: 20),
        const _Divider(),
        const SizedBox(height: 20),
        _OtpButton(onTap: _onOtpTap),
        const SizedBox(height: 20),
        const _LegalText(),
      ],
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

  void _onOtpTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connexion par téléphone — bientôt disponible.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback? onBack;
  const _TopBar({this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: _kSlate100)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kSlate50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kSlate200),
                ),
                child: const Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          AppLogos.monogram(context, size: 28),
        ],
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  final _Tab active;
  final ValueChanged<_Tab> onSelect;

  const _TabSwitcher({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kSlate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TabBtn(
            label: 'Créer un compte',
            active: active == _Tab.signup,
            onTap: () => onSelect(_Tab.signup),
          ),
          _TabBtn(
            label: 'Se connecter',
            active: active == _Tab.login,
            onTap: () => onSelect(_Tab.login),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? _kSlate900 : _kSlate400,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Form atoms ────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _kSlate700,
      ),
    );
  }
}

InputDecoration _buildInputDecoration({
  String? hint,
  String? errorText,
  Widget? suffix,
}) {
  const radius = BorderRadius.all(Radius.circular(12));
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _kSlate400, fontSize: 15),
    errorText: errorText,
    errorStyle: const TextStyle(fontSize: 12),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    border: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: _kSlate200, width: 1.5),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: _kSlate200, width: 1.5),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: _kBlue, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Colors.red, width: 1.5),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Colors.red, width: 2),
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autocorrect: false,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, color: _kSlate900),
      decoration: _buildInputDecoration(hint: hint, errorText: errorText),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmit;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, color: _kSlate900),
      decoration: _buildInputDecoration(
        hint: hint,
        errorText: errorText,
        suffix: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: _kSlate400,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ── CTA + secondary ───────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kBlue.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          shadowColor: _kBlue.withValues(alpha: 0.4),
          elevation: onPressed != null ? 4 : 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _kSlate200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou continuer avec',
            style: TextStyle(
              fontSize: 12,
              color: _kSlate400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _kSlate200)),
      ],
    );
  }
}

class _OtpButton extends StatelessWidget {
  final VoidCallback onTap;
  const _OtpButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.phone_outlined, size: 18, color: _kSlate700),
      label: const Text(
        'Continuer avec le téléphone (OTP)',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _kSlate700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: _kSlate50,
        side: const BorderSide(color: _kSlate200, width: 1.5),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _LegalText extends StatelessWidget {
  const _LegalText();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      const TextSpan(
        text: 'En continuant, vous acceptez les ',
        children: [
          TextSpan(
            text: 'Conditions d\'utilisation',
            style: TextStyle(color: _kBlue),
          ),
          TextSpan(text: ' et la '),
          TextSpan(
            text: 'Politique de confidentialité',
            style: TextStyle(color: _kBlue),
          ),
          TextSpan(text: ' de Scalario.'),
        ],
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        color: _kSlate400,
        height: 1.6,
      ),
    );
  }
}

// ── Invitation banner ─────────────────────────────────────────────────────────

class _InviteBanner extends StatelessWidget {
  const _InviteBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
        ),
        border: Border.all(color: const Color(0xFF86EFAC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invitation de votre intégrateur',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Boutique pré-configurée · Prêt à démarrer',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
