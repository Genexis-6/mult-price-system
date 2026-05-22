// websocket_service.dart (prediction)
import 'dart:async';
import 'dart:convert';
import 'package:mobile/core/utils/app_ws_url_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:mobile/features/home/data/model/task_status_model.dart';
import 'package:mobile/core/utils/logger_utlis.dart';

class WebSocketService {
  final String baseUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  StreamController<TaskStatus>? _controller;

  Timer? _pingTimer;
  Timer? _reconnectTimer;

  bool _isConnected = false;
  bool _isManuallyClosed = false;
  bool _preventReconnect = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;

  WebSocketService({required this.baseUrl});

  Stream<TaskStatus> connect(String taskId) {
    _disconnectInternal();

    _reconnectAttempts = 0;
    _preventReconnect = false;
    final wsUrl = Uri.parse('${AppWsUrlConfig.wsUrl}/v1/predict/ws/$taskId'); // Changed path
    logger.d('🔌 Connecting to Prediction WebSocket: $wsUrl');
    logger.d('📡 Task ID for WebSocket: $taskId');

    _controller = StreamController<TaskStatus>.broadcast();

    try {
      _channel = IOWebSocketChannel.connect(wsUrl);
      _isManuallyClosed = false;

      _subscription = _channel!.stream.listen(
        (data) {
          _reconnectAttempts = 0;
          _isConnected = true;
          logger.d('✅ Prediction WebSocket connected and receiving data');
          logger.d('📨 WebSocket message received: $data');

          try {
            final Map<String, dynamic> jsonData;
            if (data is String) {
              // Skip plain text messages like 'pong'
              if (data == 'pong') {
                logger.d('💓 Prediction WebSocket pong received');
                return;
              }
              jsonData = jsonDecode(data);
            } else if (data is Map) {
              jsonData = Map<String, dynamic>.from(data);
            } else {
              logger.e('❌ Unknown data type: ${data.runtimeType}');
              return;
            }

            final taskStatus = TaskStatus(
              taskId: jsonData['task_id'] ?? taskId,
              status: jsonData['status'] ?? 'processing',
              progress: jsonData['progress'] ?? 0,
              message: jsonData['message'] ?? 'Processing...',
              timestamp: DateTime.now(),
              result: jsonData['result'],
            );

            logger.d('✅ Parsed TaskStatus: status=${taskStatus.status}, progress=${taskStatus.progress}, message=${taskStatus.message}');
            _controller?.add(taskStatus);
          } catch (e) {
            logger.e('❌ Error parsing message: $e');
          }
        },
        onError: (error) {
          logger.e('❌ Prediction WebSocket error: $error');
          _isConnected = false;
          if (!_isManuallyClosed && !_preventReconnect) {
            _scheduleReconnect(taskId);
          }
        },
        onDone: () {
          logger.d('⚠️ Prediction WebSocket closed');
          _isConnected = false;
          if (!_isManuallyClosed && !_preventReconnect) {
            _scheduleReconnect(taskId);
          }
        },
      );

      _startPing();
    } catch (e) {
      logger.e('❌ Connection failed: $e');
      if (!_isManuallyClosed && !_preventReconnect) {
        _scheduleReconnect(taskId);
      }
    }

    return _controller!.stream;
  }

  void preventReconnect() {
    _preventReconnect = true;
    _isManuallyClosed = true;
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add('ping');
          logger.d('💓 Prediction WebSocket ping sent');
        } catch (e) {
          logger.e('❌ Failed to send ping: $e');
          _isConnected = false;
        }
      }
    });
  }

  void _scheduleReconnect(String taskId) {
    if (_isManuallyClosed || _preventReconnect) return;

    if (_reconnectAttempts >= maxReconnectAttempts) {
      logger.w('❌ Max reconnect attempts reached. Giving up.');
      _controller?.close();
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    logger.d('🔄 Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$maxReconnectAttempts)...');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isManuallyClosed && !_preventReconnect) {
        connect(taskId);
      }
    });
  }

  void disconnect() {
    _isManuallyClosed = true;
    _preventReconnect = true;
    _reconnectTimer?.cancel();
    _disconnectInternal();
    _controller?.close();
  }

  void _disconnectInternal() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    if (_channel != null) {
      try {
        _channel!.sink.close();
      } catch (e) {
        // Ignore close errors
      }
    }
    _subscription = null;
    _channel = null;
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}