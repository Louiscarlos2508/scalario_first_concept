import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/app_breakpoints.dart';

void main() {
  group('AppColors', () {
    test('primary is Bleu confiance #1565C0', () {
      expect(AppColors.primary, const Color(0xFF1565C0));
    });
    test('success is Vert #2E7D32', () {
      expect(AppColors.success, const Color(0xFF2E7D32));
    });
    test('error is Rouge #C62828', () {
      expect(AppColors.error, const Color(0xFFC62828));
    });
    test('warning is Jaune #F9A825', () {
      expect(AppColors.warning, const Color(0xFFF9A825));
    });
    test('surface is white #FFFFFF', () {
      expect(AppColors.surface, const Color(0xFFFFFFFF));
    });
    test('background is Fond app #F5F5F5', () {
      expect(AppColors.background, const Color(0xFFF5F5F5));
    });
    test('textPrimary is #212121', () {
      expect(AppColors.textPrimary, const Color(0xFF212121));
    });
    test('textSecondary is #757575', () {
      expect(AppColors.textSecondary, const Color(0xFF757575));
    });
    test('border is #E0E0E0', () {
      expect(AppColors.border, const Color(0xFFE0E0E0));
    });
  });

  group('AppTextStyles', () {
    test('displayMedium is 22sp Bold textPrimary', () {
      expect(AppTextStyles.displayMedium.fontSize, 22);
      expect(AppTextStyles.displayMedium.fontWeight, FontWeight.bold);
      expect(AppTextStyles.displayMedium.color, AppColors.textPrimary);
    });
    test('titleLarge is 18sp SemiBold textPrimary', () {
      expect(AppTextStyles.titleLarge.fontSize, 18);
      expect(AppTextStyles.titleLarge.fontWeight, FontWeight.w600);
      expect(AppTextStyles.titleLarge.color, AppColors.textPrimary);
    });
    test('titleMedium is 16sp SemiBold textPrimary', () {
      expect(AppTextStyles.titleMedium.fontSize, 16);
      expect(AppTextStyles.titleMedium.fontWeight, FontWeight.w600);
      expect(AppTextStyles.titleMedium.color, AppColors.textPrimary);
    });
    test('bodyMedium is 14sp Regular textPrimary', () {
      expect(AppTextStyles.bodyMedium.fontSize, 14);
      expect(AppTextStyles.bodyMedium.fontWeight, FontWeight.normal);
      expect(AppTextStyles.bodyMedium.color, AppColors.textPrimary);
    });
    test('bodySmall is 12sp Regular textSecondary', () {
      expect(AppTextStyles.bodySmall.fontSize, 12);
      expect(AppTextStyles.bodySmall.fontWeight, FontWeight.normal);
      expect(AppTextStyles.bodySmall.color, AppColors.textSecondary);
    });
    test('labelSmall is 11sp Medium textSecondary', () {
      expect(AppTextStyles.labelSmall.fontSize, 11);
      expect(AppTextStyles.labelSmall.fontWeight, FontWeight.w500);
      expect(AppTextStyles.labelSmall.color, AppColors.textSecondary);
    });
    test('headlineLarge is 20sp Bold monospace textPrimary', () {
      expect(AppTextStyles.headlineLarge.fontSize, 20);
      expect(AppTextStyles.headlineLarge.fontWeight, FontWeight.bold);
      expect(AppTextStyles.headlineLarge.fontFamily, 'monospace');
      expect(AppTextStyles.headlineLarge.color, AppColors.textPrimary);
    });
    test('headlineMedium is 18sp Bold monospace textPrimary', () {
      expect(AppTextStyles.headlineMedium.fontSize, 18);
      expect(AppTextStyles.headlineMedium.fontWeight, FontWeight.bold);
      expect(AppTextStyles.headlineMedium.fontFamily, 'monospace');
      expect(AppTextStyles.headlineMedium.color, AppColors.textPrimary);
    });
  });

  group('AppTheme.light() — component minimum sizes (Fitts law)', () {
    late ThemeData theme;

    setUpAll(() {
      theme = AppTheme.light();
    });

    test('ElevatedButton minimumSize is 64x48 (Fitts ≥ 48dp)', () {
      final style = theme.elevatedButtonTheme.style!;
      final size = style.minimumSize!.resolve({});
      expect(size, const Size(64, 48));
    });

    test('FilledButton minimumSize is 88x56 (primary CTA)', () {
      final style = theme.filledButtonTheme.style!;
      final size = style.minimumSize!.resolve({});
      expect(size, const Size(88, 56));
    });

    test('Card elevation is 0', () {
      expect(theme.cardTheme.elevation, 0);
    });

    test('useMaterial3 is true', () {
      expect(theme.useMaterial3, true);
    });

    test('scaffoldBackgroundColor is AppColors.background', () {
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });

    test('primary color in colorScheme is AppColors.primary', () {
      expect(theme.colorScheme.primary, AppColors.primary);
    });

    test('error color in colorScheme is AppColors.error', () {
      expect(theme.colorScheme.error, AppColors.error);
    });
  });

  group('Breakpoints', () {
    test('kCompact is 600.0', () {
      expect(kCompact, 600.0);
    });
    test('kMedium is 1024.0', () {
      expect(kMedium, 1024.0);
    });
    test('kCompact < kMedium', () {
      expect(kCompact, lessThan(kMedium));
    });
  });
}
