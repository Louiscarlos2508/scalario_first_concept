import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class FakeConnectivityImpl implements Connectivity {
  FakeConnectivityImpl() : super();

  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  void emit(ConnectivityResult result) {
    _controller.add([result]);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];
}

class FakeConnectivity {
  final FakeConnectivityImpl connectivity = FakeConnectivityImpl();

  void emitConnected() => connectivity.emit(ConnectivityResult.wifi);

  void emitDisconnected() => connectivity.emit(ConnectivityResult.none);

  void dispose() => connectivity.onConnectivityChanged.drain();
}
