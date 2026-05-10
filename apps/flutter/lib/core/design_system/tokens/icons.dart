import 'package:flutter/material.dart';

import 'colors.dart';

/// Tailles d'icônes — toujours utiliser ces tokens, jamais un nombre brut.
abstract final class ScalarioIconSize {
  static const double xs = 16;
  static const double sm = 20;
  static const double md = 24;
  static const double lg = 32;
}

/// Tokens icônes Scalario.
///
/// Source de vérité : `design-process/D-Design-System/tokens/icons.md`
/// (validée 2026-05-09).
///
/// Convention :
/// - Style par défaut = `_outlined` (variant Material aéré).
/// - Style actif = filled (sans suffixe) — uniquement pour BottomNav active tab,
///   filtres actifs, états sélectionnés.
/// - Marques tierces (WhatsApp) = SVG asset, jamais `IconData`.
abstract final class ScalarioIcons {
  // ---------------------------------------------------------------------------
  // Navigation — outlined par défaut, filled = actif
  // ---------------------------------------------------------------------------
  static const IconData navDashboard = Icons.home_outlined;
  static const IconData navDashboardActive = Icons.home;

  static const IconData navSales = Icons.shopping_cart_outlined;
  static const IconData navSalesActive = Icons.shopping_cart;

  static const IconData navStock = Icons.inventory_2_outlined;
  static const IconData navStockActive = Icons.inventory_2;

  static const IconData navReports = Icons.bar_chart_outlined;
  static const IconData navReportsActive = Icons.bar_chart;

  /// Historique : pas de variante outlined dans Material — même icône pour
  /// repos et actif (la sélection est marquée par couleur + label).
  static const IconData navHistory = Icons.history;
  static const IconData navHistoryActive = Icons.history;

  static const IconData navTeam = Icons.group_outlined;
  static const IconData navTeamActive = Icons.group;

  static const IconData navOps = Icons.assignment_outlined;
  static const IconData navOpsActive = Icons.assignment;

  static const IconData navSettings = Icons.settings_outlined;
  static const IconData navSettingsActive = Icons.settings;

  // ---------------------------------------------------------------------------
  // Actions — toolbar, AppBar, ActionButton
  // ---------------------------------------------------------------------------
  static const IconData actionAdd = Icons.add;
  static const IconData actionEdit = Icons.edit_outlined;
  static const IconData actionDelete = Icons.delete_outline;
  static const IconData actionConfirm = Icons.check;
  static const IconData actionClose = Icons.close;
  static const IconData actionBack = Icons.arrow_back;
  static const IconData actionSearch = Icons.search;
  static const IconData actionFilter = Icons.tune_outlined;
  static const IconData actionSend = Icons.send_outlined;
  static const IconData actionDownload = Icons.download_outlined;
  static const IconData actionPrint = Icons.print_outlined;
  static const IconData actionCopy = Icons.content_copy_outlined;
  static const IconData actionMore = Icons.more_vert;
  static const IconData actionView = Icons.visibility_outlined;
  static const IconData actionHide = Icons.visibility_off_outlined;

  // ---------------------------------------------------------------------------
  // Feedback & État — couleur associée disponible via `stateColor`
  // ---------------------------------------------------------------------------
  static const IconData stateNotifBell = Icons.notifications_outlined;
  static const IconData stateSyncActive = Icons.sync;
  static const IconData stateSyncOffline = Icons.cloud_off_outlined;
  static const IconData stateError = Icons.error_outline;
  static const IconData stateWarning = Icons.warning_amber_rounded;
  static const IconData stateSuccess = Icons.check_circle_outline;
  static const IconData stateInfo = Icons.info_outline;
  static const IconData stateLoading = Icons.refresh;

  /// Couleur recommandée pour un icône d'état. Renvoie `null` quand aucune
  /// couleur sémantique forte n'est imposée par le DS (texte hérite alors du
  /// contexte). Spec : `tokens/icons.md` → section "Feedback & État".
  static Color? stateColor(IconData icon) {
    if (icon == stateNotifBell) return ScalarioColors.neutral700;
    if (icon == stateSyncActive) return ScalarioColors.primary500;
    if (icon == stateSyncOffline) return ScalarioColors.warning500;
    if (icon == stateError) return ScalarioColors.danger500;
    if (icon == stateWarning) return ScalarioColors.warning500;
    if (icon == stateSuccess) return ScalarioColors.success500;
    if (icon == stateInfo) return ScalarioColors.primary700;
    if (icon == stateLoading) return ScalarioColors.neutral500;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Métier — POS & Caisse
  // ---------------------------------------------------------------------------
  static const IconData bizPos = Icons.point_of_sale_outlined;
  static const IconData bizCash = Icons.payments_outlined;
  static const IconData bizMobileMoney = Icons.phone_android_outlined;
  static const IconData bizCredit = Icons.credit_score_outlined;
  static const IconData bizReceipt = Icons.receipt_outlined;
  static const IconData bizInvoice = Icons.description_outlined;
  static const IconData bizChange = Icons.currency_exchange;

  // ---------------------------------------------------------------------------
  // Métier — Stock & Produits
  // ---------------------------------------------------------------------------
  static const IconData bizProduct = Icons.inventory_outlined;
  static const IconData bizDelivery = Icons.local_shipping_outlined;
  static const IconData bizSupplier = Icons.store_outlined;
  static const IconData bizLoss = Icons.delete_sweep_outlined;
  static const IconData bizInventory = Icons.fact_check_outlined;
  static const IconData bizAlert = Icons.notifications_active_outlined;
  static const IconData bizTransfer = Icons.swap_horiz;

  // ---------------------------------------------------------------------------
  // Partage & Connectivité
  // ---------------------------------------------------------------------------
  /// WhatsApp : SVG custom (marque propriétaire — jamais `IconData`).
  /// Charger via `SvgPicture.asset(ScalarioIcons.whatsappAsset)`.
  static const String whatsappAsset = 'assets/icons/whatsapp.svg';

  static const IconData shareSms = Icons.sms_outlined;
  static const IconData shareEmail = Icons.email_outlined;
  static const IconData shareBluetooth = Icons.bluetooth;
  static const IconData shareBluetoothScan = Icons.bluetooth_searching;
  static const IconData sharePdf = Icons.picture_as_pdf_outlined;

  // ---------------------------------------------------------------------------
  // UI Primitives — chevrons, flèches, conteneurs vides
  // ---------------------------------------------------------------------------
  /// Chevron `›` pour KPICard tappable, ListTile drill-down.
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData chevronLeft = Icons.chevron_left;

  /// Flèches de tri DataTable (header sortable).
  static const IconData arrowUp = Icons.arrow_upward;
  static const IconData arrowDown = Icons.arrow_downward;

  /// Conteneur vide — état empty d'une liste/table.
  static const IconData inbox = Icons.inbox_outlined;

  /// Graphique générique — état empty d'un ChartBar.
  static const IconData chart = Icons.bar_chart_outlined;

  // ---------------------------------------------------------------------------
  // Aliases sémantiques — feedback (raccourcis pour AlertBanner)
  // ---------------------------------------------------------------------------
  /// Alias `state*` raccourcis pour les composants feedback.
  /// Pointent vers les mêmes `IconData` que `stateError`/`stateWarning`/etc.
  static const IconData error = stateError;
  static const IconData alert = stateWarning;
  static const IconData warning = stateWarning;
  static const IconData check = stateSuccess;
  static const IconData info = stateInfo;

  // ---------------------------------------------------------------------------
  // Administration
  // ---------------------------------------------------------------------------
  static const IconData adminTenant = Icons.business_outlined;
  static const IconData adminDeploy = Icons.rocket_launch_outlined;
  static const IconData adminMonitor = Icons.monitor_heart_outlined;
  static const IconData adminLogs = Icons.article_outlined;
  static const IconData adminBilling = Icons.receipt_long_outlined;
  static const IconData adminSupport = Icons.headset_mic_outlined;
  static const IconData adminUser = Icons.person_outlined;
}
