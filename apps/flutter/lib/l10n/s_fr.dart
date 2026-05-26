// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class SFr extends S {
  SFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Scalario';

  @override
  String get welcomeMessage => 'Bienvenue sur Scalario';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get logout => 'Deconnexion';

  @override
  String get logoutConfirm => 'Etes-vous sur de vouloir vous deconnecter ?';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navSales => 'Ventes';

  @override
  String get navStock => 'Stock';

  @override
  String get navReports => 'Rapports';

  @override
  String get navHistory => 'Historique';

  @override
  String get navTeam => 'Equipe';

  @override
  String get navOps => 'Operations';

  @override
  String get navSettings => 'Parametres';

  @override
  String get roleOwner => 'Proprietaire';

  @override
  String get roleManager => 'Gerant';

  @override
  String get roleCommercial => 'Commercial';

  @override
  String get roleSuperAdmin => 'Admin Scalario';

  @override
  String get moduleVentes => 'Ventes';

  @override
  String get moduleStock => 'Stock';

  @override
  String get modulePertes => 'Pertes';

  @override
  String get moduleCloture => 'Cloture de caisse';

  @override
  String get moduleRapports => 'Rapports';

  @override
  String get moduleEmployes => 'Employes';

  @override
  String get moduleLivraisons => 'Livraisons';

  @override
  String get moduleCommandes => 'Commandes';

  @override
  String get moduleFactures => 'Factures';

  @override
  String get moduleClients => 'Clients';

  @override
  String get moduleFournisseurs => 'Fournisseurs';

  @override
  String get moduleConges => 'Conges';

  @override
  String get modulePaie => 'Paie';

  @override
  String get kpiCaJour => 'CA du jour';

  @override
  String get kpiNbVentes => 'Nb ventes';

  @override
  String get kpiAlertes => 'Alertes stock';

  @override
  String get kpiPertes => 'Pertes jour';

  @override
  String get kpiMarge => 'Marge';

  @override
  String get kpiStockVal => 'Valeur stock';

  @override
  String get chartTendance => 'Tendance des ventes (7j)';

  @override
  String get tableDernieresVentes => 'Dernieres ventes';

  @override
  String get tableProduit => 'Produit';

  @override
  String get tableQte => 'Qte';

  @override
  String get tablePrix => 'Prix';

  @override
  String get tableHeure => 'Heure';

  @override
  String get btnSave => 'Enregistrer';

  @override
  String get btnCancel => 'Annuler';

  @override
  String get btnDelete => 'Supprimer';

  @override
  String get btnAdd => 'Ajouter';

  @override
  String get btnEdit => 'Modifier';

  @override
  String get btnSearch => 'Rechercher';

  @override
  String get btnFilter => 'Filtrer';

  @override
  String get btnExport => 'Exporter';

  @override
  String get btnPrint => 'Imprimer';

  @override
  String get btnValidate => 'Valider';

  @override
  String get btnReject => 'Rejeter';

  @override
  String get btnRetry => 'Reessayer';

  @override
  String get btnConfirm => 'Confirmer';

  @override
  String get btnClose => 'Fermer';

  @override
  String get btnBack => 'Retour';

  @override
  String get btnHelp => 'Aide';

  @override
  String alertStockBasse(int count) {
    return '$count produits sous le seuil d\'alerte stock';
  }

  @override
  String get alertSyncOk => 'Synchronisation reussie';

  @override
  String get alertSyncError => 'Erreur de synchronisation';

  @override
  String get alertUpdateAvailable => 'Mise a jour disponible';

  @override
  String get alertPaymentFailed => 'Echec de paiement — verifiez votre compte';

  @override
  String get syncSynced => 'Synchronise';

  @override
  String get syncSyncing => 'Synchronisation...';

  @override
  String get syncConflict => 'Conflits a resoudre';

  @override
  String get syncOffline => 'Hors ligne';

  @override
  String get formRequired => 'Ce champ est obligatoire';

  @override
  String get formEmailInvalid => 'Email invalide';

  @override
  String formMinLength(int length) {
    return 'Minimum $length caracteres';
  }

  @override
  String get dateToday => 'Aujourd\'hui';

  @override
  String get dateYesterday => 'Hier';

  @override
  String get dateFormat => 'DD/MM/YYYY';

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
    return 'Rupture de stock : $produit';
  }

  @override
  String stockFaible(String produit, int qte) {
    return 'Stock faible : $produit ($qte restants)';
  }

  @override
  String get commandeValidee => 'Commande validee';

  @override
  String get commandeRejetee => 'Commande rejetee';

  @override
  String get perteDeclaree => 'Perte declaree';

  @override
  String get clotureEffectuee => 'Cloture de caisse effectuee';

  @override
  String get causesPerte => 'Causes de perte';

  @override
  String get causePerissable => 'Produit perissable';

  @override
  String get causeCasse => 'Casse';

  @override
  String get causeVol => 'Vol';

  @override
  String get causeErreur => 'Erreur de saisie';

  @override
  String get causeAutre => 'Autre';

  @override
  String get paymentCash => 'Especes';

  @override
  String get paymentMobileMoney => 'Mobile Money';

  @override
  String get paymentCredit => 'Credit';

  @override
  String get loading => 'Chargement...';

  @override
  String get emptyList => 'Aucune donnee';

  @override
  String get errorOccurred => 'Une erreur est survenue';

  @override
  String get errorRetry => 'Veuillez reessayer';

  @override
  String get noConnection => 'Pas de connexion Internet';

  @override
  String confirmDelete(String item) {
    return 'Supprimer $item ?';
  }

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get sandboxTitle => 'Sandbox BDUI (dev)';

  @override
  String get sandboxFile => 'Fichier JSON';

  @override
  String get sandboxBreakpoint => 'Breakpoint';

  @override
  String get sandboxReload => 'Recharger';

  @override
  String get sectorCommerceGeneral => 'Commerce general';

  @override
  String get sectorPharmacie => 'Pharmacie';

  @override
  String get sectorBtp => 'BTP';

  @override
  String get sectorCabinetMedical => 'Cabinet medical';

  @override
  String get monthJan => 'Janvier';

  @override
  String get monthFeb => 'Fevrier';

  @override
  String get monthMar => 'Mars';

  @override
  String get monthApr => 'Avril';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Juin';

  @override
  String get monthJul => 'Juillet';

  @override
  String get monthAug => 'Aout';

  @override
  String get monthSep => 'Septembre';

  @override
  String get monthOct => 'Octobre';

  @override
  String get monthNov => 'Novembre';

  @override
  String get monthDec => 'Decembre';

  @override
  String get dayMon => 'Lun';

  @override
  String get dayTue => 'Mar';

  @override
  String get dayWed => 'Mer';

  @override
  String get dayThu => 'Jeu';

  @override
  String get dayFri => 'Ven';

  @override
  String get daySat => 'Sam';

  @override
  String get daySun => 'Dim';
}
