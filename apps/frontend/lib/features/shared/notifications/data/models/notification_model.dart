class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? targetId;
  final DateTime createdAt;
  final bool isRead;

  /// e.g. "Yempabou · gérante"
  final String? actor;

  /// e.g. "Valider maintenant ›" — if non-null, a CTA button is shown.
  final String? actionLabel;

  /// Filter category: 'action' (requires user action) or 'info'.
  String get category {
    if (actionLabel != null) return 'action';
    switch (type) {
      case 'internal_order':
      case 'low_stock':
      case 'loss':
        return 'action';
      default:
        return 'info';
    }
  }

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    required this.createdAt,
    required this.isRead,
    this.actor,
    this.actionLabel,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      targetId: json['targetId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      actor: json['actor'] as String?,
      actionLabel: json['actionLabel'] as String?,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      targetId: targetId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      actor: actor,
      actionLabel: actionLabel,
    );
  }
}

/// Mock notifications matching Figma 13:11.
final List<NotificationModel> mockNotifications = [
  // ── Aujourd'hui · 5 avril ──────────────────────────────────────────
  NotificationModel(
    id: 'notif-1',
    title: 'Commande interne à valider',
    body: "Le commercial a demandé 50kg d'oignons. Approuvée par la gérante.",
    type: 'internal_order',
    targetId: '#CMD-2026-038',
    createdAt: DateTime(2026, 4, 5, 14, 32),
    isRead: false,
    actionLabel: 'Valider maintenant \u203A',
  ),
  NotificationModel(
    id: 'notif-2',
    title: 'Stock bas \u2014 4 produits',
    body: 'Tomate fraîche, lait 1L, savon Marseille, riz parfumé sous le seuil.',
    type: 'low_stock',
    createdAt: DateTime(2026, 4, 5, 12, 8),
    isRead: false,
  ),
  NotificationModel(
    id: 'notif-3',
    title: 'Perte déclarée',
    body: '8 unités de salade verte \u2014 expirées (14 500 F)',
    type: 'loss',
    createdAt: DateTime(2026, 4, 5, 10, 45),
    isRead: false,
    actor: 'Yempabou \u00B7 gérante',
  ),

  // ── Hier · 4 avril ─────────────────────────────────────────────────
  NotificationModel(
    id: 'notif-4',
    title: 'Caisse clôturée',
    body: 'CA du jour : 425 000 F \u00B7 Aucun écart',
    type: 'session_closed',
    createdAt: DateTime(2026, 4, 4, 19, 22),
    isRead: true,
  ),
  NotificationModel(
    id: 'notif-5',
    title: 'Nouvelle dépense',
    body: 'Eau pour clients \u2014 2 000 F \u00B7 justificatif joint',
    type: 'expense',
    createdAt: DateTime(2026, 4, 4, 16, 10),
    isRead: true,
  ),
  NotificationModel(
    id: 'notif-6',
    title: 'Commande validée',
    body: 'Réception oignons confirmée \u2014 48kg sur 50 commandés',
    type: 'internal_order',
    createdAt: DateTime(2026, 4, 4, 11, 30),
    isRead: true,
  ),
  NotificationModel(
    id: 'notif-7',
    title: 'Synchronisation OK',
    body: 'Toutes les données du jour sont à jour',
    type: 'sync',
    createdAt: DateTime(2026, 4, 4, 8, 0),
    isRead: true,
  ),
];
