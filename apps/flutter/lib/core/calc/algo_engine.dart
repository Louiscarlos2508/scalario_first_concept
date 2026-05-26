import 'primitives.dart';

class EvalStep {
  final String fn;
  final List<Object?> args;
  final Object? result;
  const EvalStep({required this.fn, required this.args, required this.result});
}

class EvalResult {
  final Object? value;
  final String type;
  final List<EvalStep>? steps;
  const EvalResult({required this.value, required this.type, this.steps});
}

const _maxDepth = 100;

class AlgoEngine {
  int _depth = 0;
  final List<EvalStep> _steps = [];

  EvalResult eval(
    dynamic formula,
    Map<String, Object?> inputs, {
    bool debug = false,
  }) {
    _depth = 0;
    _steps.clear();
    final value = _evalRecursive(formula, inputs, debug: debug);
    final type = value.runtimeType.toString();
    if (debug) {
      return EvalResult(value: value, type: type, steps: List.of(_steps));
    }
    return EvalResult(value: value, type: type);
  }

  dynamic _evalRecursive(
    dynamic formula,
    Map<String, Object?> inputs, {
    bool debug = false,
  }) {
    _depth++;
    if (_depth > _maxDepth) {
      throw Exception('Max evaluation depth $_maxDepth exceeded');
    }

    if (formula is String && formula.startsWith('\$')) {
      final varName = formula.substring(1);
      final val = inputs[varName];
      if (val == null && !inputs.containsKey(varName)) {
        throw Exception('Variable not found: \$$varName');
      }
      return val;
    }

    if (formula is! Map<String, dynamic> || !formula.containsKey('fn')) {
      return formula;
    }

    final fnName = formula['fn'] as String;
    final primitive = primitives[fnName];
    if (primitive == null) {
      throw Exception('Unknown function: $fnName');
    }

    final rawArgs = (formula['args'] as List?) ?? <dynamic>[];
    final args = rawArgs.map((arg) => _evalRecursive(arg, inputs, debug: debug)).toList();

    try {
      final result = primitive.fn(args);
      if (debug) {
        _steps.add(EvalStep(fn: fnName, args: args, result: result));
      }
      return result;
    } catch (e) {
      throw Exception('${e.toString().replaceFirst('Exception: ', '')} at step ${_steps.length} of $fnName');
    }
  }

  bool validate(Map<String, dynamic> formula) {
    try {
      final result = eval(formula, {});
      return result.value != null || result.type == 'Null';
    } catch (_) {
      return false;
    }
  }
}
