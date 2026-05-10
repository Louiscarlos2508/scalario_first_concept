// Smoke tests icônes : chaque token résout en `IconData` non-null + chaque
// taille respecte la spec markdown.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/design_system/tokens/colors.dart';
import 'package:scalario/core/design_system/tokens/icons.dart';

void main() {
  group('ScalarioIconSize — sync spec', () {
    test('xs = 16', () => expect(ScalarioIconSize.xs, 16));
    test('sm = 20', () => expect(ScalarioIconSize.sm, 20));
    test('md = 24', () => expect(ScalarioIconSize.md, 24));
    test('lg = 32', () => expect(ScalarioIconSize.lg, 32));
  });

  group('Navigation — outlined + filled non-null', () {
    final List<IconData> navIcons = <IconData>[
      ScalarioIcons.navDashboard,
      ScalarioIcons.navDashboardActive,
      ScalarioIcons.navSales,
      ScalarioIcons.navSalesActive,
      ScalarioIcons.navStock,
      ScalarioIcons.navStockActive,
      ScalarioIcons.navReports,
      ScalarioIcons.navReportsActive,
      ScalarioIcons.navHistory,
      ScalarioIcons.navHistoryActive,
      ScalarioIcons.navTeam,
      ScalarioIcons.navTeamActive,
      ScalarioIcons.navOps,
      ScalarioIcons.navOpsActive,
      ScalarioIcons.navSettings,
      ScalarioIcons.navSettingsActive,
    ];

    test('Tous les tokens nav non-null', () {
      for (final IconData icon in navIcons) {
        expect(icon, isNotNull);
      }
    });

    test('Outlined ≠ filled (sauf history qui partage)', () {
      expect(ScalarioIcons.navDashboard, isNot(ScalarioIcons.navDashboardActive));
      expect(ScalarioIcons.navSales, isNot(ScalarioIcons.navSalesActive));
      expect(ScalarioIcons.navStock, isNot(ScalarioIcons.navStockActive));
      expect(ScalarioIcons.navReports, isNot(ScalarioIcons.navReportsActive));
      expect(ScalarioIcons.navTeam, isNot(ScalarioIcons.navTeamActive));
      expect(ScalarioIcons.navOps, isNot(ScalarioIcons.navOpsActive));
      expect(ScalarioIcons.navSettings, isNot(ScalarioIcons.navSettingsActive));
      // history = même icône repos/actif (pas de variante outlined Material)
      expect(ScalarioIcons.navHistory, ScalarioIcons.navHistoryActive);
    });
  });

  group('Actions — 15 entrées non-null', () {
    final List<IconData> actionIcons = <IconData>[
      ScalarioIcons.actionAdd,
      ScalarioIcons.actionEdit,
      ScalarioIcons.actionDelete,
      ScalarioIcons.actionConfirm,
      ScalarioIcons.actionClose,
      ScalarioIcons.actionBack,
      ScalarioIcons.actionSearch,
      ScalarioIcons.actionFilter,
      ScalarioIcons.actionSend,
      ScalarioIcons.actionDownload,
      ScalarioIcons.actionPrint,
      ScalarioIcons.actionCopy,
      ScalarioIcons.actionMore,
      ScalarioIcons.actionView,
      ScalarioIcons.actionHide,
    ];

    test('15 actions définies', () {
      expect(actionIcons, hasLength(15));
    });

    test('Toutes non-null', () {
      for (final IconData icon in actionIcons) {
        expect(icon, isNotNull);
      }
    });
  });

  group('Feedback & État — 8 icônes + couleurs associées', () {
    test('stateColor mappe les 8 états', () {
      expect(ScalarioIcons.stateColor(ScalarioIcons.stateNotifBell),
          ScalarioColors.neutral700);
      expect(ScalarioIcons.stateColor(ScalarioIcons.stateSyncActive),
          ScalarioColors.primary500);
      expect(ScalarioIcons.stateColor(ScalarioIcons.stateSyncOffline),
          ScalarioColors.warning500);
      expect(ScalarioIcons.stateColor(ScalarioIcons.stateError),
          ScalarioColors.danger500);
      expect(ScalarioIcons.stateColor(ScalarioIcons.stateWarning),
          ScalarioColors.warning500);
      expect(ScalarioIcons.stateColor(ScalarioIcons.stateSuccess),
          ScalarioColors.success500);
      expect(ScalarioIcons.stateColor(ScalarioIcons.stateInfo),
          ScalarioColors.primary700);
      expect(ScalarioIcons.stateColor(ScalarioIcons.stateLoading),
          ScalarioColors.neutral500);
    });

    test('stateColor renvoie null pour un icône non-state', () {
      expect(ScalarioIcons.stateColor(ScalarioIcons.actionAdd), isNull);
    });
  });

  group('Métier POS — 7 entrées', () {
    final List<IconData> posIcons = <IconData>[
      ScalarioIcons.bizPos,
      ScalarioIcons.bizCash,
      ScalarioIcons.bizMobileMoney,
      ScalarioIcons.bizCredit,
      ScalarioIcons.bizReceipt,
      ScalarioIcons.bizInvoice,
      ScalarioIcons.bizChange,
    ];

    test('7 icônes POS', () {
      expect(posIcons, hasLength(7));
    });
  });

  group('Métier Stock — 7 entrées', () {
    final List<IconData> stockIcons = <IconData>[
      ScalarioIcons.bizProduct,
      ScalarioIcons.bizDelivery,
      ScalarioIcons.bizSupplier,
      ScalarioIcons.bizLoss,
      ScalarioIcons.bizInventory,
      ScalarioIcons.bizAlert,
      ScalarioIcons.bizTransfer,
    ];

    test('7 icônes stock', () {
      expect(stockIcons, hasLength(7));
    });
  });

  group('Partage & Connectivité — 5 IconData + 1 SVG asset', () {
    test('WhatsApp = SVG asset (pas IconData)', () {
      expect(ScalarioIcons.whatsappAsset, 'assets/icons/whatsapp.svg');
    });

    test('5 icônes Material partage non-null', () {
      final List<IconData> shareIcons = <IconData>[
        ScalarioIcons.shareSms,
        ScalarioIcons.shareEmail,
        ScalarioIcons.shareBluetooth,
        ScalarioIcons.shareBluetoothScan,
        ScalarioIcons.sharePdf,
      ];
      expect(shareIcons, hasLength(5));
    });
  });

  group('Administration — 7 entrées', () {
    final List<IconData> adminIcons = <IconData>[
      ScalarioIcons.adminTenant,
      ScalarioIcons.adminDeploy,
      ScalarioIcons.adminMonitor,
      ScalarioIcons.adminLogs,
      ScalarioIcons.adminBilling,
      ScalarioIcons.adminSupport,
      ScalarioIcons.adminUser,
    ];

    test('7 icônes admin', () {
      expect(adminIcons, hasLength(7));
    });
  });
}
