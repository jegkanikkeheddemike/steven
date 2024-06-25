import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:steven/device.dart';
import 'package:steven/game/user.dart';
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

      socket.stream.listen((rawMsg) {
        var msg = jsonDecode(rawMsg);
        for (var key in handlers.keys) {
          switch (msg[key]) {
            case null:
              continue;
            case var data:
              if (!handlers[key]!(data)) {
                handlers.remove(key);
              }
              return;
          }
        }

        print("-- DROPPED RESPONSE --");
        print(msg);
      });
    });
  }
  // Map of handlers. Return true to retain
  Map<String, bool Function(dynamic)> handlers = {};

  Future<Lobby> createLobby() async {
    Completer<Lobby> onLobbyResponse = Completer<Lobby>();
    handlers["LobbyCreated"] = (data) {
      var newLobby = Lobby(data);
      lobby = newLobby;
      handlers["UserAdd"] = (data) {
        if (data["lobby_id"] == newLobby.lobbyNr) {
          newLobby._addUser(data["username"]);
          return true;
        }
        return false;
      };

      onLobbyResponse.complete(lobby);
      return false;
    };

    socket.sink.add(jsonEncode("CreateLobby"));

    return await onLobbyResponse.future;
  }

  Future<void> addUser(String name, Lobby lobby) async {
    Completer<void> onUserAdded = Completer();
    handlers["UserAdded"] = (data) {
      if (data == name) {
        onUserAdded.complete();
        return false;
      }
      return true;
    };
    socket.sink.add(jsonEncode({
      "UserAdd": [lobby.lobbyNr, name]
    }));

    await onUserAdded.future;
  }

  Future<bool> joinLobby(int pin) async {
    Completer<bool> onLobbyJoin = Completer();
    handlers["lobbyJoin"] = (data) {
      return false;
    };

    throw UnimplementedError();
  }

  bool _userAdd(dynamic dynData) {
    Map<String, dynamic> data = dynData as Map<String, dynamic>;

    switch (lobby) {
      case null:
        print("Received UserAdd without lobby");
      case var lobby:
        if (lobby.lobbyNr != data["lobby"]) {
          print("Reveived UserAdd of invalid lobby: ${data["lobby"]}");
          return true;
        }
        var newuser =
            User(data["name"], onlineData: OnlineData(data["device"]));
        lobby._addUser(newuser);
    }

    return true;
  }
}

class Lobby extends ChangeNotifier {
  Lobby(this.lobbyNr);
  final int lobbyNr;

  List<User> users = [];

  void _addUser(User user) {
    users.add(user);
    notifyListeners();
  }
}

enum ConnState {
  connected,
  connecting,
  failed,
}
