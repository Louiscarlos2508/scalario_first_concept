import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_logos.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/data/services/employee_pin_service.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

/// Full-screen kiosk screen for employee identification via PIN.
///
/// Flow:
///   View A — Employee selection (cards grid)
///   View B — PIN entry (4-digit keypad)
///
/// On successful PIN → writes [selectedEmployeeProvider] → [SessionGuard]
/// detects the change and proceeds to [OpenSessionScreen].
class EmployeePinScreen extends ConsumerStatefulWidget {
  const EmployeePinScreen({super.key});

  @override
  ConsumerState<EmployeePinScreen> createState() => _EmployeePinScreenState();
}

enum _View { selection, pin }

class _EmployeePinScreenState extends ConsumerState<EmployeePinScreen>
    with SingleTickerProviderStateMixin {
  _View _view = _View.selection;
  EmployeeProfile? _selected;
  final List<String> _digits = [];
  bool _hasError = false;

  late final AnimationController _shakeCtrl;
  late final Animation<Offset> _shakeAnim;

  static const _kDark = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.04, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.04, 0), end: const Offset(0.04, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.04, 0), end: const Offset(-0.04, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.04, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _shakeCtrl.dispose();
    super.dispose();
  }

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
    if (event is! KeyDownEvent || _view != _View.pin) return false;
    final digit = _keyToDigit[event.logicalKey];
    if (digit != null) { _onDigit(digit); return true; }
    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      _onBackspace(); return true;
    }
    return false;
  }

  // ── PIN logic ────────────────────────────────────────────────────────────────

  void _onDigit(String d) {
    if (_digits.length >= 4) return;
    setState(() {
      _digits.add(d);
      _hasError = false;
    });
    if (_digits.length == 4) _validate();
  }

  void _onBackspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  void _validate() {
    final service = ref.read(employeePinServiceProvider);
    if (service.validatePin(_selected!, _digits.join())) {
      ref.read(selectedEmployeeProvider.notifier).state = _selected;
      // SessionGuard will react and show OpenSessionScreen
    } else {
      setState(() => _hasError = true);
      _shakeCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _digits.clear());
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _view == _View.selection
            ? _SelectionView(
                key: const ValueKey('selection'),
                onSelected: (e) => setState(() => _selected = e),
                selected: _selected,
                onContinue: () => setState(() {
                  _view = _View.pin;
                  _digits.clear();
                  _hasError = false;
                }),
              )
            : _PinView(
                key: const ValueKey('pin'),
                employee: _selected!,
                digits: _digits,
                hasError: _hasError,
                shakeAnim: _shakeAnim,
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                onBack: () => setState(() {
                  _view = _View.selection;
                  _digits.clear();
                  _hasError = false;
                }),
              ),
      ),
    );
  }
}

// ── View A — Employee selection ───────────────────────────────────────────────

class _SelectionView extends ConsumerWidget {
  final EmployeeProfile? selected;
  final void Function(EmployeeProfile) onSelected;
  final VoidCallback onContinue;

  const _SelectionView({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantName = ref
            .watch(userProfileProvider)
            .valueOrNull
            ?.memberships
            .firstOrNull
            ?.tenantName ??
        'Scalario';

    return SafeArea(
      child: FutureBuilder<List<EmployeeProfile>>(
        future: ref.read(employeePinServiceProvider).getEmployees(),
        builder: (context, snapshot) {
          final employees = snapshot.data ?? [];

          return Column(
            children: [
              const SizedBox(height: 40),

              // ── Logo ──────────────────────────────────────────────────────
              SvgPicture.asset(AppLogos.wordmarkDark, width: 148, fit: BoxFit.contain),
              const SizedBox(height: 10),
              Text(
                tenantName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE d MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 48),

              // ── Title ──────────────────────────────────────────────────────
              const Text(
                'Qui êtes-vous ?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),

              // ── Employee cards ─────────────────────────────────────────────
              Expanded(
                child: employees.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun employé configuré.\nContactez le propriétaire.',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 160,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: employees.length,
                          itemBuilder: (_, i) => _EmployeeCard(
                            employee: employees[i],
                            isSelected: selected?.id == employees[i].id,
                            onTap: () => onSelected(employees[i]),
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 28),

              // ── CTA ────────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: selected == null ? null : onContinue,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    label: const Text(
                      'Continuer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

// ── View B — PIN entry ────────────────────────────────────────────────────────

class _PinView extends StatelessWidget {
  final EmployeeProfile employee;
  final List<String> digits;
  final bool hasError;
  final Animation<Offset> shakeAnim;
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onBack;

  const _PinView({
    super.key,
    required this.employee,
    required this.digits,
    required this.hasError,
    required this.shakeAnim,
    required this.onDigit,
    required this.onBackspace,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Back ──────────────────────────────────────────────────────────
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white60),
                onPressed: onBack,
              ),
            ),
          ),

          const Spacer(flex: 2),

          // ── Avatar + name ─────────────────────────────────────────────────
          EmployeeAvatar(employee: employee, size: 72),
          const SizedBox(height: 14),
          Text(
            employee.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasError ? 'PIN incorrect — réessayez' : 'Entrez votre PIN',
            style: TextStyle(
              color: hasError ? const Color(0xFFEF5350) : Colors.white54,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 36),

          // ── PIN dots ──────────────────────────────────────────────────────
          SlideTransition(
            position: shakeAnim,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < digits.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasError
                        ? const Color(0xFFEF5350)
                        : filled
                            ? Colors.white
                            : Colors.transparent,
                    border: (!filled && !hasError)
                        ? Border.all(color: Colors.white38, width: 1.5)
                        : null,
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 48),

          // ── Numpad ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: _NumPad(onDigit: onDigit, onBackspace: onBackspace),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// ── Employee card ─────────────────────────────────────────────────────────────

class _EmployeeCard extends StatelessWidget {
  final EmployeeProfile employee;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmployeeCard({
    required this.employee,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmployeeAvatar(employee: employee, size: 54),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                employee.firstName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (employee.name.contains(' '))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  employee.name.split(' ').skip(1).join(' '),
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Employee avatar ───────────────────────────────────────────────────────────

/// Colored circle avatar with employee initials.
/// Exported so other widgets (e.g. POS topbar) can reuse it.
class EmployeeAvatar extends StatelessWidget {
  final EmployeeProfile employee;
  final double size;

  const EmployeeAvatar({super.key, required this.employee, required this.size});

  Color _color() {
    try {
      return Color(int.parse(employee.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: _color(), shape: BoxShape.circle),
      child: Center(
        child: Text(
          employee.initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.34,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Numeric keypad ────────────────────────────────────────────────────────────

class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const _NumPad({required this.onDigit, required this.onBackspace});

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
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 72, height: 72);
              return _NumKey(
                label: key,
                onTap: key == '⌫' ? onBackspace : () => onDigit(key),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NumKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: label == '⌫'
              ? const Icon(Icons.backspace_outlined, color: Colors.white70, size: 22)
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
        ),
      ),
    );
  }
}
