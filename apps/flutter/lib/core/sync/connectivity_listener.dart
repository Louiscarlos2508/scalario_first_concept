import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';

typedef ConnectivityCallback = void Function(ConnectivityResult status);

class ConnectivityListener {
  ConnectivityListener({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void listen(ConnectivityCallback onChanged) {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final result =
            results.isNotEmpty ? results.first : ConnectivityResult.none;
        onChanged(result);
      },
      onError: (Object error) {
        developer.log(
          'Connectivity stream error: $error — listener may be dead',
          name: 'Scalario.Offline.Sync',
          level: 900,
        );
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
