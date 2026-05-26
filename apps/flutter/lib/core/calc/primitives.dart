import 'dart:math';

typedef PrimitiveFn = Object? Function(List<Object?> args);

class AlgoPrimitive {
  final String name;
  final PrimitiveFn fn;

  const AlgoPrimitive({required this.name, required this.fn});
}

final Map<String, AlgoPrimitive> primitives = {
  // --- Math (10) ---
  'add': AlgoPrimitive(
    name: 'add', fn: (args) => (args[0] as num) + (args[1] as num),
  ),
  'sub': AlgoPrimitive(
    name: 'sub', fn: (args) => (args[0] as num) - (args[1] as num),
  ),
  'mul': AlgoPrimitive(
    name: 'mul', fn: (args) => (args[0] as num) * (args[1] as num),
  ),
  'div': AlgoPrimitive(
    name: 'div', fn: (args) {
      final b = args[1] as num;
      if (b == 0) throw ArgumentError('div/0');
      return (args[0] as num) / b;
    },
  ),
  'round': AlgoPrimitive(
    name: 'round', fn: (args) {
      final d = (args.length > 1 ? args[1] as int : 0);
      return double.parse(((args[0] as num).toDouble()).toStringAsFixed(d));
    },
  ),
  'floor': AlgoPrimitive(
    name: 'floor', fn: (args) => (args[0] as num).floor(),
  ),
  'ceil': AlgoPrimitive(
    name: 'ceil', fn: (args) => (args[0] as num).ceil(),
  ),
  'abs': AlgoPrimitive(
    name: 'abs', fn: (args) => (args[0] as num).abs(),
  ),
  'min': AlgoPrimitive(
    name: 'min', fn: (args) => min(args[0] as num, args[1] as num),
  ),
  'max': AlgoPrimitive(
    name: 'max', fn: (args) => max(args[0] as num, args[1] as num),
  ),

  // --- Logic (10) ---
  'if': AlgoPrimitive(
    name: 'if', fn: (args) => (args[0] as bool) ? args[1] : args[2],
  ),
  'gt': AlgoPrimitive(
    name: 'gt', fn: (args) => (args[0] as num) > (args[1] as num),
  ),
  'lt': AlgoPrimitive(
    name: 'lt', fn: (args) => (args[0] as num) < (args[1] as num),
  ),
  'eq': AlgoPrimitive(
    name: 'eq', fn: (args) => args[0] == args[1],
  ),
  'ne': AlgoPrimitive(
    name: 'ne', fn: (args) => args[0] != args[1],
  ),
  'gte': AlgoPrimitive(
    name: 'gte', fn: (args) => (args[0] as num) >= (args[1] as num),
  ),
  'lte': AlgoPrimitive(
    name: 'lte', fn: (args) => (args[0] as num) <= (args[1] as num),
  ),
  'and': AlgoPrimitive(
    name: 'and', fn: (args) => (args[0] as bool) && (args[1] as bool),
  ),
  'or': AlgoPrimitive(
    name: 'or', fn: (args) => (args[0] as bool) || (args[1] as bool),
  ),
  'not': AlgoPrimitive(
    name: 'not', fn: (args) => !(args[0] as bool),
  ),

  // --- Lists (6) ---
  'sum': AlgoPrimitive(
    name: 'sum', fn: (args) {
      final arr = args[0] as List<num>;
      return arr.fold<num>(0, (a, b) => a + b);
    },
  ),
  'avg': AlgoPrimitive(
    name: 'avg', fn: (args) {
      final arr = args[0] as List<num>;
      if (arr.isEmpty) return null;
      return arr.fold<num>(0, (a, b) => a + b) / arr.length;
    },
  ),
  'count': AlgoPrimitive(
    name: 'count', fn: (args) => (args[0] as List).length,
  ),
  'filter': AlgoPrimitive(
    name: 'filter', fn: (args) {
      final arr = args[0] as List<Map<String, dynamic>>;
      final field = args[1] as String;
      final value = args[2];
      return arr.where((item) => item[field] == value).toList();
    },
  ),
  'map_field': AlgoPrimitive(
    name: 'map_field', fn: (args) {
      final arr = args[0] as List<Map<String, dynamic>>;
      final field = args[1] as String;
      return arr.map((item) => item[field]).toList();
    },
  ),
  'unique': AlgoPrimitive(
    name: 'unique', fn: (args) => (args[0] as List).toSet().toList(),
  ),

  // --- Dates (4) ---
  'today': AlgoPrimitive(
    name: 'today', fn: (_) {
      final d = DateTime.now();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    },
  ),
  'diff_jours': AlgoPrimitive(
    name: 'diff_jours', fn: (args) {
      final d1 = DateTime.parse(args[0] as String);
      final d2 = DateTime.parse(args[1] as String);
      return d1.difference(d2).inDays;
    },
  ),
  'add_days': AlgoPrimitive(
    name: 'add_days', fn: (args) {
      final d = DateTime.parse(args[0] as String);
      final days = args[1] as int;
      final r = d.add(Duration(days: days));
      return '${r.year}-${r.month.toString().padLeft(2, '0')}-${r.day.toString().padLeft(2, '0')}';
    },
  ),
  'format_date': AlgoPrimitive(
    name: 'format_date', fn: (args) {
      final d = DateTime.parse(args[0] as String);
      final fmt = args[1] as String;
      if (fmt == 'DD/MM/YYYY') {
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    },
  ),

  // --- Text (5) ---
  'concat': AlgoPrimitive(
    name: 'concat', fn: (args) => args.map((a) => '$a').join(),
  ),
  'upper': AlgoPrimitive(
    name: 'upper', fn: (args) => (args[0] as String).toUpperCase(),
  ),
  'lower': AlgoPrimitive(
    name: 'lower', fn: (args) => (args[0] as String).toLowerCase(),
  ),
  'format_currency': AlgoPrimitive(
    name: 'format_currency', fn: (args) {
      final amount = args[0] as num;
      final currency = args[1] as String;
      const symbols = {
        'XOF': 'FCFA', 'XAF': 'FCFA', 'EUR': '€', 'USD': '\$',
        'GBP': '£', 'NGN': '₦', 'GHS': '₵',
      };
      final sym = symbols[currency] ?? currency;
      return '$amount $sym';
    },
  ),
  'slugify': AlgoPrimitive(
    name: 'slugify', fn: (args) {
      return (args[0] as String)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
    },
  ),
};
