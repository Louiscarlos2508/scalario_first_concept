import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/auth/auth_state.dart';
import '../providers/pos_providers.dart';
import '../screens/session_lock_screen.dart';

const kLockStatePrefKey = 'scalario_session_locked';

/// Wraps any widget and triggers [SessionLockScreen] after a configurable
/// period of inactivity (no pointer events).
///
/// - Timer resets on every pointer down/move within the wrapped area.
/// - Timeout value is read from [sessionLockTimeoutProvider] (-1 = disabled)
///   and persisted in SharedPreferences as [kLockTimeoutPrefKey].
/// - Place this inside [SessionGuard] so the lock only activates when a
///   session is actually open.
class SessionLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const SessionLockWrapper({super.key, required this.child});

  @override
  ConsumerState<SessionLockWrapper> createState() => _SessionLockWrapperState();
}

class _SessionLockWrapperState extends ConsumerState<SessionLockWrapper> {
  Timer? _timer;
  bool _prefsLoaded = false; // guard against flash of unlocked content

  @override
  void initState() {
    super.initState();
    _loadTimeoutPref();
  }

  /// Load persisted prefs and lock on startup if user has a PIN configured.
  Future<void> _loadTimeoutPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final saved = prefs.getInt(kLockTimeoutPrefKey);
    if (saved != null) {
      ref.read(sessionLockTimeoutProvider.notifier).state = saved;
    }

    // Check if current user has a PIN — lock only if they do.
    final employee = ref.read(selectedEmployeeProvider);
    bool hasPin;
    if (employee != null) {
      // Local employee: PIN is always configured
      hasPin = employee.pin.isNotEmpty;
    } else {
      // Supabase user: check stored PIN
      final userId = ref.read(userProfileProvider).valueOrNull?.id;
      if (userId != null) {
        final pin = await ref.read(employeePinServiceProvider).getUserPin(userId);
        hasPin = pin != null && pin.isNotEmpty;
      } else {
        hasPin = false;
      }
    }

    if (!mounted) return;
    if (hasPin) {
      ref.read(sessionLockedProvider.notifier).state = true;
    } else {
      _scheduleTimer();
    }
    setState(() => _prefsLoaded = true);
  }

  void _scheduleTimer() {
    _timer?.cancel();
    final timeout = ref.read(sessionLockTimeoutProvider);
    if (timeout <= 0) return; // disabled
    _timer = Timer(Duration(minutes: timeout), _onTimeout);
  }

  void _onTimeout() {
    if (mounted) ref.read(sessionLockedProvider.notifier).state = true;
  }

  void _onInteraction() {
    if (!ref.read(sessionLockedProvider)) _scheduleTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Persist lock state + restart timer on unlock.
    ref.listen(sessionLockedProvider, (_, locked) {
      SharedPreferences.getInstance()
          .then((p) => p.setBool(kLockStatePrefKey, locked));
      if (!locked) _scheduleTimer();
    });

    // Reschedule when timeout setting changes.
    ref.listen(sessionLockTimeoutProvider, (_, _) {
      if (!ref.read(sessionLockedProvider)) _scheduleTimer();
    });

    final isLocked = ref.watch(sessionLockedProvider);

    // Block content until prefs are read — prevents flash of unlocked state
    if (!_prefsLoaded) {
      return const ColoredBox(color: Color(0xFF0F172A));
    }

    return Listener(
      onPointerDown: (_) => _onInteraction(),
      onPointerMove: (_) => _onInteraction(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          widget.child,
          if (isLocked)
            const Positioned.fill(child: SessionLockScreen()),
        ],
      ),
    );
  }
}
