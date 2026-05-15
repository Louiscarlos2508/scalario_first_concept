import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/sandbox/sandbox_user_context.dart';

void main() {
  group('SandboxUserContextProvider', () {
    test('default preset is OWNER', () {
      final provider = SandboxUserContextProvider();
      expect(provider.preset, SandboxUserPreset.owner);
      expect(provider.current.roles, contains('OWNER'));
    });

    test('selectPreset switches roles and notifies', () {
      final provider = SandboxUserContextProvider();
      int notifications = 0;
      provider.addListener(() => notifications++);

      provider.selectPreset(SandboxUserPreset.cashier);

      expect(provider.preset, SandboxUserPreset.cashier);
      expect(provider.current.roles, contains('CASHIER'));
      expect(notifications, 1);
    });

    test('custom preset requires JSON, surfaces error', () {
      final provider = SandboxUserContextProvider();
      provider.selectPreset(SandboxUserPreset.custom);
      expect(provider.customError, isNotNull);

      provider.applyCustomJson('not json');
      expect(provider.customError, contains('JSON'));

      provider.applyCustomJson('{"roles":["MANAGER"]}');
      expect(provider.customError, isNull);
      expect(provider.current.roles, contains('MANAGER'));
    });

    test('custom JSON requires non-empty roles array', () {
      final provider = SandboxUserContextProvider();
      provider.applyCustomJson('{}');
      expect(provider.customError, contains('roles'));
    });
  });
}
