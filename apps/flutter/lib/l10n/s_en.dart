// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Scalario';

  @override
  String get welcomeMessage => 'Welcome to Scalario';

  @override
  String get loginTitle => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navSales => 'Sales';

  @override
  String get navStock => 'Stock';

  @override
  String get navReports => 'Reports';

  @override
  String get navHistory => 'History';

  @override
  String get navTeam => 'Team';

  @override
  String get navOps => 'Operations';

  @override
  String get navSettings => 'Settings';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleCommercial => 'Sales Agent';

  @override
  String get roleSuperAdmin => 'Scalario Admin';

  @override
  String get moduleVentes => 'Sales';

  @override
  String get moduleStock => 'Inventory';

  @override
  String get modulePertes => 'Losses';

  @override
  String get moduleCloture => 'Cash Closing';

  @override
  String get moduleRapports => 'Reports';

  @override
  String get moduleEmployes => 'Employees';

  @override
  String get moduleLivraisons => 'Deliveries';

  @override
  String get moduleCommandes => 'Orders';

  @override
  String get moduleFactures => 'Invoices';

  @override
  String get moduleClients => 'Clients';

  @override
  String get moduleFournisseurs => 'Suppliers';

  @override
  String get moduleConges => 'Leave';

  @override
  String get modulePaie => 'Payroll';

  @override
  String get kpiCaJour => 'Daily Revenue';

  @override
  String get kpiNbVentes => 'Sales Count';

  @override
  String get kpiAlertes => 'Stock Alerts';

  @override
  String get kpiPertes => 'Daily Losses';

  @override
  String get kpiMarge => 'Margin';

  @override
  String get kpiStockVal => 'Stock Value';

  @override
  String get chartTendance => 'Sales Trend (7d)';

  @override
  String get tableDernieresVentes => 'Recent Sales';

  @override
  String get tableProduit => 'Product';

  @override
  String get tableQte => 'Qty';

  @override
  String get tablePrix => 'Price';

  @override
  String get tableHeure => 'Time';

  @override
  String get btnSave => 'Save';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnDelete => 'Delete';

  @override
  String get btnAdd => 'Add';

  @override
  String get btnEdit => 'Edit';

  @override
  String get btnSearch => 'Search';

  @override
  String get btnFilter => 'Filter';

  @override
  String get btnExport => 'Export';

  @override
  String get btnPrint => 'Print';

  @override
  String get btnValidate => 'Validate';

  @override
  String get btnReject => 'Reject';

  @override
  String get btnRetry => 'Retry';

  @override
  String get btnConfirm => 'Confirm';

  @override
  String get btnClose => 'Close';

  @override
  String get btnBack => 'Back';

  @override
  String get btnHelp => 'Help';

  @override
  String alertStockBasse(int count) {
    return '$count products below stock alert threshold';
  }

  @override
  String get alertSyncOk => 'Sync successful';

  @override
  String get alertSyncError => 'Sync error';

  @override
  String get alertUpdateAvailable => 'Update available';

  @override
  String get alertPaymentFailed => 'Payment failed — check your account';

  @override
  String get syncSynced => 'Synced';

  @override
  String get syncSyncing => 'Syncing...';

  @override
  String get syncConflict => 'Conflicts to resolve';

  @override
  String get syncOffline => 'Offline';

  @override
  String get formRequired => 'This field is required';

  @override
  String get formEmailInvalid => 'Invalid email';

  @override
  String formMinLength(int length) {
    return 'Minimum $length characters';
  }

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get dateFormat => 'MM/DD/YYYY';

  @override
  String get currencyFCFA => 'FCFA';

  @override
  String get currencyEuro => 'EUR';

  @override
  String get currencyDollar => 'USD';

  @override
  String amountFcfa(num amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString FCFA';
  }

  @override
  String stockRupture(String produit) {
    return 'Out of stock: $produit';
  }

  @override
  String stockFaible(String produit, int qte) {
    return 'Low stock: $produit ($qte remaining)';
  }

  @override
  String get commandeValidee => 'Order validated';

  @override
  String get commandeRejetee => 'Order rejected';

  @override
  String get perteDeclaree => 'Loss reported';

  @override
  String get clotureEffectuee => 'Cash closing completed';

  @override
  String get causesPerte => 'Loss causes';

  @override
  String get causePerissable => 'Perishable';

  @override
  String get causeCasse => 'Breakage';

  @override
  String get causeVol => 'Theft';

  @override
  String get causeErreur => 'Input error';

  @override
  String get causeAutre => 'Other';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentMobileMoney => 'Mobile Money';

  @override
  String get paymentCredit => 'Credit';

  @override
  String get loading => 'Loading...';

  @override
  String get emptyList => 'No data';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get errorRetry => 'Please try again';

  @override
  String get noConnection => 'No Internet connection';

  @override
  String confirmDelete(String item) {
    return 'Delete $item?';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get sandboxTitle => 'BDUI Sandbox (dev)';

  @override
  String get sandboxFile => 'JSON File';

  @override
  String get sandboxBreakpoint => 'Breakpoint';

  @override
  String get sandboxReload => 'Recharger';

  @override
  String get sectorCommerceGeneral => 'General Commerce';

  @override
  String get sectorPharmacie => 'Pharmacy';

  @override
  String get sectorBtp => 'Construction';

  @override
  String get sectorCabinetMedical => 'Medical Practice';

  @override
  String get monthJan => 'January';

  @override
  String get monthFeb => 'February';

  @override
  String get monthMar => 'March';

  @override
  String get monthApr => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'June';

  @override
  String get monthJul => 'July';

  @override
  String get monthAug => 'August';

  @override
  String get monthSep => 'September';

  @override
  String get monthOct => 'October';

  @override
  String get monthNov => 'November';

  @override
  String get monthDec => 'December';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';
}
