import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local employee profile used for PIN identification on shared POS devices.
///
/// This is NOT a Supabase auth user — it's a lightweight local identity
/// that maps to a known team member. The owner configures these once
/// (via Settings → Team in a future screen); employees use them every shift.
class EmployeeProfile {
  final String id;
  final String name;
  final String pin; // 4-digit, plaintext for V1
  final String color; // hex color for avatar, e.g. '#1A73E8'

  const EmployeeProfile({
    required this.id,
    required this.name,
    required this.pin,
    required this.color,
  });

  /// Two uppercase initials derived from name.
  String get initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  /// First name only — used for compact display.
  String get firstName => name.split(' ').first;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pin': pin,
        'color': color,
      };

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) =>
      EmployeeProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        pin: json['pin'] as String,
        color: json['color'] as String? ?? '#1A73E8',
      );
}

/// Manages the list of employee profiles stored locally on the device.
///
/// Data is persisted in [SharedPreferences] as a JSON array.
/// Falls back to demo employees if no data has been saved yet.
class EmployeePinService {
  static const _prefsKey = 'scalario_employee_profiles';

  Future<List<EmployeeProfile>> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return _demoEmployees();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => EmployeeProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _demoEmployees();
    }
  }

  Future<void> saveEmployees(List<EmployeeProfile> employees) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(employees.map((e) => e.toJson()).toList()),
    );
  }

  // ── Supabase-user PIN (keyed by Supabase user ID) ────────────────────────

  static const _userPinPrefix = 'scalario_user_pin_';

  Future<String?> getUserPin(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_userPinPrefix$userId');
  }

  Future<void> saveUserPin(String userId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_userPinPrefix$userId', pin);
  }

  /// Returns true if [pin] matches the employee's stored PIN.
  bool validatePin(EmployeeProfile employee, String pin) =>
      employee.pin == pin;

  /// Demo employees — pre-loaded when no real team has been configured.
  /// Replace or extend via Settings → Équipe once that screen exists.
  List<EmployeeProfile> _demoEmployees() => const [
        EmployeeProfile(
          id: 'demo-1',
          name: 'Bernard Sawadogo',
          pin: '1234',
          color: '#1A73E8',
        ),
        EmployeeProfile(
          id: 'demo-2',
          name: 'Mariam Traoré',
          pin: '5678',
          color: '#34A853',
        ),
        EmployeeProfile(
          id: 'demo-3',
          name: 'Cheick Ouédraogo',
          pin: '0000',
          color: '#EA4335',
        ),
      ];
}
