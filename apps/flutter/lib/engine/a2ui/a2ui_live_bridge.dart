import 'dart:async';
import 'dart:developer' as developer;

import '../../core/live/scalario_live_client.dart';

class A2UILiveBridge {
  A2UILiveBridge({
    required this.liveClient,
  }) {
    _setup();
  }

  final ScalarioLiveClient liveClient;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  StreamSubscription<Map<String, dynamic>>? _subscription;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  void _setup() {
    liveClient.on('a2ui_message', _handleMessage);
  }

  void _handleMessage(LiveEvent event) {
    final data = event.data;
    developer.log(
      'A2UI message received: ${data['type']}',
      name: 'A2UI',
    );
    _messageController.add(data);
  }

  void dispose() {
    _subscription?.cancel();
    _messageController.close();
  }
}
