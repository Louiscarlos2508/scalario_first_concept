import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Welcome empty state — Figma 11:426 (première ouverture)
// Standalone widget, not used in the dashboard — reserved for onboarding flow.
// ══════════════════════════════════════════════════════════════════════════════

class WelcomeEmptyState extends StatelessWidget {
  final String firstName;
  final bool isDesktop;
  final VoidCallback onConfigureTap;
  final VoidCallback onAddProductsTap;
  final VoidCallback onInviteTeamTap;
  final VoidCallback onFirstSaleTap;

  const WelcomeEmptyState({
    super.key,
    required this.firstName,
    required this.isDesktop,
    required this.onConfigureTap,
    required this.onAddProductsTap,
    required this.onInviteTeamTap,
    required this.onFirstSaleTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = firstName.isEmpty ? '' : ' $firstName';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Greeting ──────────────────────────────────────────────────
        const SizedBox(height: 8),
        Text('Bienvenue$name !',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text(
          'Ta boutique est prête. Commence par enregistrer ta première vente.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),

        // ── Empty state card ──────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1.6,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            children: [
              const Text('\u{1F331}', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text('Pas encore de données',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const SizedBox(
                width: 290,
                child: Text(
                  'Une fois les premières ventes enregistrées, tu verras ici ton CA, tes alertes et ta marge en temps réel.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onConfigureTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Configurer ma boutique',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // ── Pour démarrer section ─────────────────────────────────────
        const Text('POUR DÉMARRER',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        OnboardingStep(
          emoji: '\u{1F4E6}',
          emojiBg: AppColors.chipSuccessBg,
          emojiColor: AppColors.success,
          title: '1. Ajouter mes produits',
          subtitle: 'Importer ou saisir le catalogue',
          onTap: onAddProductsTap,
        ),
        const SizedBox(height: 8),
        OnboardingStep(
          emoji: '\u{1F465}',
          emojiBg: AppColors.chipSuccessBg,
          emojiColor: AppColors.success,
          title: '2. Inviter mon équipe',
          subtitle: 'Gérante, vendeurs, commercial',
          onTap: onInviteTeamTap,
        ),
        const SizedBox(height: 8),
        OnboardingStep(
          emoji: '\u{1F4B3}',
          emojiBg: AppColors.chipSuccessBg,
          emojiColor: AppColors.success,
          title: '3. Première vente',
          subtitle: 'Ouvrir le POS',
          onTap: onFirstSaleTap,
        ),
      ],
    );
  }
}

class OnboardingStep extends StatelessWidget {
  final String emoji;
  final Color emojiBg;
  final Color emojiColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const OnboardingStep({
    super.key,
    required this.emoji,
    required this.emojiBg,
    required this.emojiColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: emojiBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(emoji,
                    style: TextStyle(fontSize: 20, color: emojiColor)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Text('\u203A',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
