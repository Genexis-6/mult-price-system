import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/share/application/provider/app_state_provider.dart';
import 'package:mobile/features/track/data/webcoket/price_tracking_websocket_service.dart';
// import 'package:mobile/features/track/data/websocket/price_tracking_websocket_service.dart';

final priceTrackingWebSocketProvider = StateNotifierProvider.family<PriceTrackingWebSocketNotifier, PriceTrackingWebSocketState, String>(
  (ref, email) => PriceTrackingWebSocketNotifier(
    email: email,
    ref: ref,
  ),
);

class PriceTrackingWebSocketState {
  final PriceTrackingWebSocketConnectionState connectionState;
  final Map<String, dynamic>? lastMessage;
  final List<Map<String, dynamic>> initialAlerts;
  
  const PriceTrackingWebSocketState({
    this.connectionState = PriceTrackingWebSocketConnectionState.disconnected,
    this.lastMessage,
    this.initialAlerts = const [],
  });
  
  PriceTrackingWebSocketState copyWith({
    PriceTrackingWebSocketConnectionState? connectionState,
    Map<String, dynamic>? lastMessage,
    List<Map<String, dynamic>>? initialAlerts,
  }) {
    return PriceTrackingWebSocketState(
      connectionState: connectionState ?? this.connectionState,
      lastMessage: lastMessage ?? this.lastMessage,
      initialAlerts: initialAlerts ?? this.initialAlerts,
    );
  }
}

class PriceTrackingWebSocketNotifier extends StateNotifier<PriceTrackingWebSocketState> {
  final String email;
  final Ref ref;
  PriceTrackingWebSocketService? _webSocket;
  bool _isDisposed = false;
  
  PriceTrackingWebSocketNotifier({
    required this.email,
    required this.ref,
  }) : super(const PriceTrackingWebSocketState()) {
    _initialize();
  }
  
  void _initialize() {
    if (_isDisposed) return;
    
    // final appState = ref.read(appStateProvider);
    final baseUrl =  'http://10.0.2.2:8000';
    
    _webSocket = PriceTrackingWebSocketService(
      email: email,
      baseUrl: baseUrl,
    );
    
    _webSocket!.onStateChange.listen((state) {
      if (!_isDisposed && mounted) {
        this.state = this.state.copyWith(connectionState: state);
      }
    });
    
    _webSocket!.onMessage.listen((message) {
      if (!_isDisposed && mounted) {
        _handleMessage(message);
      }
    });
    
    _webSocket!.connect();
  }
  
  void _handleMessage(Map<String, dynamic> message) {
    if (_isDisposed || !mounted) return;
    
    final type = message['type'] as String?;
    
    state = state.copyWith(lastMessage: message);
    
    switch (type) {
      case 'initial_status':
        final alerts = message['alerts'] as List<dynamic>? ?? [];
        state = state.copyWith(
          initialAlerts: alerts.cast<Map<String, dynamic>>(),
        );
        break;
        
      case 'alert_update':
        _handleAlertUpdate(message);
        break;
        
      case 'refresh':
        final alerts = message['alerts'] as List<dynamic>? ?? [];
        state = state.copyWith(
          initialAlerts: alerts.cast<Map<String, dynamic>>(),
        );
        break;
    }
  }
  
  void _handleAlertUpdate(Map<String, dynamic> update) {
    if (_isDisposed || !mounted) return;
    
    final alertId = update['alert_id'] as int?;
    if (alertId == null) return;
    
    final updatedAlerts = state.initialAlerts.map((alert) {
      if (alert['id'] == alertId) {
        return {
          ...alert,
          'current_best_price': update['current_best_price'] ?? alert['current_best_price'],
          'current_best_platform': update['current_best_platform'] ?? alert['current_best_platform'],
          'status': update['target_reached'] == true ? 'triggered' : alert['status'],
        };
      }
      return alert;
    }).toList();
    
    state = state.copyWith(initialAlerts: updatedAlerts);
  }
  
  void sendRefresh() {
    _webSocket?.sendRefresh();
  }
  
  void reconnect() {
    _webSocket?.disconnect();
    _webSocket?.connect();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _webSocket?.dispose();
    super.dispose();
  }
}