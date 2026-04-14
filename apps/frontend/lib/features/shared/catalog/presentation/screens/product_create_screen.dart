import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Création / Édition produit — Figma 46:2
// Mobile création  : 46:3  (nouveau, tous les champs)
// Mobile vrac      : 46:268 (mode vrac actif)
// Mobile édition   : 46:409 (modifier existant, simplifié)
// Desktop création : 46:510 (inline dans shell, 2 colonnes + sidebar récap)
// ══════════════════════════════════════════════════════════════════════════════

/// Mobile entry point — pushed via Navigator.
class ProductCreateScreen extends ConsumerStatefulWidget {
  const ProductCreateScreen({super.key, this.product});

  /// If non-null, the form is in edit mode with pre-filled values.
  final Map<String, dynamic>? product;

  @override
  ConsumerState<ProductCreateScreen> createState() =>
      _ProductCreateScreenState();
}

class _ProductCreateScreenState extends ConsumerState<ProductCreateScreen> {
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: ScalarioAppBar(
        title: isEdit
            ? 'Éditer · ${widget.product!['name']}'
            : 'Nouveau produit',
        leadingOverride: isEdit
            ? null // default back arrow
            : GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: Text('×',
                        style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w400)),
                  ),
                ),
              ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ProductCreateBody(
              product: widget.product,
              onSaved: () => Navigator.of(context).pop(),
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ProductCreateBody — reusable form content (mobile + desktop)
// ══════════════════════════════════════════════════════════════════════════════

class ProductCreateBody extends ConsumerStatefulWidget {
  const ProductCreateBody({
    super.key,
    this.product,
    this.onSaved,
    this.onCancel,
    this.showDesktopActions = false,
  });

  final Map<String, dynamic>? product;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;
  final bool showDesktopActions;

  @override
  ConsumerState<ProductCreateBody> createState() => _ProductCreateBodyState();
}

class _ProductCreateBodyState extends ConsumerState<ProductCreateBody> {
  // ── Form controllers ──
  late final TextEditingController _nameCtrl;
  late final TextEditingController _eanCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _buyPriceCtrl;
  late final TextEditingController _retailPriceCtrl;
  late final TextEditingController _wholesalePriceCtrl;
  late final TextEditingController _wholesaleQtyCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _alertCtrl;
  late final TextEditingController _supplierCtrl;
  late final TextEditingController _supplierRefCtrl;

  // Vrac fields
  late final TextEditingController _vracBuyUnitCtrl;
  late final TextEditingController _vracBuyPriceCtrl;
  late final TextEditingController _vracSellUnitCtrl;
  late final TextEditingController _vracSellPriceCtrl;

  // Frotte fields
  late final TextEditingController _frottePercentCtrl;

  // Freshness fields
  late final TextEditingController _freshDaysCtrl;
  late final TextEditingController _freshAlertCtrl;

  String _category = '';
  String _unit = 'Kilogramme (kg)';

  bool _isPerishable = false;
  bool _isFrotte = false;
  bool _isVrac = false;
  bool _hasSupplier = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _nameCtrl = TextEditingController(text: p?['name']?.toString() ?? '');
    _eanCtrl = TextEditingController(text: p?['ean']?.toString() ?? '');
    _descCtrl =
        TextEditingController(text: p?['description']?.toString() ?? '');
    _buyPriceCtrl =
        TextEditingController(text: p?['buyPrice']?.toString() ?? '');
    _retailPriceCtrl =
        TextEditingController(text: p?['retailPrice']?.toString() ?? '');
    _wholesalePriceCtrl =
        TextEditingController(text: p?['wholesalePrice']?.toString() ?? '');
    _wholesaleQtyCtrl = TextEditingController();
    _stockCtrl =
        TextEditingController(text: p?['stockQuantity']?.toString() ?? '');
    _alertCtrl =
        TextEditingController(text: p?['minStockLevel']?.toString() ?? '');
    _supplierCtrl =
        TextEditingController(text: p?['supplier']?.toString() ?? '');
    _supplierRefCtrl = TextEditingController();
    _vracBuyUnitCtrl = TextEditingController();
    _vracBuyPriceCtrl = TextEditingController();
    _vracSellUnitCtrl = TextEditingController();
    _vracSellPriceCtrl = TextEditingController();
    _frottePercentCtrl = TextEditingController();
    _freshDaysCtrl = TextEditingController(text: p != null ? '5' : '');
    _freshAlertCtrl = TextEditingController(text: p != null ? '2' : '');

    if (p != null) {
      _category = p['categoryName']?.toString() ?? '';
      _isPerishable = p['freshnessStatus'] != null;
      _hasSupplier = (p['supplier']?.toString() ?? '').isNotEmpty;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _eanCtrl, _descCtrl, _buyPriceCtrl, _retailPriceCtrl,
      _wholesalePriceCtrl, _wholesaleQtyCtrl, _stockCtrl, _alertCtrl,
      _supplierCtrl, _supplierRefCtrl, _vracBuyUnitCtrl, _vracBuyPriceCtrl,
      _vracSellUnitCtrl, _vracSellPriceCtrl, _frottePercentCtrl,
      _freshDaysCtrl, _freshAlertCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Computed margin ──
  double? get _margin {
    final buy = double.tryParse(_buyPriceCtrl.text);
    final sell = double.tryParse(_retailPriceCtrl.text);
    if (buy == null || sell == null || buy <= 0) return null;
    return ((sell - buy) / buy) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 0 : 0,
              vertical: isDesktop ? 0 : 0,
            ),
            child: isDesktop ? _buildDesktopForm() : _buildMobileForm(),
          ),
        ),
        if (!widget.showDesktopActions) _buildMobileBottomBar(),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOBILE FORM — Figma 46:3 (création) / 46:409 (édition)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobileForm() {
    if (_isEdit) return _buildMobileEditForm();
    return _buildMobileCreateForm();
  }

  // ── Mobile création (46:3) ──────────────────────────────────────────────

  Widget _buildMobileCreateForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image upload zone ──
        Center(child: _buildImageUploadZone()),
        const SizedBox(height: 4),

        // ── Section: Infos générales ──
        _sectionDivider(),
        _sectionHeader('📋', 'INFOS GÉNÉRALES'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('NOM DU PRODUIT*'),
              const SizedBox(height: 6),
              _textField(_nameCtrl, 'Tomate fraîche locale'),
              const SizedBox(height: 16),
              _fieldLabel('CODE-BARRES'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                      child: _textField(_eanCtrl, 'EAN / scanner')),
                  const SizedBox(width: 10),
                  _scanButton(),
                ],
              ),
              const SizedBox(height: 16),
              _fieldLabel('CATÉGORIE*'),
              const SizedBox(height: 6),
              _dropdownField(
                value: _category.isEmpty ? null : _category,
                hint: 'Légumes · Frais',
                items: const [
                  'Légumes · Frais',
                  'Fruits',
                  'Légumes',
                  'Frais',
                  'Céréales · Sec',
                  'Épices',
                  'Conserves',
                  'Hygiène',
                ],
                onChanged: (v) => setState(() => _category = v ?? ''),
              ),
              const SizedBox(height: 16),
              _fieldLabel('DESCRIPTION (OPTIONNEL)'),
              const SizedBox(height: 6),
              _textField(_descCtrl, 'Variété, origine…', maxLines: 2),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Section: Prix & vente ──
        _sectionDivider(),
        _sectionHeader('💰', 'PRIX & VENTE'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('PRIX D\'ACHAT HT'),
              const SizedBox(height: 6),
              _priceField(_buyPriceCtrl, 'F / kg'),
              const SizedBox(height: 16),
              _fieldLabel('PRIX VENTE DÉTAIL*'),
              const SizedBox(height: 6),
              _priceField(_retailPriceCtrl, 'F / kg', focused: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('PRIX GROS'),
                        const SizedBox(height: 6),
                        _priceFieldCompact(_wholesalePriceCtrl, 'F'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('QTÉ MIN GROS'),
                        const SizedBox(height: 6),
                        _unitFieldCompact(_wholesaleQtyCtrl, 'kg'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _marginBar(),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Section: Stock ──
        _sectionDivider(),
        _sectionHeader('📦', 'STOCK'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('QTÉ INITIALE'),
                        const SizedBox(height: 6),
                        _unitFieldCompact(_stockCtrl, 'kg'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('SEUIL ALERTE'),
                        const SizedBox(height: 6),
                        _unitFieldCompact(_alertCtrl, 'kg'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _fieldLabel('UNITÉ DE BASE'),
              const SizedBox(height: 6),
              _dropdownField(
                value: _unit,
                hint: 'Kilogramme (kg)',
                items: const [
                  'Kilogramme (kg)',
                  'Gramme (g)',
                  'Litre (L)',
                  'Pièce',
                  'Sachet',
                  'Boîte',
                ],
                onChanged: (v) => setState(() => _unit = v ?? _unit),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Toggle options ──
        _sectionDivider(),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _toggleOption(
                icon: '🍃',
                label: 'Périssable / fraîcheur',
                subtitle:
                    'Suivre la durée de vie et alertes péremption',
                value: _isPerishable,
                onChanged: (v) => setState(() => _isPerishable = v),
              ),
              if (_isPerishable) ...[
                const SizedBox(height: 12),
                _buildFreshnessFields(),
              ],
              const SizedBox(height: 16),
              _toggleOption(
                icon: '🧊',
                label: 'Frotte (casse / perte)',
                subtitle: 'Appliqué auto à chaque réception',
                value: _isFrotte,
                onChanged: (v) => setState(() => _isFrotte = v),
              ),
              if (_isFrotte) ...[
                const SizedBox(height: 12),
                _buildFrotteFields(),
              ],
              const SizedBox(height: 16),
              _toggleOption(
                icon: '📦',
                label: 'Vrac → sachet',
                subtitle:
                    'Acheter en vrac, conditionner et revendre en sachets/unités',
                value: _isVrac,
                onChanged: (v) => setState(() => _isVrac = v),
              ),
              if (_isVrac) ...[
                const SizedBox(height: 12),
                _buildVracFields(),
              ],
              const SizedBox(height: 16),
              _toggleOption(
                icon: '🚚',
                label: 'Fournisseur principal',
                subtitle:
                    'Optionnel — pour suivi achats',
                value: _hasSupplier,
                onChanged: (v) => setState(() => _hasSupplier = v),
              ),
              if (_hasSupplier) ...[
                const SizedBox(height: 12),
                _buildSupplierFields(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Mobile édition (46:409) ─────────────────────────────────────────────

  Widget _buildMobileEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Product image ──
        Center(child: _buildImageUploadZone()),
        const SizedBox(height: 4),

        // ── Section: Prix & vente ──
        _sectionDivider(),
        _sectionHeader('💰', 'PRIX & VENTE'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('PRIX D\'ACHAT'),
              const SizedBox(height: 6),
              _priceField(_buyPriceCtrl, 'F / kg'),
              const SizedBox(height: 16),
              _fieldLabel('PRIX VENTE DÉTAIL'),
              const SizedBox(height: 6),
              _priceField(_retailPriceCtrl, 'F / kg', focused: true),
              const SizedBox(height: 12),
              _marginBar(label: 'NOUVELLE MARGE'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Section: Stock ──
        _sectionDivider(),
        _sectionHeader('📦', 'STOCK'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('QTÉ ACTUELLE'),
                        const SizedBox(height: 6),
                        _unitFieldCompact(_stockCtrl, 'kg'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('SEUIL ALERTE'),
                        const SizedBox(height: 6),
                        _unitFieldCompact(_alertCtrl, 'kg'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'La quantité ne se modifie pas ici — passez par "Mouvements stock" pour ajuster.',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DESKTOP FORM — Figma 46:510 (two columns + sidebar recap)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktopForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main form column ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Infos générales card
                _desktopCard(
                  icon: '📋',
                  title: 'Infos générales',
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image upload
                      _buildImageUploadZone(size: 140),
                      const SizedBox(width: 20),
                      // Fields
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('NOM DU PRODUIT*'),
                                      const SizedBox(height: 6),
                                      _textField(
                                          _nameCtrl, 'Tomate fraîche locale'),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('CODE-BARRES'),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: _textField(
                                                  _eanCtrl, 'EAN')),
                                          const SizedBox(width: 8),
                                          _scanButton(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('CATÉGORIE*'),
                                      const SizedBox(height: 6),
                                      _dropdownField(
                                        value: _category.isEmpty
                                            ? null
                                            : _category,
                                        hint: 'Légumes · Frais',
                                        items: const [
                                          'Légumes · Frais',
                                          'Fruits',
                                          'Légumes',
                                          'Frais',
                                          'Céréales · Sec',
                                          'Épices',
                                          'Conserves',
                                          'Hygiène',
                                        ],
                                        onChanged: (v) => setState(
                                            () => _category = v ?? ''),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('FOURNISSEUR'),
                                      const SizedBox(height: 6),
                                      _textField(_supplierCtrl,
                                          'Marché Sankaryaré'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _fieldLabel('DESCRIPTION'),
                            const SizedBox(height: 6),
                            _textField(_descCtrl, 'Variété, origine…'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Prix & vente card
                _desktopCard(
                  icon: '💰',
                  title: 'Prix & vente',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('PRIX D\'ACHAT'),
                                const SizedBox(height: 6),
                                _priceField(_buyPriceCtrl, 'F / kg'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('PRIX DÉTAIL*'),
                                const SizedBox(height: 6),
                                _priceField(_retailPriceCtrl, 'F / kg',
                                    focused: true),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('PRIX GROS (≥ 5KG)'),
                                const SizedBox(height: 6),
                                _priceField(
                                    _wholesalePriceCtrl, 'F / kg'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _marginBar(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stock & seuils card
                _desktopCard(
                  icon: '📦',
                  title: 'Stock & seuils',
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('QTÉ INITIALE'),
                            const SizedBox(height: 6),
                            _unitFieldCompact(_stockCtrl, 'kg'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('SEUIL ALERTE'),
                            const SizedBox(height: 6),
                            _unitFieldCompact(_alertCtrl, 'kg'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('UNITÉ DE BASE'),
                            const SizedBox(height: 6),
                            _dropdownField(
                              value: _unit,
                              hint: 'Kilogramme (kg)',
                              items: const [
                                'Kilogramme (kg)',
                                'Gramme (g)',
                                'Litre (L)',
                                'Pièce',
                                'Sachet',
                                'Boîte',
                              ],
                              onChanged: (v) =>
                                  setState(() => _unit = v ?? _unit),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Options spécifiques card
                _desktopCard(
                  icon: '⚙',
                  title: 'Options spécifiques',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _toggleOptionDesktop(
                        icon: '🍃',
                        label: 'Périssable / fraîcheur',
                        subtitle: _isPerishable
                            ? 'Durée de vie ${_freshDaysCtrl.text.isEmpty ? "…" : "${_freshDaysCtrl.text} j"} · alerte rouge ${_freshAlertCtrl.text.isEmpty ? "…" : "${_freshAlertCtrl.text} j"} avant'
                            : 'Suivre la durée de vie et alertes péremption',
                        value: _isPerishable,
                        onChanged: (v) => setState(() => _isPerishable = v),
                      ),
                      if (_isPerishable) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _buildFreshnessFields(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _toggleOptionDesktop(
                        icon: '🧊',
                        label: 'Frotte (taux casse)',
                        subtitle: _isFrotte
                            ? '${_frottePercentCtrl.text.isEmpty ? "…" : "${_frottePercentCtrl.text}%"} — appliqué à chaque réception'
                            : 'Appliqué auto à chaque réception',
                        value: _isFrotte,
                        onChanged: (v) => setState(() => _isFrotte = v),
                      ),
                      if (_isFrotte) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _buildFrotteFields(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _toggleOptionDesktop(
                        icon: '📦',
                        label: 'Vrac → sachet',
                        subtitle: 'Acheter en vrac, vendre en sachets',
                        value: _isVrac,
                        onChanged: (v) => setState(() => _isVrac = v),
                      ),
                      if (_isVrac) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _buildVracFields(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // ── Sidebar: Récap + Astuce ──
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecapCard(),
                const SizedBox(height: 16),
                _buildAstuceCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED FORM WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _sectionDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 0.8,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _sectionHeader(String emoji, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w400),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdownField({
    String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 20, color: Color(0xFF64748B)),
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A)),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _scanButton() {
    return Container(
      width: 46,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
      ),
    );
  }

  /// Price field with suffix unit label (e.g. "F / kg")
  Widget _priceField(TextEditingController ctrl, String suffix,
      {bool focused = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'RobotoMono'),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: const TextStyle(
            fontSize: 15,
            color: Color(0xFFCBD5E1),
            fontFamily: 'RobotoMono'),
        suffixText: suffix,
        suffixStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color:
                  focused ? AppColors.primary : const Color(0xFFE2E8F0),
              width: focused ? 1.5 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  /// Compact price field (no suffix inside, just value + external unit)
  Widget _priceFieldCompact(TextEditingController ctrl, String unitLabel) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'RobotoMono'),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFCBD5E1),
                  fontFamily: 'RobotoMono'),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(unitLabel,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569))),
      ],
    );
  }

  /// Compact unit field (value + grey unit badge)
  Widget _unitFieldCompact(TextEditingController ctrl, String unit) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'RobotoMono'),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFCBD5E1),
                  fontFamily: 'RobotoMono'),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              unit,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _marginBar({String label = 'MARGE CALCULÉE AUTO'}) {
    final margin = _margin;
    final hasMargin = margin != null && margin > 0;
    final marginText = hasMargin ? '+${margin.toStringAsFixed(0)}%' : '';

    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasMargin
              ? [const Color(0xFF16A34A), const Color(0xFF22C55E)]
              : [const Color(0xFFE2E8F0), const Color(0xFFE2E8F0)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: hasMargin ? Colors.white : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (hasMargin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                marginText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required String icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFF0F7FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppColors.primary.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  /// Desktop toggle — more compact, subtitle shows current values
  Widget _toggleOptionDesktop({
    required String icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFF0F7FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppColors.primary.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // ── Sub-fields for toggles ──

  Widget _buildFreshnessFields() {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('DURÉE DE VIE*'),
                    const SizedBox(height: 6),
                    _unitFieldCompact(_freshDaysCtrl, 'jours'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('ALERTE ROUGE AVANT'),
                    const SizedBox(height: 6),
                    _unitFieldCompact(_freshAlertCtrl, 'j'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Le produit passera en orange à 2 jours de la péremption, et en rouge à 0 jours.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFrotteFields() {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('TAUX DE FROTTE ESTIMÉ'),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _frottePercentCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'RobotoMono'),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFCBD5E1),
                        fontFamily: 'RobotoMono'),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('%',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVracFields() {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('UNITÉ D\'ACHAT*'),
          const SizedBox(height: 6),
          _textField(_vracBuyUnitCtrl, 'Sac de 50 kg'),
          const SizedBox(height: 12),
          _fieldLabel('PRIX D\'ACHAT (SAC ENTIER)'),
          const SizedBox(height: 6),
          _priceField(_vracBuyPriceCtrl, 'F / sac'),
          const SizedBox(height: 12),
          _fieldLabel('UNITÉ DE VENTE DÉTAIL*'),
          const SizedBox(height: 6),
          _textField(_vracSellUnitCtrl, 'Sachet 1 kg'),
          const SizedBox(height: 12),
          _fieldLabel('PRIX VENTE DÉTAIL*'),
          const SizedBox(height: 6),
          _priceField(_vracSellPriceCtrl, 'F / sachet', focused: true),
          const SizedBox(height: 10),
          // Ratio + marge
          _buildVracRatioBar(),
          const SizedBox(height: 8),
          const Text(
            '1 sac de 50 kg = 50 sachets : prix de revient ajusté auto à 480 F/sachet (frotte incluse).',
            style: TextStyle(
                fontSize: 11, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildVracRatioBar() {
    final buyPrice = double.tryParse(_vracBuyPriceCtrl.text);
    final sellPrice = double.tryParse(_vracSellPriceCtrl.text);
    final hasValues = buyPrice != null && sellPrice != null && buyPrice > 0;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: hasValues
            ? const Color(0xFFE0F2FE)
            : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            'RATIO + MARGE AUTO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: hasValues
                  ? AppColors.primary
                  : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (hasValues) ...[
            Text(
              '×50',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 6),
            const Text('·',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(width: 6),
            Text(
              '+35%',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupplierFields() {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('FOURNISSEUR'),
          const SizedBox(height: 6),
          _textField(_supplierCtrl, 'Marché Sankaryaré'),
          const SizedBox(height: 12),
          _fieldLabel('RÉFÉRENCE CHEZ LE FOURNISSEUR'),
          const SizedBox(height: 6),
          _textField(_supplierRefCtrl, ''),
        ],
      ),
    );
  }

  // ── Image upload zone ──

  Widget _buildImageUploadZone({double size = 160}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: _isEdit
                        ? Color(widget.product?['emojiBg'] as int? ??
                            0xFFFEE2E2)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                    border: _isEdit
                        ? null
                        : Border.all(
                            color: const Color(0xFFCBD5E1), width: 1.5),
                  ),
                  child: Center(
                    child: _isEdit
                        ? Text(
                            widget.product?['emoji']?.toString() ?? '📷',
                            style: TextStyle(fontSize: size * 0.4))
                        : Icon(Icons.camera_alt_outlined,
                            size: size * 0.25,
                            color: const Color(0xFF94A3B8)),
                  ),
                ),
                // "+" blue badge
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        _isEdit ? Icons.edit : Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isEdit
                ? 'Tap pour changer la photo'
                : 'Ajouter une photo (caméra ou galerie)',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Desktop card wrapper ──
  Widget _desktopCard({
    required String icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── Desktop sidebar: Récap produit ──
  Widget _buildRecapCard() {
    final margin = _margin;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RÉCAP PRODUIT',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5)),
          const SizedBox(height: 14),
          _recapRow('Nom', _nameCtrl.text.isEmpty ? '—' : _nameCtrl.text),
          _recapRowBadge('Catégorie', _category.isEmpty ? '—' : _category.split(' · ').first.toUpperCase()),
          _recapRow(
              'Stock initial',
              _stockCtrl.text.isEmpty
                  ? '—'
                  : '${_stockCtrl.text}  kg'),
          _recapRow(
              'Seuil alerte',
              _alertCtrl.text.isEmpty
                  ? '—'
                  : '${_alertCtrl.text}  kg'),
          _recapRow(
              'Prix détail',
              _retailPriceCtrl.text.isEmpty
                  ? '—'
                  : '${_retailPriceCtrl.text} F'),
          _recapRowColored(
              'Marge',
              margin != null && margin > 0
                  ? '+${margin.toStringAsFixed(0)}%'
                  : '—',
              margin != null && margin > 0
                  ? const Color(0xFF16A34A)
                  : null),
          _recapRow(
              'Périssable',
              _isPerishable
                  ? '${_freshDaysCtrl.text.isEmpty ? "…" : _freshDaysCtrl.text}  j'
                  : '—'),
          _recapRow('Frotte',
              _isFrotte ? (_frottePercentCtrl.text.isEmpty ? '…' : '${_frottePercentCtrl.text}%') : '—'),
        ],
      ),
    );
  }

  Widget _recapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B))),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _recapRowBadge(String label, String badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B))),
          const Spacer(),
          if (badge != '—')
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.3)),
            )
          else
            const Text('—',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _recapRowColored(String label, String value, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B))),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color ?? const Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // ── Desktop sidebar: Astuce card ──
  Widget _buildAstuceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✨', style: TextStyle(fontSize: 14)),
              SizedBox(width: 6),
              Text('ASTUCE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Active "Vrac → sachet" si tu achètes en gros pour reconditionner. Scalario calcule auto le ratio et la marge par sachet.',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Mobile bottom action bar — Figma 46:3 / 46:409 ──
  Widget _buildMobileBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
      ),
      child: Row(
        children: [
          // Left button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: widget.onCancel ?? () => Navigator.of(context).pop(),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Text(
                    _isEdit ? 'Annuler' : '+ Autre',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Right button (primary CTA)
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _save(),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _isEdit ? '✓ Mettre à jour' : '✓ Enregistrer',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    // TODO: implement save logic
    widget.onSaved?.call();
  }
}
