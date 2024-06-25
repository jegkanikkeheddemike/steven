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
        print(msg);
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
      _listenForUserChange(newLobby);
      onLobbyResponse.complete(lobby);
      return false;
    };

    socket.sink.add(jsonEncode("CreateLobby"));

    return await onLobbyResponse.future;
  }

  Future<Lobby?> joinLobby(int pin) async {
    Completer<Lobby?> onLobbyJoin = Completer();
    handlers["JoinLobby"] = (data) {
      if (data["success"]) {
        Lobby lobby = Lobby(pin);
        for (var username in data["usernames"]) {
          lobby.users.add(User(username));
        }

        _listenForUserChange(lobby);

        onLobbyJoin.complete(lobby);
      } else {
        onLobbyJoin.complete(null);
      }
      return false;
    };

    socket.sink.add(jsonEncode({"JoinLobby": pin}));

    return await onLobbyJoin.future;
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

  void _listenForUserChange(Lobby lobby) {
    handlers["UserAdd"] = (data) {
      if (data["lobby_id"] == lobby.lobbyNr) {
        lobby._addUser(User(data["username"]));
        return true;
      }
      return false;
    };
    handlers["UserRemove"] = (data) {
      if (data["lobby_id"] == lobby.lobbyNr) {
        lobby._removeUser(data["username"]);
        return true;
      }
      return false;
    };
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

  void _removeUser(String username) {
    users.retainWhere((user) => user.name != username);
    notifyListeners();
  }
}

enum ConnState {
  connected,
  connecting,
  failed,
}
