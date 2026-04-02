import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/pos/data/services/employee_pin_service.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/session_lock_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Full-screen lock overlay shown after inactivity timeout.
///
/// Behaviour:
/// - If a local employee is identified (shared terminal / owner role):
///   validate against their stored PIN.
/// - If no local employee (cashier/commercial with own Supabase account):
///   show a simple "Reprendre" button (PIN can be added in V2).
///
/// "Ce n'est pas moi" clears the identified employee → [SessionGuard]
/// routes back to [EmployeePinScreen] automatically.
class SessionLockScreen extends ConsumerStatefulWidget {
  const SessionLockScreen({super.key});

  @override
  ConsumerState<SessionLockScreen> createState() => _SessionLockScreenState();
}

class _SessionLockScreenState extends ConsumerState<SessionLockScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _digits = [];
  bool _hasError = false;

  // PIN for Supabase-authenticated users (loaded once)
  String? _userPin;
  bool _userPinChecked = false;

  late final AnimationController _shakeCtrl;
  late final Animation<Offset> _shakeAnim;

  static const _kDark = Color(0xFF0F172A);

  static final _keyToDigit = {
    LogicalKeyboardKey.digit0: '0', LogicalKeyboardKey.digit1: '1',
    LogicalKeyboardKey.digit2: '2', LogicalKeyboardKey.digit3: '3',
    LogicalKeyboardKey.digit4: '4', LogicalKeyboardKey.digit5: '5',
    LogicalKeyboardKey.digit6: '6', LogicalKeyboardKey.digit7: '7',
    LogicalKeyboardKey.digit8: '8', LogicalKeyboardKey.digit9: '9',
    LogicalKeyboardKey.numpad0: '0', LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.numpad2: '2', LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.numpad4: '4', LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.numpad6: '6', LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.numpad8: '8', LogicalKeyboardKey.numpad9: '9',
  };

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final digit = _keyToDigit[event.logicalKey];
    if (digit != null) {
      _onDigit(digit, ref.read(selectedEmployeeProvider));
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      _onBackspace();
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: Offset.zero, end: const Offset(-0.04, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(
              begin: const Offset(-0.04, 0), end: const Offset(0.04, 0)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(
              begin: const Offset(0.04, 0), end: const Offset(-0.04, 0)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(-0.04, 0), end: Offset.zero),
          weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── PIN logic ────────────────────────────────────────────────────────────────

  void _onDigit(String d, EmployeeProfile? employee) {
    if (_digits.length >= 4) return;
    setState(() {
      _digits.add(d);
      _hasError = false;
    });
    if (_digits.length == 4) _validate(employee);
  }

  void _onBackspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  void _validate(EmployeeProfile? employee) {
    final expected = employee?.pin ?? _userPin;
    if (expected == null) return;
    if (expected == _digits.join()) {
      _unlock();
    } else {
      setState(() {
        _hasError = true;
        _digits.clear();
      });
      _shakeCtrl.forward(from: 0);
    }
  }

  void _unlock() {
    ref.read(sessionLockedProvider.notifier).state = false;
  }

  void _notMe(EmployeeProfile? employee) {
    // Clear persisted lock so logout doesn't leave a phantom lock on next login
    SharedPreferences.getInstance()
        .then((p) => p.remove(kLockStatePrefKey));
    if (employee != null) {
      // Shared device: clear identified employee → SessionGuard re-shows EmployeePinScreen
      ref.read(selectedEmployeeProvider.notifier).state = null;
    } else {
      // Own account: sign out
      ref.read(authRepositoryProvider).signOut();
    }
    ref.read(sessionLockedProvider.notifier).state = false;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final employee = ref.watch(selectedEmployeeProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    // Load Supabase user PIN once
    if (!_userPinChecked && employee == null && profile != null) {
      _userPinChecked = true;
      ref.read(employeePinServiceProvider).getUserPin(profile.id).then((p) {
        if (mounted) setState(() => _userPin = p);
      });
    }

    final name = employee?.name ??
        profile?.fullName ??
        profile?.email ??
        'Utilisateur';
    final initials = _initials(name);
    final avatarColor = employee != null
        ? Color(int.parse(employee.color.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return ColoredBox(
      color: _kDark,
      child: PopScope(
        canPop: false,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lock icon
                  const Icon(Icons.lock_outline, size: 32, color: Colors.white38),
                  const SizedBox(height: 20),

                  // Avatar
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: avatarColor,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Session verrouillée',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 32),

                  if (employee != null) ...[
                    // PIN dots
                    SlideTransition(
                      position: _shakeAnim,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) {
                          final filled = i < _digits.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _hasError
                                  ? Colors.red
                                  : filled
                                      ? Colors.white
                                      : Colors.white24,
                              border: Border.all(
                                color: _hasError
                                    ? Colors.red
                                    : Colors.white38,
                                width: 1.5,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    if (_hasError) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'PIN incorrect',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Numpad
                    _Numpad(
                      onDigit: (d) => _onDigit(d, employee),
                      onBackspace: _onBackspace,
                    ),
                  ] else if (_userPin != null) ...[
                    // Supabase user with PIN configured → validate it
                    SlideTransition(
                      position: _shakeAnim,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) {
                          final filled = i < _digits.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _hasError
                                  ? Colors.red
                                  : filled
                                      ? Colors.white
                                      : Colors.white24,
                              border: Border.all(
                                color: _hasError ? Colors.red : Colors.white38,
                                width: 1.5,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    if (_hasError) ...[
                      const SizedBox(height: 8),
                      const Text('PIN incorrect',
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 24),
                    _Numpad(
                      onDigit: (d) => _onDigit(d, null),
                      onBackspace: _onBackspace,
                    ),
                  ] else ...[
                    // Supabase user without PIN → simple unlock
                    const Text(
                      'Appuyez pour reprendre votre session.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _unlock,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(200, 48),
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Reprendre'),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // "Ce n'est pas moi"
                  TextButton(
                    onPressed: () => _notMe(employee),
                    child: Text(
                      employee != null
                          ? "Ce n'est pas moi"
                          : 'Changer de compte',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }
}

// ── Numeric keypad ────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const _Numpad({required this.onDigit, required this.onBackspace});

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 72, height: 56);
            final isBackspace = key == '⌫';
            return _NumKey(
              label: key,
              isBackspace: isBackspace,
              onTap: isBackspace ? onBackspace : () => onDigit(key),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final bool isBackspace;
  final VoidCallback onTap;

  const _NumKey({
    required this.label,
    required this.isBackspace,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 56,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: isBackspace
            ? const Icon(Icons.backspace_outlined,
                color: Colors.white70, size: 20)
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
