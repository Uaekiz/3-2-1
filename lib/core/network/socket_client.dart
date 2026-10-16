import 'dart:async';
import 'dart:io';

import '../../models/game_event.dart';

class SocketClient {
  static final SocketClient instance = SocketClient._init();
  SocketClient._init();

  WebSocket? _socket;
  Function(GameEvent event)? onEventReceived;
  Function()? onDisconnected;

  // 4 Haneli oda kodunu yerel ağda arayıp sunucuyu otomatik bulur
  Future<bool> discoverAndConnect({
    required String targetRoomCode,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final completer = Completer<bool>();
    RawDatagramSocket? listenerSocket;

    try {
      listenerSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        8888,
      );
      listenerSocket.broadcastEnabled = true;

      Timer(timeout, () {
        if (!completer.isCompleted) {
          listenerSocket?.close();
          completer.complete(false); // Düzeltilen kısım burası
        }
      });

      listenerSocket.listen((RawSocketEvent event) async {
        if (event == RawSocketEvent.read) {
          final datagram = listenerSocket?.receive();
          if (datagram != null) {
            final msg = String.fromCharCodes(datagram.data);
            // Format: FUTBOL321_ROOM:ROOM_CODE:PORT
            if (msg.startsWith('FUTBOL321_ROOM:')) {
              final parts = msg.split(':');
              if (parts.length >= 3 && parts[1] == targetRoomCode) {
                listenerSocket?.close();
                final hostIp = datagram.address.address;
                final port = int.tryParse(parts[2]) ?? 8080;

                final connected = await connect(hostIp, port);
                if (!completer.isCompleted) completer.complete(connected);
              }
            }
          }
        }
      });
    } catch (_) {
      listenerSocket?.close();
      return false;
    }

    return completer.future;
  }

  Future<bool> connect(String ip, int port) async {
    try {
      _socket = await WebSocket.connect('ws://$ip:$port')
          .timeout(const Duration(seconds: 4));
      _socket!.listen(
        (data) {
          final event = GameEvent.fromJson(data.toString());
          onEventReceived?.call(event);
        },
        onDone: () => onDisconnected?.call(),
        onError: (_) => onDisconnected?.call(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void send(GameEvent event) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(event.toJson());
    }
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
  }
}
