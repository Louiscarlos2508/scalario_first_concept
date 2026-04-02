import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_logos.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';

// ── Prefs key ─────────────────────────────────────────────────────────────────

const kOnboardingDonePrefKey = 'scalario_onboarding_done';

// ── Colours (match prototype) ─────────────────────────────────────────────────

const _kSlate900  = Color(0xFF0F172A);
const _kSlate700  = Color(0xFF374151);
const _kSlate400  = Color(0xFF94A3B8);
const _kSlate200  = Color(0xFFE2E8F0);
const _kSlate100  = Color(0xFFF1F5F9);
const _kSlate50   = Color(0xFFF8FAFC);
const _kBlue      = Color(0xFF1A73E8);
const _kGreen     = Color(0xFF34A853);
const _kAmber900  = Color(0xFF92400E);
const _kAmber100  = Color(0xFFFFFBEB);
const _kAmberBorder = Color(0xFFFDE68A);

// ── Fake AI products shown after chat (V1 mock — real AI in H2) ──────────────

class _OnboardingProduct {
  final String emoji;
  final String name;
  final String meta;
  final int price;
  int qty = 1;

  _OnboardingProduct({
    required this.emoji,
    required this.name,
    required this.meta,
    required this.price,
  });
}

final _kDemoProducts = [
  _OnboardingProduct(emoji: '🧴', name: 'Savon Lux 200g', meta: 'Hygiène · unité', price: 500),
  _OnboardingProduct(emoji: '🛢️', name: 'Huile Palme 1L', meta: 'Alimentation · bouteille', price: 1200),
  _OnboardingProduct(emoji: '🥤', name: 'Fanta Orange 50cl', meta: 'Boissons · canette', price: 350),
];

// ── Chat message model ────────────────────────────────────────────────────────

enum _Sender { user, ai }

class _ChatMsg {
  final _Sender sender;
  final String? text;
  final bool isProductCard;
  final bool isTyping;

  const _ChatMsg({
    required this.sender,
    this.text,
    this.isProductCard = false,
    this.isTyping = false,
  });
}

// ── Module display list (matches _kAllModules in settings_screen) ─────────────

const _kModuleLabels = <String, String>{
  'catalog':        'Catalogue Produits',
  'clients':        'Gestion Clients',
  'inventory':      'Inventaire & Stock',
  'transactions':   'Transactions & Ventes',
  'expenses':       'Dépenses & Charges',
  'reports':        'Rapports & KPI',
  'retail':         'Point de Vente (POS)',
  'variants':       'Variantes Produit',
  'pricing':        'Multi-Tarifs',
  'promotions':     'Promotions & Remises',
  'purchase_orders':'Achats',
  'batches':        'Lots & Fraîcheur',
  'client_orders':  'Commandes Clients',
};

// ── Payment options ───────────────────────────────────────────────────────────

const _kPayments = ['Espèces', 'Orange Money', 'Moov Money'];

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  int _panel = 0; // 0–3

  // Panel 2 — chat
  final List<_ChatMsg> _messages = [];
  bool _productsShown = false;
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _aiTyping = false;

  // Panel 3 — cart & payment
  late final List<_OnboardingProduct> _products;
  String _selectedPayment = 'Espèces';

  @override
  void initState() {
    super.initState();
    _products = List.of(_kDemoProducts.map((p) =>
        _OnboardingProduct(
            emoji: p.emoji, name: p.name, meta: p.meta, price: p.price)));
    _messages.add(const _ChatMsg(
      sender: _Sender.ai,
      text:
          'Bonjour ! 👋 Décrivez vos produits en langage naturel — '
          'par exemple : "Savon Lux 200g à 500 FCFA". Je les crée pour vous.',
    ));
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _next() => setState(() => _panel++);

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingDonePrefKey, true);
    // Invalidate userProfile so main.dart re-evaluates routing.
    if (mounted) ref.invalidate(userProfileProvider);
  }

  // ── Panel 2 logic ─────────────────────────────────────────────────────────

  void _sendMessage() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty || _aiTyping) return;
    _chatCtrl.clear();

    setState(() {
      _messages.add(_ChatMsg(sender: _Sender.user, text: text));
      _aiTyping = true;
      _messages.add(const _ChatMsg(sender: _Sender.ai, isTyping: true));
    });
    _scrollToBottom();

    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        _aiTyping = false;
        if (!_productsShown) {
          _productsShown = true;
          _messages.add(const _ChatMsg(
            sender: _Sender.ai,
            text: 'J\'ai identifié ces produits dans votre catalogue :',
          ));
          _messages.add(const _ChatMsg(
            sender: _Sender.ai,
            isProductCard: true,
          ));
        } else {
          _messages.add(const _ChatMsg(
            sender: _Sender.ai,
            text:
                'Les produits sont déjà configurés. Vous pouvez les modifier manuellement dans le catalogue.',
          ));
        }
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final config  = ref.watch(businessTypeConfigProvider).valueOrNull;
    final tenantName = profile?.memberships.firstOrNull?.tenantName ?? 'Votre boutique';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (_panel < 3) _TopBar(panel: _panel, tenantName: tenantName),
            if (_panel < 3) _ProgressBar(panel: _panel),
            Expanded(child: _buildPanel(context, config, tenantName)),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context, dynamic config, String tenantName) {
    switch (_panel) {
      case 0:  return _buildBoutique(config, tenantName);
      case 1:  return _buildChat();
      case 2:  return _buildSale();
      default: return _buildSuccess(tenantName);
    }
  }

  // ── Panel 0 — Boutique ────────────────────────────────────────────────────

  Widget _buildBoutique(dynamic config, String tenantName) {
    final modules = _kModuleLabels.keys.toList();
    final activeModules = config?.defaultFlags.keys.toSet() ??
        {'catalog', 'retail', 'inventory', 'transactions', 'reports'};

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Votre boutique est prête',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _kSlate900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Votre intégrateur a configuré votre espace.\nVérifiez que tout est correct.',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 20),

                // Template card
                Container(
                  decoration: BoxDecoration(
                    color: _kSlate50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kSlate200, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kSlate100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kSlate200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 12, color: _kSlate400),
                            const SizedBox(width: 4),
                            Text(
                              config?.name ?? 'Modèle intégrateur',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Shop name
                      Text(tenantName,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _kSlate900)),
                      const SizedBox(height: 4),
                      const Text('Configuration validée par votre intégrateur',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF64748B))),
                      const SizedBox(height: 14),

                      // Module list
                      ...modules.take(7).map((code) {
                        final on = activeModules.contains(code);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: on ? _kGreen : _kSlate200,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _kModuleLabels[code] ?? code,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: on ? _kSlate700 : _kSlate400,
                                  decoration: on
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Integrator note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kAmber100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kAmberBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('⚠️', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pour modifier les modules actifs, contactez votre intégrateur.',
                          style: TextStyle(
                              fontSize: 12,
                              color: _kAmber900,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _CtaFooter(
          label: 'C\'est bon, continuer',
          onTap: _next,
        ),
      ],
    );
  }

  // ── Panel 1 — IA Chat ─────────────────────────────────────────────────────

  Widget _buildChat() {
    return Column(
      children: [
        // Chat messages
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: _messages.length,
            itemBuilder: (_, i) => _buildBubble(_messages[i]),
          ),
        ),

        // Suggestion chips (before first send)
        if (!_productsShown)
          _SuggestionChips(onTap: (text) {
            _chatCtrl.text = text;
            _sendMessage();
          }),

        // Confirm button (after products shown)
        if (_productsShown)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _CtaFooter(
              label: 'Confirmer les produits',
              onTap: _next,
              inlined: true,
            ),
          ),

        // Input row
        _ChatInput(
          controller: _chatCtrl,
          disabled: _aiTyping,
          onSend: _sendMessage,
          onImport: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Import CSV — bientôt disponible'),
                behavior: SnackBarBehavior.floating),
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(_ChatMsg msg) {
    if (msg.isTyping) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _AiAvatar(),
            const SizedBox(width: 8),
            const _TypingBubble(),
          ],
        ),
      );
    }

    if (msg.isProductCard) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _AiAvatar(),
            const SizedBox(width: 8),
            _ProductsCreatedCard(products: _products),
          ],
        ),
      );
    }

    final isUser = msg.sender == _Sender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[_AiAvatar(), const SizedBox(width: 8)],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? _kBlue : _kSlate100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                msg.text ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : _kSlate900,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[const SizedBox(width: 8), _UserAvatar()],
        ],
      ),
    );
  }

  // ── Panel 2 — Première vente ──────────────────────────────────────────────

  Widget _buildSale() {
    int total = _products.fold(0, (s, p) => s + p.price * p.qty);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Première vente test',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _kSlate900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Testez votre caisse avec vos nouveaux produits.',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 20),

                // Section label
                const Text('PRODUITS',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate400,
                        letterSpacing: 0.4)),
                const SizedBox(height: 10),

                // Cart items
                ..._products.map((p) => StatefulBuilder(
                      builder: (_, set) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _kSlate50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kSlate200, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Text(p.emoji,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(p.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _kSlate900)),
                              ),
                              _QtyControl(
                                value: p.qty,
                                onDecrement: () =>
                                    setState(() { if (p.qty > 1) p.qty--; }),
                                onIncrement: () =>
                                    setState(() => p.qty++),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 76,
                                child: Text(
                                  '${(p.price * p.qty).toString()} F',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _kSlate900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),

                const SizedBox(height: 4),

                // Total
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kSlate900,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white60,
                              fontWeight: FontWeight.w500)),
                      Text('$total FCFA',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Payment chips
                const Text('MODE DE PAIEMENT',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate400,
                        letterSpacing: 0.4)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kPayments
                      .map((p) => _PaymentChip(
                            label: p,
                            selected: _selectedPayment == p,
                            onTap: () =>
                                setState(() => _selectedPayment = p),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        _CtaFooter(label: 'Valider la vente test', onTap: _next),
      ],
    );
  }

  // ── Panel 3 — Succès ──────────────────────────────────────────────────────

  Widget _buildSuccess(String tenantName) {
    final total = _products.fold(0, (s, p) => s + p.price * p.qty);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF34A853), Color(0xFF22C55E)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _kGreen.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Vous êtes prêt !',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kSlate900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Votre boutique est configurée et votre\npremière vente test a réussi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.6),
                ),
                const SizedBox(height: 24),

                // Receipt card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kSlate50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kSlate200, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      _ReceiptRow(
                          label: 'Boutique', value: tenantName),
                      const SizedBox(height: 10),
                      _ReceiptRow(
                          label: 'Produits configurés',
                          value: '${_products.length}'),
                      const SizedBox(height: 10),
                      _ReceiptRow(
                          label: 'Vente test',
                          value: '$total FCFA',
                          valueGreen: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'La vente test ne figure pas dans vos rapports réels.\nVous pouvez commencer à utiliser Scalario dès maintenant.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: _kSlate400,
                      height: 1.6),
                ),
              ],
            ),
          ),
        ),
        _CtaFooter(
          label: 'Aller au tableau de bord',
          green: true,
          onTap: _complete,
        ),
      ],
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int panel;
  final String tenantName;

  const _TopBar({required this.panel, required this.tenantName});

  static const _titles = ['Configuration', 'Mes produits', 'Première vente'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kSlate100)),
      ),
      child: Row(
        children: [
          AppLogos.monogram(context, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _titles[panel.clamp(0, 2)],
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kSlate900),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Étape ${panel + 1}/3',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kBlue),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int panel; // 0–2

  const _ProgressBar({required this.panel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: List.generate(3, (i) {
          Color color;
          if (i < panel) {
            color = _kGreen;
          } else if (i == panel) {
            color = _kBlue;
          } else {
            color = _kSlate200;
          }
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── CTA footer ────────────────────────────────────────────────────────────────

class _CtaFooter extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool green;
  final bool inlined;

  const _CtaFooter({
    required this.label,
    required this.onTap,
    this.green = false,
    this.inlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: green ? _kGreen : _kBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          shadowColor: (green ? _kGreen : _kBlue).withValues(alpha: 0.3),
          elevation: 4,
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );

    if (inlined) return btn;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kSlate100)),
      ),
      child: btn,
    );
  }
}

// ── Chat sub-widgets ──────────────────────────────────────────────────────────

class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_kBlue, _kGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _kSlate900,
      ),
      child: const Center(
        child: Text('B',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
        3,
        (i) => AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1200)));
    _anims = _ctrls.map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOut)).toList();
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200),
          () { if (mounted) _ctrls[i].repeat(reverse: true); });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: _kSlate100,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, _) => Container(
              margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kSlate400.withValues(
                    alpha: 0.4 + 0.6 * _anims[i].value),
              ),
              transform: Matrix4.translationValues(
                  0, -5 * _anims[i].value, 0),
            ),
          );
        }),
      ),
    );
  }
}

class _ProductsCreatedCard extends StatelessWidget {
  final List<_OnboardingProduct> products;

  const _ProductsCreatedCard({required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
              SizedBox(width: 6),
              Text(
                'Produits identifiés',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...products.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Row(
                  children: [
                    Text(p.emoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kSlate900)),
                          Text(p.meta,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Text('${p.price} F',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _SuggestionChips({required this.onTap});

  static const _chips = [
    'Savon 200g à 500 F',
    'Huile 1L à 1 200 F',
    'Jus canette 350 F',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: _chips
            .map((c) => GestureDetector(
                  onTap: () => onTap(c),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kSlate200, width: 1.5),
                    ),
                    child: Text(c,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kSlate700)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool disabled;
  final VoidCallback onSend;
  final VoidCallback onImport;

  const _ChatInput({
    required this.controller,
    required this.disabled,
    required this.onSend,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kSlate100)),
      ),
      child: Row(
        children: [
          // Import button
          GestureDetector(
            onTap: onImport,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kSlate100,
                shape: BoxShape.circle,
                border: Border.all(color: _kSlate200, width: 1.5),
              ),
              child: const Icon(Icons.upload_file_outlined,
                  size: 18, color: _kSlate400),
            ),
          ),
          const SizedBox(width: 8),
          // Text input
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !disabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(fontSize: 14, color: _kSlate900),
              decoration: InputDecoration(
                hintText: 'Décrivez vos produits…',
                hintStyle:
                    const TextStyle(fontSize: 14, color: _kSlate400),
                filled: true,
                fillColor: _kSlate50,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: _kSlate200, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: _kSlate200, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: _kBlue, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: disabled ? null : onSend,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: disabled
                    ? _kSlate200
                    : _kBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Panel 3 sub-widgets ───────────────────────────────────────────────────────

class _QtyControl extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QtyControl({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyBtn(icon: Icons.remove, onTap: onDecrement),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kSlate900),
          ),
        ),
        const SizedBox(width: 8),
        _QtyBtn(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kSlate200, width: 1.5),
        ),
        child: Icon(icon, size: 14, color: _kSlate700),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kBlue : _kSlate200,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? _kBlue : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ── Panel 4 sub-widget ────────────────────────────────────────────────────────

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueGreen;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueGreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueGreen ? const Color(0xFF16A34A) : _kSlate900,
          ),
        ),
      ],
    );
  }
}
