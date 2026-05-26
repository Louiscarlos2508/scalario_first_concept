import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LiveEvent {
  final String type;
  final Map<String, dynamic> data;
  final String timestamp;

  const LiveEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory LiveEvent.fromJson(Map<String, dynamic> json) {
    return LiveEvent(
      type: json['type'] as String,
      data: (json['data'] as Map).cast<String, dynamic>(),
      timestamp: json['timestamp'] as String,
    );
  }
}

typedef EventHandler = void Function(LiveEvent event);

class ScalarioLiveClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _baseUrl;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _shouldReconnect = true;
  String? _jwtToken;
  final Map<String, List<EventHandler>> _handlers = {};

  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  void connect({
    required String jwtToken,
    String baseUrl = 'ws://localhost:3000',
  }) {
    _jwtToken = jwtToken;
    _baseUrl = baseUrl;
    _shouldReconnect = true;
    _doConnect();
  }

  void _doConnect() {
    try {
      final uri = Uri.parse('$_baseUrl/live?token=$_jwtToken');
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      isConnected.value = true;
      _reconnectAttempts = 0;
      debugPrint('[ScalarioLive] Connected');
    } catch (e) {
      debugPrint('[ScalarioLive] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final Map<String, dynamic> json = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = LiveEvent.fromJson(json);
      _dispatch(event);
    } catch (e) {
      debugPrint('[ScalarioLive] Parse error: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('[ScalarioLive] Error: $error');
    isConnected.value = false;
  }

  void _onDone() {
    debugPrint('[ScalarioLive] Connection closed');
    isConnected.value = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    final delay = min(30, pow(2, _reconnectAttempts).toInt());
    debugPrint('[ScalarioLive] Reconnecting in ${delay}s (attempt ${_reconnectAttempts + 1})');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _reconnectAttempts++;
      _doConnect();
    });
  }

  void _dispatch(LiveEvent event) {
    final typeHandlers = _handlers[event.type] ?? [];
    final allHandlers = _handlers['*'] ?? [];
    for (final handler in [...typeHandlers, ...allHandlers]) {
      handler(event);
    }
  }

  void on(String eventType, EventHandler handler) {
    _handlers.putIfAbsent(eventType, () => []);
    _handlers[eventType]!.add(handler);
  }

  void off(String eventType, EventHandler handler) {
    _handlers[eventType]?.remove(handler);
  }

  void sendPing() {
    _channel?.sink.add(jsonEncode({'event': 'ping'}));
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    isConnected.value = false;
  }

  void dispose() {
    disconnect();
    _handlers.clear();
  }
}
