// ============================================================
// sca_kanban_board.dart - REFONTE COMPLÈTE (Phase 7)
// Tableau Kanban interactif avec Drag & Drop natif Flutter
// Features:
//  - Colonnes dynamiques (depuis BDUI props)
//  - Drag & Drop entre colonnes (DragTarget + Draggable)
//  - Ombre sur la carte en cours de drag (grab effect)
//  - Couleur de colonne configurable
//  - Badge avec nombre de cartes par colonne
//  - Bouton "Ajouter une carte" par colonne
//  - Cards avec title, sous-titre, badge de statut et avatar
// ============================================================
import 'package:flutter/material.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../theme/sca_tokens.dart';
import '../_internal/sca_focus_wrapper.dart';

// ---- Types ----

class _KanbanCard {
  final String id;
  final String title;
  final String? subtitle;
  final String? assigneeName;
  final String? status;

  const _KanbanCard({
    required this.id,
    required this.title,
    this.subtitle,
    this.assigneeName,
    this.status,
  });

  factory _KanbanCard.fromMap(Map<String, dynamic> m) {
    return _KanbanCard(
      id: m['id'] as String? ?? UniqueKey().toString(),
      title: m['title'] as String? ?? 'Carte',
      subtitle: m['subtitle'] as String?,
      assigneeName: m['assignee'] as String?,
      status: m['status'] as String?,
    );
  }
}

class _KanbanColumn {
  final String id;
  final String title;
  final Color color;
  final List<_KanbanCard> cards;

  _KanbanColumn({
    required this.id,
    required this.title,
    required this.color,
    required this.cards,
  });

  _KanbanColumn copyWith({List<_KanbanCard>? cards}) {
    return _KanbanColumn(
      id: id,
      title: title,
      color: color,
      cards: cards ?? this.cards,
    );
  }
}

// ---- Main Widget ----

class ScaKanbanBoard extends StatefulWidget {
  final ComponentConfig config;

  const ScaKanbanBoard({super.key, required this.config});

  @override
  State<ScaKanbanBoard> createState() => _ScaKanbanBoardState();
}

class _ScaKanbanBoardState extends State<ScaKanbanBoard> {
  late List<_KanbanColumn> _columns;

  @override
  void initState() {
    super.initState();
    _columns = _parseColumns();
  }

  List<_KanbanColumn> _parseColumns() {
    final rawCols = (widget.config.props['columns'] as List<dynamic>?)
            ?.map((c) => c as Map<String, dynamic>)
            .toList() ??
        [];

    if (rawCols.isEmpty) {
      // Default demo columns
      return [
        _KanbanColumn(
          id: 'todo',
          title: 'À Faire',
          color: ScaColors.neutralBg,
          cards: [
            const _KanbanCard(
                id: '1', title: 'Préparer la proposition', subtitle: 'Client ABC', assigneeName: 'Marie'),
            const _KanbanCard(
                id: '2', title: 'Analyse des besoins', subtitle: '3 jours', assigneeName: 'Julien'),
          ],
        ),
        _KanbanColumn(
          id: 'in_progress',
          title: 'En Cours',
          color: ScaColors.infoBg,
          cards: [
            const _KanbanCard(
                id: '3', title: 'Développement module', subtitle: 'Sprint 4', status: 'actif'),
          ],
        ),
        _KanbanColumn(
          id: 'review',
          title: 'En Révision',
          color: ScaColors.warningBg,
          cards: [
            const _KanbanCard(
                id: '4', title: 'Tests unitaires', subtitle: '80% complété'),
          ],
        ),
        _KanbanColumn(
          id: 'done',
          title: 'Terminé',
          color: ScaColors.successBg,
          cards: [
            const _KanbanCard(
                id: '5', title: 'Déploiement v1.0', subtitle: 'Livré le 5 juin'),
          ],
        ),
      ];
    }

    return rawCols.map((col) {
      final colorStr = col['color'] as String? ?? 'neutral';
      return _KanbanColumn(
        id: col['id'] as String? ?? col['title'] as String? ?? '',
        title: col['title'] as String? ?? '',
        color: _parseColor(colorStr),
        cards: ((col['cards'] as List<dynamic>?) ?? [])
            .map((c) => _KanbanCard.fromMap(c as Map<String, dynamic>))
            .toList(),
      );
    }).toList();
  }

  Color _parseColor(String colorStr) {
    switch (colorStr) {
      case 'blue': return ScaColors.infoBg;
      case 'green': return ScaColors.successBg;
      case 'yellow': return ScaColors.warningBg;
      case 'red': return ScaColors.dangerBg;
      default: return ScaColors.neutralBg;
    }
  }

  void _moveCard(String cardId, String fromColId, String toColId, int targetIndex) {
    if (fromColId == toColId) return;
    setState(() {
      final fromColIndex = _columns.indexWhere((c) => c.id == fromColId);
      final toColIndex = _columns.indexWhere((c) => c.id == toColId);
      if (fromColIndex == -1 || toColIndex == -1) return;

      final card = _columns[fromColIndex].cards.firstWhere((c) => c.id == cardId);
      final newFromCards = List<_KanbanCard>.from(_columns[fromColIndex].cards)..removeWhere((c) => c.id == cardId);
      final newToCards = List<_KanbanCard>.from(_columns[toColIndex].cards);
      final insertAt = targetIndex.clamp(0, newToCards.length);
      newToCards.insert(insertAt, card);

      _columns[fromColIndex] = _columns[fromColIndex].copyWith(cards: newFromCards);
      _columns[toColIndex] = _columns[toColIndex].copyWith(cards: newToCards);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ScaColors.bgSecondary,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(ScaSpacing.s3),
        children: [
          for (final column in _columns)
            _KanbanColumnWidget(
              column: column,
              onCardDrop: (cardId, fromColId, targetIndex) {
                _moveCard(cardId, fromColId, column.id, targetIndex);
              },
            ),
        ],
      ),
    );
  }
}

// ---- Column Widget ----

class _KanbanColumnWidget extends StatefulWidget {
  final _KanbanColumn column;
  final void Function(String cardId, String fromColId, int targetIndex) onCardDrop;

  const _KanbanColumnWidget({
    required this.column,
    required this.onCardDrop,
  });

  @override
  State<_KanbanColumnWidget> createState() => _KanbanColumnWidgetState();
}

class _KanbanColumnWidgetState extends State<_KanbanColumnWidget> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      margin: const EdgeInsets.only(right: ScaSpacing.s3),
      child: DragTarget<Map<String, String>>(
        onWillAcceptWithDetails: (details) {
          setState(() => _isDragOver = true);
          return details.data['fromColId'] != widget.column.id;
        },
        onLeave: (_) => setState(() => _isDragOver = false),
        onAcceptWithDetails: (details) {
          setState(() => _isDragOver = false);
          widget.onCardDrop(
            details.data['cardId']!,
            details.data['fromColId']!,
            widget.column.cards.length,
          );
        },
        builder: (context, candidateData, rejectedData) {
          return AnimatedContainer(
            duration: ScaAnimation.fast,
            decoration: BoxDecoration(
              color: _isDragOver
                  ? ScaColors.focusRingLight
                  : ScaColors.bgPrimary,
              borderRadius: BorderRadius.circular(ScaRadius.lg),
              border: Border.all(
                color: _isDragOver
                    ? ScaColors.focusRing
                    : ScaColors.borderLight,
                width: _isDragOver ? 1.5 : 1,
              ),
              boxShadow: ScaShadows.light,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Column Header
                _ColumnHeader(column: widget.column),
                // Cards List
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: ScaSpacing.s2,
                      vertical: ScaSpacing.s1,
                    ),
                    itemCount: widget.column.cards.length,
                    itemBuilder: (context, index) {
                      return _DraggableCard(
                        card: widget.column.cards[index],
                        columnId: widget.column.id,
                      );
                    },
                  ),
                ),
                // Add card button
                Padding(
                  padding: const EdgeInsets.all(ScaSpacing.s2),
                  child: ScaFocusWrapper(
                    onTap: () {},
                    padding: const EdgeInsets.symmetric(
                      horizontal: ScaSpacing.s2,
                      vertical: ScaSpacing.s1,
                    ),
                    borderRadius: BorderRadius.circular(ScaRadius.sm),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: ScaColors.fontTertiary,
                        ),
                        SizedBox(width: ScaSpacing.s1),
                        Text(
                          'Ajouter une carte',
                          style: TextStyle(
                            fontSize: 12,
                            color: ScaColors.fontTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final _KanbanColumn column;

  const _ColumnHeader({required this.column});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ScaSpacing.s3,
        ScaSpacing.s3,
        ScaSpacing.s2,
        ScaSpacing.s2,
      ),
      child: Row(
        children: [
          // Color dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: column.color == ScaColors.neutralBg
                  ? ScaColors.fontLight
                  : column.color == ScaColors.infoBg
                      ? ScaColors.focusRing
                      : column.color == ScaColors.successBg
                          ? ScaColors.successFg
                          : column.color == ScaColors.warningBg
                              ? ScaColors.warningFg
                              : ScaColors.dangerFg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: ScaSpacing.s2),
          Text(
            column.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ScaColors.fontPrimary,
            ),
          ),
          const SizedBox(width: ScaSpacing.s1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: ScaColors.neutralBg,
              borderRadius: BorderRadius.circular(ScaRadius.full),
            ),
            child: Text(
              '${column.cards.length}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ScaColors.fontTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Draggable Card ----

class _DraggableCard extends StatefulWidget {
  final _KanbanCard card;
  final String columnId;

  const _DraggableCard({required this.card, required this.columnId});

  @override
  State<_DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<_DraggableCard> {
  bool _isDragging = false;

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cardWidget = AnimatedContainer(
      duration: ScaAnimation.fast,
      margin: const EdgeInsets.only(bottom: ScaSpacing.s2),
      decoration: BoxDecoration(
        color: _isDragging
            ? ScaColors.bgSecondary
            : ScaColors.bgPrimary,
        borderRadius: BorderRadius.circular(ScaRadius.md),
        border: Border.all(color: ScaColors.borderLight),
        boxShadow: _isDragging ? [] : ScaShadows.light,
      ),
      child: _isDragging
          ? const SizedBox(height: 80)
          : Padding(
              padding: const EdgeInsets.all(ScaSpacing.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.card.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ScaColors.fontPrimary,
                    ),
                  ),
                  if (widget.card.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.card.subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ScaColors.fontTertiary,
                      ),
                    ),
                  ],
                  if (widget.card.assigneeName != null ||
                      widget.card.status != null) ...[
                    const SizedBox(height: ScaSpacing.s2),
                    Row(
                      children: [
                        if (widget.card.status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ScaColors.successBg,
                              borderRadius:
                                  BorderRadius.circular(ScaRadius.full),
                            ),
                            child: Text(
                              widget.card.status!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: ScaColors.successFg,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (widget.card.assigneeName != null)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: ScaColors.focusRing,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _initials(widget.card.assigneeName!),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );

    return Draggable<Map<String, String>>(
      data: {'cardId': widget.card.id, 'fromColId': widget.columnId},
      onDragStarted: () => setState(() => _isDragging = true),
      onDragEnd: (_) => setState(() => _isDragging = false),
      onDraggableCanceled: (_, __) => setState(() => _isDragging = false),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 232,
          padding: const EdgeInsets.all(ScaSpacing.s3),
          decoration: BoxDecoration(
            color: ScaColors.bgPrimary,
            borderRadius: BorderRadius.circular(ScaRadius.md),
            border: Border.all(color: ScaColors.focusRing.withOpacity(0.3)),
            boxShadow: ScaShadows.superHeavy,
          ),
          child: Text(
            widget.card.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ScaColors.fontPrimary,
            ),
          ),
        ),
      ),
      childWhenDragging: cardWidget,
      child: cardWidget,
    );
  }
}
