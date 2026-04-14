/// Modèle et mock data pour les commandes internes.
/// TODO(backend): Remplacer les mocks par les vrais providers Supabase.
library;

import 'dart:ui';

// ── Enums ────────────────────────────────────────────────────────────────────

enum OrderStatus { toValidate, inProgress, validated, refused }

enum OrderUrgency { urgent, normal }

enum WfStepState { completed, current, pending }

// ── Modèles ──────────────────────────────────────────────────────────────────

class WorkflowStep {
  final String label;
  final WfStepState state;
  final int stepNumber;

  const WorkflowStep({
    required this.label,
    required this.state,
    required this.stepNumber,
  });
}

/// Ligne produit dans une commande interne.
class OrderProductLine {
  final String emoji;
  final Color emojiBackground;
  final String name;
  final int quantity;
  final String unit; // cartons, sacs, cageots…
  final double unitPrice;

  const OrderProductLine({
    required this.emoji,
    required this.emojiBackground,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

/// Entrée dans l'historique du workflow d'approbation.
class WorkflowHistoryEntry {
  final String title;
  final String actor;
  final String timestamp;
  final String? comment;
  final WfStepState state;
  final int stepNumber;

  const WorkflowHistoryEntry({
    required this.title,
    required this.actor,
    required this.timestamp,
    this.comment,
    required this.state,
    required this.stepNumber,
  });
}

class InternalOrder {
  final String id;
  final String title;
  final int productCount;
  final String commercialName;
  final String commercialInitial;
  final String shopName;
  final DateTime createdAt;
  final String supplierName;
  final double estimatedAmount;
  final OrderUrgency urgency;
  final OrderStatus status;
  final List<WorkflowStep> steps;

  /// True si la commande attend la validation de l'utilisateur courant.
  final bool isMyTurn;

  /// Lignes produits détaillées (pour l'écran détail).
  final List<OrderProductLine> products;

  /// Historique du workflow (pour l'écran détail).
  final List<WorkflowHistoryEntry> workflowHistory;

  /// Motif du commercial (optionnel).
  final String? commercialNote;

  const InternalOrder({
    required this.id,
    required this.title,
    required this.productCount,
    required this.commercialName,
    required this.commercialInitial,
    required this.shopName,
    required this.createdAt,
    required this.supplierName,
    required this.estimatedAmount,
    required this.urgency,
    required this.status,
    required this.steps,
    this.isMyTurn = false,
    this.products = const [],
    this.workflowHistory = const [],
    this.commercialNote,
  });
}

// ── Mock data ────────────────────────────────────────────────────────────────

final List<InternalOrder> mockInternalOrders = [
  // ── À valider ──────────────────────────────────────────────────────────────
  InternalOrder(
    id: '#CMD-2026-038',
    title: 'Réappro légumes',
    productCount: 4,
    commercialName: 'Moussa Kouma',
    commercialInitial: 'M',
    shopName: 'Boutique Ouaga',
    createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
    supplierName: 'Kossoda SARL',
    estimatedAmount: 142500,
    urgency: OrderUrgency.normal,
    status: OrderStatus.toValidate,
    isMyTurn: true,
    steps: const [
      WorkflowStep(label: 'Commercial', state: WfStepState.completed, stepNumber: 1),
      WorkflowStep(label: 'Gérante', state: WfStepState.completed, stepNumber: 2),
      WorkflowStep(label: 'Patronne', state: WfStepState.current, stepNumber: 3),
    ],
    commercialNote:
        'Stock tomates et oignons quasi épuisé depuis hier soir. Cliente Cantine Lycée commande lundi 200 portions, on doit être prêts. J\'ai joint la photo du frigo vide.',
    products: const [
      OrderProductLine(
        emoji: '\u{1F345}',
        emojiBackground: Color(0xFFFFEBEE),
        name: 'Tomates fraîches',
        quantity: 8,
        unit: 'cartons',
        unitPrice: 4500,
      ),
      OrderProductLine(
        emoji: '\u{1F9C5}',
        emojiBackground: Color(0xFFFFF8E1),
        name: 'Oignons rouges',
        quantity: 12,
        unit: 'sacs',
        unitPrice: 3800,
      ),
      OrderProductLine(
        emoji: '\u{1F96C}',
        emojiBackground: Color(0xFFE8F5E9),
        name: 'Salade laitue',
        quantity: 6,
        unit: 'cageots',
        unitPrice: 4200,
      ),
      OrderProductLine(
        emoji: '\u{1F955}',
        emojiBackground: Color(0xFFFFE0B2),
        name: 'Carottes',
        quantity: 9,
        unit: 'sacs',
        unitPrice: 4075,
      ),
    ],
    workflowHistory: [
      WorkflowHistoryEntry(
        title: 'Commande créée',
        actor: 'Moussa Kouma · Commercial',
        timestamp: '05 avr · 13:55:22',
        state: WfStepState.completed,
        stepNumber: 1,
      ),
      WorkflowHistoryEntry(
        title: 'Approuvée par la gérante',
        actor: 'Fatim Diop · Gérante Ouaga',
        timestamp: '05 avr · 14:18:07',
        comment: 'Validé, Moussa a raison c\'est urgent pour lundi.',
        state: WfStepState.completed,
        stepNumber: 2,
      ),
      WorkflowHistoryEntry(
        title: 'En attente de ta validation',
        actor: 'Toi · Patronne',
        timestamp: 'depuis 35 min',
        state: WfStepState.current,
        stepNumber: 3,
      ),
    ],
  ),
  InternalOrder(
    id: '#CMD-2026-037',
    title: 'Rupture tomates',
    productCount: 2,
    commercialName: 'Awa Sankara',
    commercialInitial: 'A',
    shopName: 'Boutique Ouaga',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    supplierName: 'Sankara Frères',
    estimatedAmount: 38000,
    urgency: OrderUrgency.urgent,
    status: OrderStatus.toValidate,
    isMyTurn: false,
    steps: const [
      WorkflowStep(label: 'Commercial', state: WfStepState.completed, stepNumber: 1),
      WorkflowStep(label: 'Gérante', state: WfStepState.current, stepNumber: 2),
      WorkflowStep(label: 'Patronne', state: WfStepState.pending, stepNumber: 3),
    ],
    commercialNote: 'Rupture totale depuis ce matin, clients mécontents.',
    products: const [
      OrderProductLine(
        emoji: '\u{1F345}',
        emojiBackground: Color(0xFFFFEBEE),
        name: 'Tomates fraîches',
        quantity: 5,
        unit: 'cartons',
        unitPrice: 4500,
      ),
      OrderProductLine(
        emoji: '\u{1F336}',
        emojiBackground: Color(0xFFFFEBEE),
        name: 'Piments rouges',
        quantity: 3,
        unit: 'sacs',
        unitPrice: 4333,
      ),
    ],
    workflowHistory: [
      WorkflowHistoryEntry(
        title: 'Commande créée',
        actor: 'Awa Sankara · Commercial',
        timestamp: '05 avr · 15:20:00',
        state: WfStepState.completed,
        stepNumber: 1,
      ),
      WorkflowHistoryEntry(
        title: 'En attente gérante',
        actor: 'Fatim Diop · Gérante Ouaga',
        timestamp: 'depuis 1 h',
        state: WfStepState.current,
        stepNumber: 2,
      ),
    ],
  ),
  InternalOrder(
    id: '#CMD-2026-036',
    title: 'Réappro produits secs',
    productCount: 6,
    commercialName: 'Boubou Tall',
    commercialInitial: 'B',
    shopName: 'Boutique Ouaga',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    supplierName: 'Marché Sandaga',
    estimatedAmount: 86200,
    urgency: OrderUrgency.normal,
    status: OrderStatus.toValidate,
    isMyTurn: false,
    steps: const [
      WorkflowStep(label: 'Commercial', state: WfStepState.completed, stepNumber: 1),
      WorkflowStep(label: 'Gérante', state: WfStepState.current, stepNumber: 2),
      WorkflowStep(label: 'Patronne', state: WfStepState.pending, stepNumber: 3),
    ],
    products: const [
      OrderProductLine(
        emoji: '\u{1F35A}',
        emojiBackground: Color(0xFFFFF8E1),
        name: 'Riz brisé',
        quantity: 10,
        unit: 'sacs',
        unitPrice: 3500,
      ),
      OrderProductLine(
        emoji: '\u{1FAD8}',
        emojiBackground: Color(0xFFFFF3E0),
        name: 'Huile végétale',
        quantity: 6,
        unit: 'bidons',
        unitPrice: 2800,
      ),
      OrderProductLine(
        emoji: '\u{1F9C2}',
        emojiBackground: Color(0xFFF3E5F5),
        name: 'Sel fin',
        quantity: 8,
        unit: 'paquets',
        unitPrice: 500,
      ),
      OrderProductLine(
        emoji: '\u{1F36B}',
        emojiBackground: Color(0xFFEFEBE9),
        name: 'Sucre en morceaux',
        quantity: 5,
        unit: 'cartons',
        unitPrice: 3200,
      ),
      OrderProductLine(
        emoji: '\u{2615}',
        emojiBackground: Color(0xFFEFEBE9),
        name: 'Café Nescafé',
        quantity: 4,
        unit: 'boîtes',
        unitPrice: 4800,
      ),
      OrderProductLine(
        emoji: '\u{1F35D}',
        emojiBackground: Color(0xFFFFF8E1),
        name: 'Pâtes spaghetti',
        quantity: 12,
        unit: 'paquets',
        unitPrice: 750,
      ),
    ],
    workflowHistory: [
      WorkflowHistoryEntry(
        title: 'Commande créée',
        actor: 'Boubou Tall · Commercial',
        timestamp: '05 avr · 13:20:00',
        state: WfStepState.completed,
        stepNumber: 1,
      ),
      WorkflowHistoryEntry(
        title: 'En attente gérante',
        actor: 'Fatim Diop · Gérante Ouaga',
        timestamp: 'depuis 3 h',
        state: WfStepState.current,
        stepNumber: 2,
      ),
    ],
  ),

  // ── En cours ───────────────────────────────────────────────────────────────
  InternalOrder(
    id: '#CMD-2026-035',
    title: 'Réappro fruits',
    productCount: 5,
    commercialName: 'Awa Sankara',
    commercialInitial: 'A',
    shopName: 'Boutique Ouaga',
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    supplierName: 'Marché Sandaga',
    estimatedAmount: 98500,
    urgency: OrderUrgency.normal,
    status: OrderStatus.inProgress,
    steps: const [
      WorkflowStep(label: 'Commercial', state: WfStepState.completed, stepNumber: 1),
      WorkflowStep(label: 'Gérante', state: WfStepState.current, stepNumber: 2),
      WorkflowStep(label: 'Patronne', state: WfStepState.pending, stepNumber: 3),
    ],
    products: const [
      OrderProductLine(
        emoji: '\u{1F34C}',
        emojiBackground: Color(0xFFFFF8E1),
        name: 'Bananes plantain',
        quantity: 10,
        unit: 'régimes',
        unitPrice: 3500,
      ),
      OrderProductLine(
        emoji: '\u{1F34D}',
        emojiBackground: Color(0xFFFFF8E1),
        name: 'Ananas',
        quantity: 8,
        unit: 'pièces',
        unitPrice: 2500,
      ),
      OrderProductLine(
        emoji: '\u{1F34E}',
        emojiBackground: Color(0xFFFFEBEE),
        name: 'Pommes',
        quantity: 6,
        unit: 'cartons',
        unitPrice: 5500,
      ),
      OrderProductLine(
        emoji: '\u{1F96D}',
        emojiBackground: Color(0xFFFFE0B2),
        name: 'Mangues',
        quantity: 15,
        unit: 'cageots',
        unitPrice: 2000,
      ),
      OrderProductLine(
        emoji: '\u{1F353}',
        emojiBackground: Color(0xFFFFEBEE),
        name: 'Fraises',
        quantity: 4,
        unit: 'barquettes',
        unitPrice: 3500,
      ),
    ],
    workflowHistory: [
      WorkflowHistoryEntry(
        title: 'Commande créée',
        actor: 'Awa Sankara · Commercial',
        timestamp: '05 avr · 10:30:00',
        state: WfStepState.completed,
        stepNumber: 1,
      ),
      WorkflowHistoryEntry(
        title: 'En attente gérante',
        actor: 'Fatim Diop · Gérante Ouaga',
        timestamp: 'depuis 6 h',
        state: WfStepState.current,
        stepNumber: 2,
      ),
    ],
  ),
  InternalOrder(
    id: '#CMD-2026-034',
    title: 'Réappro emballages',
    productCount: 3,
    commercialName: 'Moussa Kouma',
    commercialInitial: 'M',
    shopName: 'Boutique Ouaga',
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    supplierName: 'Plastique Express',
    estimatedAmount: 24800,
    urgency: OrderUrgency.normal,
    status: OrderStatus.inProgress,
    steps: const [
      WorkflowStep(label: 'Commercial', state: WfStepState.completed, stepNumber: 1),
      WorkflowStep(label: 'Gérante', state: WfStepState.completed, stepNumber: 2),
      WorkflowStep(label: 'Patronne', state: WfStepState.current, stepNumber: 3),
    ],
    isMyTurn: true,
    products: const [
      OrderProductLine(
        emoji: '\u{1F4E6}',
        emojiBackground: Color(0xFFE3F2FD),
        name: 'Sacs plastiques grands',
        quantity: 20,
        unit: 'paquets',
        unitPrice: 450,
      ),
      OrderProductLine(
        emoji: '\u{1F9FB}',
        emojiBackground: Color(0xFFF3E5F5),
        name: 'Papier kraft',
        quantity: 10,
        unit: 'rouleaux',
        unitPrice: 890,
      ),
      OrderProductLine(
        emoji: '\u{1F381}',
        emojiBackground: Color(0xFFFFE0B2),
        name: 'Sachets zip',
        quantity: 15,
        unit: 'paquets',
        unitPrice: 520,
      ),
    ],
    workflowHistory: [
      WorkflowHistoryEntry(
        title: 'Commande créée',
        actor: 'Moussa Kouma · Commercial',
        timestamp: '05 avr · 08:15:00',
        state: WfStepState.completed,
        stepNumber: 1,
      ),
      WorkflowHistoryEntry(
        title: 'Approuvée par la gérante',
        actor: 'Fatim Diop · Gérante Ouaga',
        timestamp: '05 avr · 09:40:00',
        comment: 'OK on a besoin d\'emballages.',
        state: WfStepState.completed,
        stepNumber: 2,
      ),
      WorkflowHistoryEntry(
        title: 'En attente de ta validation',
        actor: 'Toi · Patronne',
        timestamp: 'depuis 8 h',
        state: WfStepState.current,
        stepNumber: 3,
      ),
    ],
  ),

  // ── Validées ───────────────────────────────────────────────────────────────
  InternalOrder(
    id: '#CMD-2026-033',
    title: 'Légumes secs',
    productCount: 8,
    commercialName: 'Boubou Tall',
    commercialInitial: 'B',
    shopName: 'Boutique Ouaga',
    createdAt: DateTime(2026, 4, 3, 11, 2),
    supplierName: 'Coopérative Bobo',
    estimatedAmount: 156000,
    urgency: OrderUrgency.normal,
    status: OrderStatus.validated,
    steps: const [
      WorkflowStep(label: 'Commercial', state: WfStepState.completed, stepNumber: 1),
      WorkflowStep(label: 'Gérante', state: WfStepState.completed, stepNumber: 2),
      WorkflowStep(label: 'Patronne', state: WfStepState.completed, stepNumber: 3),
    ],
    products: const [
      OrderProductLine(
        emoji: '\u{1FAD8}',
        emojiBackground: Color(0xFFFFF3E0),
        name: 'Haricots blancs',
        quantity: 10,
        unit: 'sacs',
        unitPrice: 4500,
      ),
      OrderProductLine(
        emoji: '\u{1F33E}',
        emojiBackground: Color(0xFFFFF8E1),
        name: 'Lentilles',
        quantity: 8,
        unit: 'sacs',
        unitPrice: 3800,
      ),
      OrderProductLine(
        emoji: '\u{1F35A}',
        emojiBackground: Color(0xFFFFF8E1),
        name: 'Pois chiches',
        quantity: 6,
        unit: 'sacs',
        unitPrice: 4200,
      ),
      OrderProductLine(
        emoji: '\u{1F330}',
        emojiBackground: Color(0xFFEFEBE9),
        name: 'Arachides',
        quantity: 12,
        unit: 'sacs',
        unitPrice: 2500,
      ),
      OrderProductLine(
        emoji: '\u{1F33D}',
        emojiBackground: Color(0xFFFFF8E1),
        name: 'Maïs sec',
        quantity: 10,
        unit: 'sacs',
        unitPrice: 2200,
      ),
      OrderProductLine(
        emoji: '\u{1F35E}',
        emojiBackground: Color(0xFFEFEBE9),
        name: 'Farine de mil',
        quantity: 5,
        unit: 'sacs',
        unitPrice: 3600,
      ),
      OrderProductLine(
        emoji: '\u{1F9C2}',
        emojiBackground: Color(0xFFF3E5F5),
        name: 'Soumbala',
        quantity: 4,
        unit: 'paquets',
        unitPrice: 5500,
      ),
      OrderProductLine(
        emoji: '\u{1F330}',
        emojiBackground: Color(0xFFEFEBE9),
        name: 'Noix de cajou',
        quantity: 3,
        unit: 'sacs',
        unitPrice: 8500,
      ),
    ],
    workflowHistory: [
      WorkflowHistoryEntry(
        title: 'Commande créée',
        actor: 'Boubou Tall · Commercial',
        timestamp: '03 avr · 11:02:00',
        state: WfStepState.completed,
        stepNumber: 1,
      ),
      WorkflowHistoryEntry(
        title: 'Approuvée par la gérante',
        actor: 'Fatim Diop · Gérante Ouaga',
        timestamp: '03 avr · 12:30:00',
        state: WfStepState.completed,
        stepNumber: 2,
      ),
      WorkflowHistoryEntry(
        title: 'Validée par la patronne',
        actor: 'Toi · Patronne',
        timestamp: '03 avr · 14:15:00',
        comment: 'Bon prix, validé.',
        state: WfStepState.completed,
        stepNumber: 3,
      ),
    ],
  ),
  InternalOrder(
    id: '#CMD-2026-032',
    title: 'Boissons fraîches',
    productCount: 4,
    commercialName: 'Fatim Diop',
    commercialInitial: 'F',
    shopName: 'Boutique Ouaga',
    createdAt: DateTime(2026, 4, 2, 9, 30),
    supplierName: 'Brakina Distrib',
    estimatedAmount: 72400,
    urgency: OrderUrgency.normal,
    status: OrderStatus.validated,
    steps: const [
      WorkflowStep(label: 'Commercial', state: WfStepState.completed, stepNumber: 1),
      WorkflowStep(label: 'Gérante', state: WfStepState.completed, stepNumber: 2),
      WorkflowStep(label: 'Patronne', state: WfStepState.completed, stepNumber: 3),
    ],
    products: const [
      OrderProductLine(
        emoji: '\u{1F37A}',
        emojiBackground: Color(0xFFFFF8E1),
        name: 'Bière Brakina',
        quantity: 10,
        unit: 'casiers',
        unitPrice: 4200,
      ),
      OrderProductLine(
        emoji: '\u{1F964}',
        emojiBackground: Color(0xFFE8F5E9),
        name: 'Jus de bissap',
        quantity: 8,
        unit: 'packs',
        unitPrice: 1800,
      ),
      OrderProductLine(
        emoji: '\u{1F4A7}',
        emojiBackground: Color(0xFFE3F2FD),
        name: 'Eau minérale',
        quantity: 12,
        unit: 'packs',
        unitPrice: 1200,
      ),
      OrderProductLine(
        emoji: '\u{1F379}',
        emojiBackground: Color(0xFFFFEBEE),
        name: 'Sodas assortis',
        quantity: 6,
        unit: 'casiers',
        unitPrice: 3600,
      ),
    ],
    workflowHistory: [
      WorkflowHistoryEntry(
        title: 'Commande créée',
        actor: 'Fatim Diop · Gérante Ouaga',
        timestamp: '02 avr · 09:30:00',
        state: WfStepState.completed,
        stepNumber: 1,
      ),
      WorkflowHistoryEntry(
        title: 'Auto-approuvée (gérante = demandeur)',
        actor: 'Fatim Diop · Gérante Ouaga',
        timestamp: '02 avr · 09:30:00',
        state: WfStepState.completed,
        stepNumber: 2,
      ),
      WorkflowHistoryEntry(
        title: 'Validée par la patronne',
        actor: 'Toi · Patronne',
        timestamp: '02 avr · 11:00:00',
        state: WfStepState.completed,
        stepNumber: 3,
      ),
    ],
  ),

  // ── Refusées ───────────────────────────────────────────────────────────────
  InternalOrder(
    id: '#CMD-2026-031',
    title: 'Commande huile de palme',
    productCount: 10,
    commercialName: 'Moussa Kouma',
    commercialInitial: 'M',
    shopName: 'Boutique Ouaga',
    createdAt: DateTime(2026, 4, 1, 16, 0),
    supplierName: 'Huilerie du Sud',
    estimatedAmount: 210000,
    urgency: OrderUrgency.normal,
    status: OrderStatus.refused,
    steps: const [
      WorkflowStep(label: 'Commercial', state: WfStepState.completed, stepNumber: 1),
      WorkflowStep(label: 'Gérante', state: WfStepState.completed, stepNumber: 2),
      WorkflowStep(label: 'Patronne', state: WfStepState.completed, stepNumber: 3),
    ],
    products: const [
      OrderProductLine(
        emoji: '\u{1FAD8}',
        emojiBackground: Color(0xFFFFF3E0),
        name: 'Huile de palme rouge',
        quantity: 5,
        unit: 'fûts',
        unitPrice: 18000,
      ),
      OrderProductLine(
        emoji: '\u{1FAD8}',
        emojiBackground: Color(0xFFFFF8E1),
        name: 'Huile de palme raffinée',
        quantity: 5,
        unit: 'fûts',
        unitPrice: 24000,
      ),
    ],
    workflowHistory: [
      WorkflowHistoryEntry(
        title: 'Commande créée',
        actor: 'Moussa Kouma · Commercial',
        timestamp: '01 avr · 16:00:00',
        state: WfStepState.completed,
        stepNumber: 1,
      ),
      WorkflowHistoryEntry(
        title: 'Approuvée par la gérante',
        actor: 'Fatim Diop · Gérante Ouaga',
        timestamp: '01 avr · 17:20:00',
        state: WfStepState.completed,
        stepNumber: 2,
      ),
      WorkflowHistoryEntry(
        title: 'Refusée par la patronne',
        actor: 'Toi · Patronne',
        timestamp: '01 avr · 18:00:00',
        comment: 'Hors budget ce mois-ci, reporter à mai.',
        state: WfStepState.completed,
        stepNumber: 3,
      ),
    ],
  ),
  InternalOrder(
    id: '#CMD-2026-030',
    title: 'Stock déco vitrine',
    productCount: 15,
    commercialName: 'Awa Sankara',
    commercialInitial: 'A',
    shopName: 'Boutique Ouaga',
    createdAt: DateTime(2026, 3, 30, 10, 0),
    supplierName: 'Déco Plus',
    estimatedAmount: 45000,
    urgency: OrderUrgency.normal,
    status: OrderStatus.refused,
    steps: const [
      WorkflowStep(label: 'Commercial', state: WfStepState.completed, stepNumber: 1),
      WorkflowStep(label: 'Gérante', state: WfStepState.completed, stepNumber: 2),
      WorkflowStep(label: 'Patronne', state: WfStepState.completed, stepNumber: 3),
    ],
    products: const [
      OrderProductLine(
        emoji: '\u{1F3A8}',
        emojiBackground: Color(0xFFF3E5F5),
        name: 'Guirlandes lumineuses',
        quantity: 5,
        unit: 'boîtes',
        unitPrice: 3000,
      ),
      OrderProductLine(
        emoji: '\u{1F490}',
        emojiBackground: Color(0xFFFFEBEE),
        name: 'Fleurs artificielles',
        quantity: 10,
        unit: 'bouquets',
        unitPrice: 3000,
      ),
    ],
    workflowHistory: [
      WorkflowHistoryEntry(
        title: 'Commande créée',
        actor: 'Awa Sankara · Commercial',
        timestamp: '30 mar · 10:00:00',
        state: WfStepState.completed,
        stepNumber: 1,
      ),
      WorkflowHistoryEntry(
        title: 'Approuvée par la gérante',
        actor: 'Fatim Diop · Gérante Ouaga',
        timestamp: '30 mar · 11:30:00',
        state: WfStepState.completed,
        stepNumber: 2,
      ),
      WorkflowHistoryEntry(
        title: 'Refusée par la patronne',
        actor: 'Toi · Patronne',
        timestamp: '30 mar · 14:00:00',
        comment: 'Pas prioritaire, on garde le budget pour le stock alimentaire.',
        state: WfStepState.completed,
        stepNumber: 3,
      ),
    ],
  ),
];

// ── Helpers ──────────────────────────────────────────────────────────────────

List<InternalOrder> internalOrdersByStatus(OrderStatus status) =>
    mockInternalOrders.where((o) => o.status == status).toList();

/// Tous les commerciaux distincts (pour le filtre).
List<({String name, String initial, int orderCount})> distinctCommercials() {
  final map = <String, ({String initial, int count})>{};
  for (final o in mockInternalOrders) {
    final prev = map[o.commercialName];
    map[o.commercialName] = (
      initial: o.commercialInitial,
      count: (prev?.count ?? 0) + 1,
    );
  }
  return map.entries
      .map((e) => (name: e.key, initial: e.value.initial, orderCount: e.value.count))
      .toList();
}
