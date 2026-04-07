import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:mobile/features/home/data/model/task_status_model.dart';

class WebSocketService {
  final String baseUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  StreamController<TaskStatus>? _controller;

  Timer? _pingTimer;
  Timer? _reconnectTimer;

  bool _isConnected = false;
  bool _isManuallyClosed = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  WebSocketService({required this.baseUrl});
  Stream<TaskStatus> connect(String taskId) {
    _disconnectInternal();

    _reconnectAttempts = 0;
    final wsUrl = Uri.parse('$baseUrl/v1/predict/ws/$taskId');
    print('🔌 Connecting to WebSocket: $wsUrl');

    _controller = StreamController<TaskStatus>.broadcast();

    // Set a timeout for connection
    Timer? connectionTimeout;
    connectionTimeout = Timer(const Duration(seconds: 3), () {
      if (!_isConnected && !_isManuallyClosed) {
        print('⚠️ WebSocket connection timeout, but continuing...');
        // Don't fail, just continue - messages might still come through
        connectionTimeout?.cancel();
      }
    });

    try {
      _channel = IOWebSocketChannel.connect(wsUrl);
      _isManuallyClosed = false;

      _subscription = _channel!.stream.listen(
        (data) {
          connectionTimeout?.cancel();
          _reconnectAttempts = 0;
          _isConnected = true;
          print('📨 WebSocket message received: $data');

          try {
            final jsonData = jsonDecode(data.toString());
            final taskStatus = TaskStatus(
              taskId: jsonData['task_id'] ?? taskId,
              status: jsonData['status'] ?? 'processing',
              progress: jsonData['progress'] ?? 0,
              message: jsonData['message'] ?? 'Processing...',
              timestamp: DateTime.now(),
              result: jsonData['result'],
            );

            print(
              '✅ Parsed TaskStatus: status=${taskStatus.status}, progress=${taskStatus.progress}',
            );
            _controller?.add(taskStatus);

            // If completed, close connection after a short delay
            if (taskStatus.progress >= 100 ||
                taskStatus.status.toLowerCase() == 'completed') {
              Future.delayed(const Duration(seconds: 2), () {
                if (!_isManuallyClosed) {
                  disconnect();
                }
              });
            }
          } catch (e) {
            print('❌ Error parsing message: $e');
          }
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _isConnected = false;
          connectionTimeout?.cancel();
          if (!_isManuallyClosed) {
            _scheduleReconnect(taskId);
          }
        },
        onDone: () {
          print('⚠️ WebSocket closed');
          _isConnected = false;
          connectionTimeout?.cancel();
          if (!_isManuallyClosed) {
            _scheduleReconnect(taskId);
          }
        },
      );

      _startPing();
    } catch (e) {
      print('❌ Connection failed: $e');
      connectionTimeout.cancel();
      _controller?.addError(e);
      _scheduleReconnect(taskId);
    }

    return _controller!.stream;
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({"type": "ping"}));
          print('💓 Ping sent');
        } catch (e) {
          print('❌ Failed to send ping: $e');
          _isConnected = false;
        }
      }
    });
  }

  void _scheduleReconnect(String taskId) {
    if (_isManuallyClosed) return;

    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('❌ Max reconnect attempts reached. Giving up.');
      _controller?.addError(
        'Connection failed after $maxReconnectAttempts attempts',
      );
      _controller?.close();
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    print(
      '🔄 Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$maxReconnectAttempts)...',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isManuallyClosed) {
        connect(taskId);
      }
    });
  }

  void disconnect() {
    _isManuallyClosed = true;
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
