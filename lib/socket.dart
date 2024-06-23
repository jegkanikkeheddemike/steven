import 'package:flutter/foundation.dart';
import 'package:steven/device.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Conn extends ChangeNotifier {
  final String addr;
  late WebSocketChannel socket;

  ConnState state = ConnState.connecting;

  Lobby? lobby;

  Conn(this.addr) {
    socket = WebSocketChannel.connect(Uri.parse("ws://$addr:6996"));
    socket.ready.then((_) {
      state = ConnState.connected;
      socket.sink.add(deviceID());
    });
  }
}

class Lobby extends ChangeNotifier {}

enum ConnState {
  connected,
  connecting,
  failed,
}
