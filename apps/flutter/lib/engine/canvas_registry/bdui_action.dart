sealed class BduiAction {
  final String? trigger;
  final Map<String, dynamic>? params;

  const BduiAction({this.trigger, this.params});

  static BduiAction? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final type = json['type'] as String?;
    if (type == null) return null;

    return switch (type) {
      'navigate' => BduiNavigateAction._fromJson(json),
      'sheet' => BduiSheetAction._fromJson(json),
      'dialog' => BduiDialogAction._fromJson(json),
      'confirm' => BduiConfirmAction._fromJson(json),
      'api_call' => BduiApiCallAction._fromJson(json),
      'local' => BduiLocalAction._fromJson(json),
      'toast' => BduiToastAction._fromJson(json),
      'show_alert' => BduiShowAlertAction._fromJson(json),
      'add_to_cart' => BduiAddToCartAction._fromJson(json),
      'remove_from_cart' => BduiRemoveFromCartAction._fromJson(json),
      'update_cart_item' => BduiUpdateCartItemAction._fromJson(json),
      'toggle_credit_mode' => const BduiLocalAction(action: 'toggle_credit_mode'),
      'clear_cart' => const BduiLocalAction(action: 'clear_cart'),
      'retry' => const BduiLocalAction(action: 'retry'),
      _ => null,
    };
  }
}

class BduiNavigateAction extends BduiAction {
  final String screen;
  const BduiNavigateAction({required this.screen, super.params}) : super(trigger: 'tap');
  BduiNavigateAction._fromJson(Map<String, dynamic> j)
      : screen = j['screen'] as String? ?? '',
        super(trigger: j['trigger'] as String? ?? 'tap');
}

class BduiSheetAction extends BduiAction {
  final String screen;
  const BduiSheetAction({required this.screen, super.params}) : super(trigger: 'tap');
  BduiSheetAction._fromJson(Map<String, dynamic> j)
      : screen = j['screen'] as String? ?? '',
        super(trigger: j['trigger'] as String? ?? 'tap');
}

class BduiDialogAction extends BduiAction {
  final String dialog;
  const BduiDialogAction({required this.dialog, super.params}) : super(trigger: 'tap');
  BduiDialogAction._fromJson(Map<String, dynamic> j)
      : dialog = j['dialog'] as String? ?? '',
        super(trigger: j['trigger'] as String? ?? 'tap');
}

class BduiConfirmAction extends BduiAction {
  final String confirmKey;
  final BduiAction? then;
  const BduiConfirmAction({required this.confirmKey, this.then, super.params}) : super(trigger: 'tap');
  BduiConfirmAction._fromJson(Map<String, dynamic> j)
      : confirmKey = j['confirm_key'] as String? ?? 'confirm',
        then = BduiAction.fromJson(j['then'] as Map<String, dynamic>?);
}

class BduiApiCallAction extends BduiAction {
  final String endpoint;
  final String method;
  const BduiApiCallAction({required this.endpoint, this.method = 'GET', super.params}) : super(trigger: 'tap');
  BduiApiCallAction._fromJson(Map<String, dynamic> j)
      : endpoint = j['endpoint'] as String? ?? '',
        method = j['method'] as String? ?? 'GET';
}

class BduiLocalAction extends BduiAction {
  final String action;
  const BduiLocalAction({required this.action, super.params}) : super(trigger: 'tap');
  BduiLocalAction._fromJson(Map<String, dynamic> j)
      : action = j['action'] as String? ?? 'tap';
}

class BduiToastAction extends BduiAction {
  final String? messageKey;
  final int? durationMs;
  const BduiToastAction({this.messageKey, this.durationMs}) : super(trigger: 'tap');
  BduiToastAction._fromJson(Map<String, dynamic> j)
      : messageKey = j['message_key'] as String?,
        durationMs = j['duration_ms'] as int?;
}

class BduiShowAlertAction extends BduiAction {
  final String? messageKey;
  final String? variant;
  const BduiShowAlertAction({this.messageKey, this.variant}) : super(trigger: 'tap');
  BduiShowAlertAction._fromJson(Map<String, dynamic> j)
      : messageKey = j['message_key'] as String?,
        variant = j['variant'] as String?;
}

class BduiAddToCartAction extends BduiAction {
  final String target;
  const BduiAddToCartAction({required this.target}) : super(trigger: 'tap');
  BduiAddToCartAction._fromJson(Map<String, dynamic> j)
      : target = j['target'] as String? ?? 'cart';
}

class BduiRemoveFromCartAction extends BduiAction {
  final String target;
  const BduiRemoveFromCartAction({required this.target}) : super(trigger: 'tap');
  BduiRemoveFromCartAction._fromJson(Map<String, dynamic> j)
      : target = j['target'] as String? ?? 'cart';
}

class BduiUpdateCartItemAction extends BduiAction {
  final String target;
  const BduiUpdateCartItemAction({required this.target}) : super(trigger: 'quantity_change');
  BduiUpdateCartItemAction._fromJson(Map<String, dynamic> j)
      : target = j['target'] as String? ?? 'cart';
}