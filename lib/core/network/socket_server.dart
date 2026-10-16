import 'dart:async';
import 'dart:io';

import '../../models/game_event.dart';

class SocketServer {
  static final SocketServer instance = SocketServer._init();
  SocketServer._init();

  HttpServer? _server;
  RawDatagramSocket? _udpSocket;
  final List<WebSocket> _clients = [];
  Timer? _beaconTimer;

  Function(GameEvent event, WebSocket sender)? onEventReceived;
  Function(WebSocket client)? onClientConnected;
  Function(WebSocket client)? onClientDisconnected;

  int get connectedCount => _clients.length;

  Future<void> startServer({required String roomCode, int port = 8080}) async {
    await stopServer();

    // 1. WebSocket Sunucusunu Başlat
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen((HttpRequest request) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        WebSocketTransformer.upgrade(request).then((WebSocket ws) {
          _clients.add(ws);
          onClientConnected?.call(ws);

          ws.listen(
            (data) {
              final event = GameEvent.fromJson(data.toString());
              onEventReceived?.call(event, ws);
            },
            onDone: () {
              _clients.remove(ws);
              onClientDisconnected?.call(ws);
            },
            onError: (_) {
              _clients.remove(ws);
              onClientDisconnected?.call(ws);
            },
          );
        });
      }
    });

    // 2. UDP Beacon (Otomatik Keşif Yayını) Başlat
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _udpSocket!.broadcastEnabled = true;

    _beaconTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Yerel ağa "FUTBOL321_ROOM:5821:8080" mesajı fırlatır
      final message = 'FUTBOL321_ROOM:$roomCode:$port';
      _udpSocket?.send(
        message.codeUnits,
        InternetAddress('255.255.255.255'),
        8888,
      );
    });
  }

  // Tüm bağlı oyunculara anlık durum gönderir
  void broadcast(GameEvent event) {
    final payload = event.toJson();
    for (var client in _clients) {
      if (client.readyState == WebSocket.open) {
        client.add(payload);
      }
    }
  }

  Future<void> stopServer() async {
    _beaconTimer?.cancel();
    _udpSocket?.close();
    for (var client in _clients) {
      await client.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }
}
