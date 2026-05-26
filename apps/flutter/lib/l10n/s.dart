import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 's_en.dart';
import 's_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/s.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scalario'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Scalario'**
  String get welcomeMessage;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Deconnexion'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Etes-vous sur de vouloir vous deconnecter ?'**
  String get logoutConfirm;

  /// No description provided for @navDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get navDashboard;

  /// No description provided for @navSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get navSales;

  /// No description provided for @navStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get navStock;

  /// No description provided for @navReports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get navReports;

  /// No description provided for @navHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get navHistory;

  /// No description provided for @navTeam.
  ///
  /// In fr, this message translates to:
  /// **'Equipe'**
  String get navTeam;

  /// No description provided for @navOps.
  ///
  /// In fr, this message translates to:
  /// **'Operations'**
  String get navOps;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Parametres'**
  String get navSettings;

  /// No description provided for @roleOwner.
  ///
  /// In fr, this message translates to:
  /// **'Proprietaire'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In fr, this message translates to:
  /// **'Gerant'**
  String get roleManager;

  /// No description provided for @roleCommercial.
  ///
  /// In fr, this message translates to:
  /// **'Commercial'**
  String get roleCommercial;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Admin Scalario'**
  String get roleSuperAdmin;

  /// No description provided for @moduleVentes.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get moduleVentes;

  /// No description provided for @moduleStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get moduleStock;

  /// No description provided for @modulePertes.
  ///
  /// In fr, this message translates to:
  /// **'Pertes'**
  String get modulePertes;

  /// No description provided for @moduleCloture.
  ///
  /// In fr, this message translates to:
  /// **'Cloture de caisse'**
  String get moduleCloture;

  /// No description provided for @moduleRapports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get moduleRapports;

  /// No description provided for @moduleEmployes.
  ///
  /// In fr, this message translates to:
  /// **'Employes'**
  String get moduleEmployes;

  /// No description provided for @moduleLivraisons.
  ///
  /// In fr, this message translates to:
  /// **'Livraisons'**
  String get moduleLivraisons;

  /// No description provided for @moduleCommandes.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get moduleCommandes;

  /// No description provided for @moduleFactures.
  ///
  /// In fr, this message translates to:
  /// **'Factures'**
  String get moduleFactures;

  /// No description provided for @moduleClients.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get moduleClients;

  /// No description provided for @moduleFournisseurs.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseurs'**
  String get moduleFournisseurs;

  /// No description provided for @moduleConges.
  ///
  /// In fr, this message translates to:
  /// **'Conges'**
  String get moduleConges;

  /// No description provided for @modulePaie.
  ///
  /// In fr, this message translates to:
  /// **'Paie'**
  String get modulePaie;

  /// No description provided for @kpiCaJour.
  ///
  /// In fr, this message translates to:
  /// **'CA du jour'**
  String get kpiCaJour;

  /// No description provided for @kpiNbVentes.
  ///
  /// In fr, this message translates to:
  /// **'Nb ventes'**
  String get kpiNbVentes;

  /// No description provided for @kpiAlertes.
  ///
  /// In fr, this message translates to:
  /// **'Alertes stock'**
  String get kpiAlertes;

  /// No description provided for @kpiPertes.
  ///
  /// In fr, this message translates to:
  /// **'Pertes jour'**
  String get kpiPertes;

  /// No description provided for @kpiMarge.
  ///
  /// In fr, this message translates to:
  /// **'Marge'**
  String get kpiMarge;

  /// No description provided for @kpiStockVal.
  ///
  /// In fr, this message translates to:
  /// **'Valeur stock'**
  String get kpiStockVal;

  /// No description provided for @chartTendance.
  ///
  /// In fr, this message translates to:
  /// **'Tendance des ventes (7j)'**
  String get chartTendance;

  /// No description provided for @tableDernieresVentes.
  ///
  /// In fr, this message translates to:
  /// **'Dernieres ventes'**
  String get tableDernieresVentes;

  /// No description provided for @tableProduit.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get tableProduit;

  /// No description provided for @tableQte.
  ///
  /// In fr, this message translates to:
  /// **'Qte'**
  String get tableQte;

  /// No description provided for @tablePrix.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get tablePrix;

  /// No description provided for @tableHeure.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get tableHeure;

  /// No description provided for @btnSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get btnSave;

  /// No description provided for @btnCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get btnCancel;

  /// No description provided for @btnDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get btnDelete;

  /// No description provided for @btnAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get btnAdd;

  /// No description provided for @btnEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get btnEdit;

  /// No description provided for @btnSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get btnSearch;

  /// No description provided for @btnFilter.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer'**
  String get btnFilter;

  /// No description provided for @btnExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get btnExport;

  /// No description provided for @btnPrint.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer'**
  String get btnPrint;

  /// No description provided for @btnValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get btnValidate;

  /// No description provided for @btnReject.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter'**
  String get btnReject;

  /// No description provided for @btnRetry.
  ///
  /// In fr, this message translates to:
  /// **'Reessayer'**
  String get btnRetry;

  /// No description provided for @btnConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get btnConfirm;

  /// No description provided for @btnClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get btnClose;

  /// No description provided for @btnBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get btnBack;

  /// No description provided for @btnHelp.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get btnHelp;

  /// No description provided for @alertStockBasse.
  ///
  /// In fr, this message translates to:
  /// **'{count} produits sous le seuil d\'alerte stock'**
  String alertStockBasse(int count);

  /// No description provided for @alertSyncOk.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation reussie'**
  String get alertSyncOk;

  /// No description provided for @alertSyncError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de synchronisation'**
  String get alertSyncError;

  /// No description provided for @alertUpdateAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Mise a jour disponible'**
  String get alertUpdateAvailable;

  /// No description provided for @alertPaymentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Echec de paiement — verifiez votre compte'**
  String get alertPaymentFailed;

  /// No description provided for @syncSynced.
  ///
  /// In fr, this message translates to:
  /// **'Synchronise'**
  String get syncSynced;

  /// No description provided for @syncSyncing.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation...'**
  String get syncSyncing;

  /// No description provided for @syncConflict.
  ///
  /// In fr, this message translates to:
  /// **'Conflits a resoudre'**
  String get syncConflict;

  /// No description provided for @syncOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get syncOffline;

  /// No description provided for @formRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire'**
  String get formRequired;

  /// No description provided for @formEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get formEmailInvalid;

  /// No description provided for @formMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Minimum {length} caracteres'**
  String formMinLength(int length);

  /// No description provided for @dateToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get dateYesterday;

  /// No description provided for @dateFormat.
  ///
  /// In fr, this message translates to:
  /// **'DD/MM/YYYY'**
  String get dateFormat;

  /// No description provided for @currencyFCFA.
  ///
  /// In fr, this message translates to:
  /// **'FCFA'**
  String get currencyFCFA;

  /// No description provided for @currencyEuro.
  ///
  /// In fr, this message translates to:
  /// **'EUR'**
  String get currencyEuro;

  /// No description provided for @currencyDollar.
  ///
  /// In fr, this message translates to:
  /// **'USD'**
  String get currencyDollar;

  /// No description provided for @amountFcfa.
  ///
  /// In fr, this message translates to:
  /// **'{amount} FCFA'**
  String amountFcfa(num amount);

  /// No description provided for @stockRupture.
  ///
  /// In fr, this message translates to:
  /// **'Rupture de stock : {produit}'**
  String stockRupture(String produit);

  /// No description provided for @stockFaible.
  ///
  /// In fr, this message translates to:
  /// **'Stock faible : {produit} ({qte} restants)'**
  String stockFaible(String produit, int qte);

  /// No description provided for @commandeValidee.
  ///
  /// In fr, this message translates to:
  /// **'Commande validee'**
  String get commandeValidee;

  /// No description provided for @commandeRejetee.
  ///
  /// In fr, this message translates to:
  /// **'Commande rejetee'**
  String get commandeRejetee;

  /// No description provided for @perteDeclaree.
  ///
  /// In fr, this message translates to:
  /// **'Perte declaree'**
  String get perteDeclaree;

  /// No description provided for @clotureEffectuee.
  ///
  /// In fr, this message translates to:
  /// **'Cloture de caisse effectuee'**
  String get clotureEffectuee;

  /// No description provided for @causesPerte.
  ///
  /// In fr, this message translates to:
  /// **'Causes de perte'**
  String get causesPerte;

  /// No description provided for @causePerissable.
  ///
  /// In fr, this message translates to:
  /// **'Produit perissable'**
  String get causePerissable;

  /// No description provided for @causeCasse.
  ///
  /// In fr, this message translates to:
  /// **'Casse'**
  String get causeCasse;

  /// No description provided for @causeVol.
  ///
  /// In fr, this message translates to:
  /// **'Vol'**
  String get causeVol;

  /// No description provided for @causeErreur.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de saisie'**
  String get causeErreur;

  /// No description provided for @causeAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get causeAutre;

  /// No description provided for @paymentCash.
  ///
  /// In fr, this message translates to:
  /// **'Especes'**
  String get paymentCash;

  /// No description provided for @paymentMobileMoney.
  ///
  /// In fr, this message translates to:
  /// **'Mobile Money'**
  String get paymentMobileMoney;

  /// No description provided for @paymentCredit.
  ///
  /// In fr, this message translates to:
  /// **'Credit'**
  String get paymentCredit;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @emptyList.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnee'**
  String get emptyList;

  /// No description provided for @errorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorOccurred;

  /// No description provided for @errorRetry.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez reessayer'**
  String get errorRetry;

  /// No description provided for @noConnection.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion Internet'**
  String get noConnection;

  /// No description provided for @confirmDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer {item} ?'**
  String confirmDelete(String item);

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @sandboxTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sandbox BDUI (dev)'**
  String get sandboxTitle;

  /// No description provided for @sandboxFile.
  ///
  /// In fr, this message translates to:
  /// **'Fichier JSON'**
  String get sandboxFile;

  /// No description provided for @sandboxBreakpoint.
  ///
  /// In fr, this message translates to:
  /// **'Breakpoint'**
  String get sandboxBreakpoint;

  /// No description provided for @sandboxReload.
  ///
  /// In fr, this message translates to:
  /// **'Recharger'**
  String get sandboxReload;

  /// No description provided for @sectorCommerceGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Commerce general'**
  String get sectorCommerceGeneral;

  /// No description provided for @sectorPharmacie.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacie'**
  String get sectorPharmacie;

  /// No description provided for @sectorBtp.
  ///
  /// In fr, this message translates to:
  /// **'BTP'**
  String get sectorBtp;

  /// No description provided for @sectorCabinetMedical.
  ///
  /// In fr, this message translates to:
  /// **'Cabinet medical'**
  String get sectorCabinetMedical;

  /// No description provided for @monthJan.
  ///
  /// In fr, this message translates to:
  /// **'Janvier'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In fr, this message translates to:
  /// **'Fevrier'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In fr, this message translates to:
  /// **'Mars'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In fr, this message translates to:
  /// **'Avril'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In fr, this message translates to:
  /// **'Mai'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In fr, this message translates to:
  /// **'Juin'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In fr, this message translates to:
  /// **'Juillet'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In fr, this message translates to:
  /// **'Aout'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In fr, this message translates to:
  /// **'Septembre'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In fr, this message translates to:
  /// **'Octobre'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In fr, this message translates to:
  /// **'Novembre'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In fr, this message translates to:
  /// **'Decembre'**
  String get monthDec;

  /// No description provided for @dayMon.
  ///
  /// In fr, this message translates to:
  /// **'Lun'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In fr, this message translates to:
  /// **'Mar'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In fr, this message translates to:
  /// **'Mer'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In fr, this message translates to:
  /// **'Jeu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In fr, this message translates to:
  /// **'Ven'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In fr, this message translates to:
  /// **'Sam'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In fr, this message translates to:
  /// **'Dim'**
  String get daySun;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'fr':
      return SFr();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
