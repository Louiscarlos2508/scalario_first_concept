class TypedProps<T> {
  final Map<String, dynamic> raw;

  const TypedProps(this.raw);

  T _cast<T>(String key, {T? fallback}) {
    final val = raw[key];
    if (val is T) return val;
    if (fallback != null) return fallback;
    throw FormatException('Expected $T for key "$key", got ${val?.runtimeType}');
  }

  String? getString(String key) => raw[key] as String?;
  String getStringRequired(String key) => _cast<String>(key);
  double? getDouble(String key) => (raw[key] as num?)?.toDouble();
  double getDoubleRequired(String key) => _cast<num>(key).toDouble();
  int? getInt(String key) => (raw[key] as num?)?.toInt();
  int getIntRequired(String key) => _cast<num>(key).toInt();
  bool? getBool(String key) => raw[key] as bool?;
  bool getBoolRequired(String key) => _cast<bool>(key);
  List<dynamic>? getList(String key) => raw[key] as List<dynamic>?;
  List<dynamic> getListRequired(String key) => _cast<List<dynamic>>(key);
  Map<String, dynamic>? getMap(String key) => raw[key] as Map<String, dynamic>?;
  Map<String, dynamic> getMapRequired(String key) => _cast<Map<String, dynamic>>(key);
}

class KPICardProps extends TypedProps<KPICardProps> {
  const KPICardProps(super.raw);

  String get label => getString('label') ?? getString('text') ?? '';
  String? get value => getString('value');
  String? get unit => getString('unit');
  String? get status => getString('status');
  String? get icon => getString('icon');
  String? get delta => getString('delta');
  bool? get deltaPositive => getBool('delta_positive');
  double? get minHeight => getDouble('min_height');
}

class ActionButtonProps extends TypedProps<ActionButtonProps> {
  const ActionButtonProps(super.raw);

  String get label => getString('label') ?? getString('text') ?? '';
  String? get icon => getString('icon');
  String? get size => getString('size');
  String? get variant => getString('variant');
  String? get labelKey => getString('label_key');
  Map<String, dynamic>? get action => getMap('action');
  bool get disabled => getBool('disabled') ?? false;
}

class TextProps extends TypedProps<TextProps> {
  const TextProps(super.raw);

  String get text => getString('text') ?? getString('label') ?? '';
  String? get style => getString('style');
  String? get align => getString('align');
  String? get color => getString('color');
}

class DataTableProps extends TypedProps<DataTableProps> {
  const DataTableProps(super.raw);

  String? get title => getString('title');
  List<dynamic> get columns => getList('columns') ?? [];
  List<dynamic> get rows => getList('rows') ?? [];
}

class FormWidgetProps extends TypedProps<FormWidgetProps> {
  const FormWidgetProps(super.raw);

  String? get title => getString('title');
  String? get submitLabel => getString('submit_label') ?? getString('submit_text');
  List<dynamic> get fields => getList('fields') ?? [];
  bool get readonly => getBool('readonly') ?? false;
}

class SearchBarProps extends TypedProps<SearchBarProps> {
  const SearchBarProps(super.raw);

  String? get placeholder => getString('placeholder');
  String? get placeholderKey => getString('placeholder_key');
  int get debounceMs => getInt('debounce_ms') ?? 300;
  int get minChars => getInt('min_chars') ?? 2;
}

class ChipSelectorProps extends TypedProps<ChipSelectorProps> {
  const ChipSelectorProps(super.raw);

  String? get label => getString('label');
  String? get labelKey => getString('label_key');
  bool get multiple => getBool('multiple') ?? true;
  List<dynamic> get options => getList('options') ?? [];
}

class QuantityControlProps extends TypedProps<QuantityControlProps> {
  const QuantityControlProps(super.raw);

  double get min => getDouble('min') ?? 0.1;
  double? get max => getDouble('max');
  double get step => getDouble('step') ?? 1.0;
  double? get value => getDouble('value');
}

class AlertBannerProps extends TypedProps<AlertBannerProps> {
  const AlertBannerProps(super.raw);

  String get message => getString('message') ?? getString('message_key') ?? '';
  String? get messageKey => getString('message_key');
  String? get variant => getString('variant');
  int? get durationMs => getInt('duration_ms');
}

class CartSummaryProps extends TypedProps<CartSummaryProps> {
  const CartSummaryProps(super.raw);

  String? get title => getString('title');
  String? get titleKey => getString('title_key');
}

class ProductGridProps extends TypedProps<ProductGridProps> {
  const ProductGridProps(super.raw);

  int get pageSize => getInt('page_size') ?? 50;
}

class ConfirmationDialogProps extends TypedProps<ConfirmationDialogProps> {
  const ConfirmationDialogProps(super.raw);

  String get title => getString('title') ?? 'Confirmer';
  String get message => getString('message') ?? getString('message_key') ?? '';
  String? get confirmLabel => getString('confirm_label') ?? getString('confirm_text');
  String? get cancelLabel => getString('cancel_label') ?? getString('cancel_text');
  bool get destructive => getBool('destructive') ?? false;
}

class EmptyStateProps extends TypedProps<EmptyStateProps> {
  const EmptyStateProps(super.raw);

  String? get icon => getString('icon');
  String? get title => getString('title');
  String? get titleKey => getString('title_key');
  String? get description => getString('description');
  String? get descriptionKey => getString('description_key');
  Map<String, dynamic>? get action => getMap('action');
}

class ErrorStateProps extends TypedProps<ErrorStateProps> {
  const ErrorStateProps(super.raw);

  String? get icon => getString('icon');
  String? get title => getString('title');
  String? get titleKey => getString('title_key');
  String? get description => getString('description');
  String? get descriptionKey => getString('description_key');
  Map<String, dynamic>? get action => getMap('action');
}

class StatusBadgeProps extends TypedProps<StatusBadgeProps> {
  const StatusBadgeProps(super.raw);

  String? get label => getString('label');
  String? get labelKey => getString('label_key');
  String? get variant => getString('variant');
  String? get color => getString('color');
}

class PeriodSelectorProps extends TypedProps<PeriodSelectorProps> {
  const PeriodSelectorProps(super.raw);

  List<String> get periods => (getList('periods') ?? ['today', 'week', 'month', 'custom']).cast<String>();
}

class ProductListProps extends TypedProps<ProductListProps> {
  const ProductListProps(super.raw);

  String? get title => getString('title');
}

class ChartWidgetProps extends TypedProps<ChartWidgetProps> {
  const ChartWidgetProps(super.raw);

  String? get title => getString('title');
  String? get type => getString('type');
}

class InfoCardProps extends TypedProps<InfoCardProps> {
  const InfoCardProps(super.raw);

  String? get title => getString('title');
  List<dynamic> get items => getList('items') ?? [];
}

class CredentialsCardProps extends TypedProps<CredentialsCardProps> {
  const CredentialsCardProps(super.raw);

  String? get username => getString('username');
  String? get password => getString('password');
  bool get showShare => getBool('show_share') ?? true;
}

class RankingListProps extends TypedProps<RankingListProps> {
  const RankingListProps(super.raw);

  String? get title => getString('title');
  List<dynamic> get items => getList('items') ?? [];
  bool get showRank => getBool('show_rank') ?? true;
}

class TransactionListProps extends TypedProps<TransactionListProps> {
  const TransactionListProps(super.raw);

  String? get title => getString('title');
  bool get showStatus => getBool('show_status') ?? true;
}

class PaymentConfirmProps extends TypedProps<PaymentConfirmProps> {
  const PaymentConfirmProps(super.raw);

  double? get total => getDouble('total');
  String? get method => getString('method');
}

class BottomSheetProps extends TypedProps<BottomSheetProps> {
  const BottomSheetProps(super.raw);

  double? get heightRatio => getDouble('height_ratio');
  bool get draggable => getBool('draggable') ?? true;
}

class ProgressBarProps extends TypedProps<ProgressBarProps> {
  const ProgressBarProps(super.raw);

  double? get value => getDouble('value');
  double? get max => getDouble('max') ?? 100.0;
  bool get showLabel => getBool('show_label') ?? true;
}