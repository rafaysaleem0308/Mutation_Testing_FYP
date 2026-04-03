import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hello/core/services/api_service.dart';
import 'dart:async';

class ChatService {
  static IO.Socket? _socket;
  static final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  static final _notificationController = StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  static Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  static String? _currentUserId;

  static void init() async {
    final userData = await ApiService.getUserData();
    final userId = userData['_id'] ?? userData['id'];
    
    if (userId == null) return;

    if (_socket != null && _socket!.connected) {
      if (_currentUserId != userId.toString()) {
        _socket!.emit('join', userId);
        _currentUserId = userId.toString();
        print('👤 User $userId re-joined their room');
      }
      return;
    }

    _socket = IO.io(ApiService.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      print('🔌 Connected to Chat Server');
      _socket!.emit('join', userId);
      _currentUserId = userId.toString();
    });

    _socket!.on('new_message', (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('new_notification', (data) {
      _notificationController.add(Map<String, dynamic>.from(data));
    });

    _socket!.onDisconnect((_) {
      print('🔌 Disconnected from Chat Server');
      _currentUserId = null;
    });
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
