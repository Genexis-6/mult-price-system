import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:mobile/core/utils/logger_utlis.dart';

enum PriceTrackingWebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class PriceTrackingWebSocketService {
  final String email;
  final String baseUrl;
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  
  PriceTrackingWebSocketConnectionState _connectionState = PriceTrackingWebSocketConnectionState.disconnected;
  PriceTrackingWebSocketConnectionState get connectionState => _connectionState;
  
  final _stateController = StreamController<PriceTrackingWebSocketConnectionState>.broadcast();
  Stream<PriceTrackingWebSocketConnectionState> get onStateChange => _stateController.stream;
  
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 30);
  
  PriceTrackingWebSocketService({
    required this.email,
    required this.baseUrl,
  });
  
  void connect() {
    if (_isDisposed) return;
    
    if (_connectionState == PriceTrackingWebSocketConnectionState.connected ||
        _connectionState == PriceTrackingWebSocketConnectionState.connecting) {
      logger.d('PriceTrackingWebSocket already connected or connecting');
      return;
    }
    
    _setState(PriceTrackingWebSocketConnectionState.connecting);
    
    try {
      final wsUrl = baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      
      final uri = Uri.parse('$wsUrl/v1/price-tracking/ws/$email');
      logger.d('PriceTrackingWebSocket connecting to: $uri');
      
      _channel = WebSocketChannel.connect(uri);
      
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );
      
      _setState(PriceTrackingWebSocketConnectionState.connected);
      _reconnectAttempts = 0;
      
      _startPingTimer();
      
    } catch (e) {
      logger.e('PriceTrackingWebSocket failed to connect: $e');
      _setState(PriceTrackingWebSocketConnectionState.error);
      _scheduleReconnect();
    }
  }
  
  void _handleMessage(dynamic message) {
    if (_isDisposed) return;
    
    try {
      // Handle plain text messages (like "pong")
      if (message is String) {
        if (message == 'pong') {
          logger.d('PriceTrackingWebSocket pong received');
          return;
        }
        // Try to parse as JSON if it starts with '{'
        if (message.trim().startsWith('{')) {
          final data = jsonDecode(message) as Map<String, dynamic>;
          logger.d('PriceTrackingWebSocket message received: ${data['type']}');
          if (!_isDisposed) {
            _messageController.add(data);
          }
          return;
        }
        // Ignore other plain text messages
        logger.d('PriceTrackingWebSocket plain text received: $message');
        return;
      }
      
      // Handle binary data
      logger.d('PriceTrackingWebSocket binary data received');
    } catch (e) {
      logger.e('PriceTrackingWebSocket failed to parse message: $e');
    }
  }
  
  void _handleError(Object error) {
    if (_isDisposed) return;
    logger.e('PriceTrackingWebSocket error: $error');
    _setState(PriceTrackingWebSocketConnectionState.error);
    _scheduleReconnect();
  }
  
  void _handleDone() {
    if (_isDisposed) return;
    logger.d('PriceTrackingWebSocket connection closed');
    
    if (_connectionState == PriceTrackingWebSocketConnectionState.connected) {
      _setState(PriceTrackingWebSocketConnectionState.disconnected);
      _scheduleReconnect();
    }
  }
  
  void _scheduleReconnect() {
    if (_isDisposed) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      logger.w('PriceTrackingWebSocket max reconnect attempts reached, giving up');
      return;
    }
    
    _reconnectAttempts++;
    logger.d('PriceTrackingWebSocket scheduling reconnect attempt $_reconnectAttempts in $_reconnectDelay');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isDisposed) {
        connect();
      }
    });
  }
  
  void _startPingTimer() {
    if (_isDisposed) return;
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      sendPing();
    });
  }
  
  void sendPing() {
    if (_isDisposed) return;
    try {
      _channel?.sink.add('ping');
      logger.d('PriceTrackingWebSocket ping sent');
    } catch (e) {
      logger.e('PriceTrackingWebSocket failed to send ping: $e');
    }
  }
  
  void sendRefresh() {
    if (_isDisposed) return;
    try {
      _channel?.sink.add('refresh');
      logger.d('PriceTrackingWebSocket refresh command sent');
    } catch (e) {
      logger.e('PriceTrackingWebSocket failed to send refresh: $e');
    }
  }
  
  void _setState(PriceTrackingWebSocketConnectionState state) {
    if (_isDisposed) return;
    _connectionState = state;
    if (!_isDisposed) {
      _stateController.add(state);
    }
  }
  
  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    
    try {
      _channel?.sink.close(status.normalClosure);
    } catch (e) {
      logger.e('PriceTrackingWebSocket error closing: $e');
    }
    
    _channel = null;
    _subscription = null;
    if (!_isDisposed) {
      _setState(PriceTrackingWebSocketConnectionState.disconnected);
    }
    
    logger.d('PriceTrackingWebSocket disconnected');
  }
  
  void dispose() {
    _isDisposed = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    
    try {
      _channel?.sink.close(status.normalClosure);
    } catch (e) {
      // Ignore
    }
    
    _channel = null;
    _subscription = null;
    
    if (!_stateController.isClosed) {
      _stateController.close();
    }
    if (!_messageController.isClosed) {
      _messageController.close();
    }
    
    logger.d('PriceTrackingWebSocket disposed');
  }
}