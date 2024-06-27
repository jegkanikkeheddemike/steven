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
  Duration backoff = const Duration(milliseconds: 500);
  bool hasTimer = false;
  Conn(this.addr) {
    connect(false);
  }

  void connect(bool manual) {
    socket = WebSocketChannel.connect(Uri.parse("ws://$addr:6996"));
    socket.ready.then((_) {
      log("Connected!");
      state = ConnState.connected;
      socket.sink.add(deviceID());

      //Reset backoff on success
      backoff = const Duration(milliseconds: 500);
      notifyListeners();
    });

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

      log("DROPPED RESPONSE: $msg");
    }, onError: (e) {
      state = ConnState.failed;

      if (manual) {
        log("Connection failed");
      } else {
        backoff = backoff * 2;
        log("Connection failed. Reattempting in  ${backoff.inSeconds} seconds");
      }

      notifyListeners();
      if (!manual) {
        Timer(backoff, () {
          if (state != ConnState.connected) {
            connect(false);
          }
        });
      }
    }, onDone: () {
      notifyListeners();
      if (state == ConnState.connected) {
        //Server closed
        connect(false);
      }
    });
  }

  Function(String) log = print;

  // Map of handlers. Return true to retain
  Map<String, bool Function(dynamic)> handlers = {};

  Future<Lobby> createLobby() async {
    Completer<Lobby> onLobbyResponse = Completer<Lobby>();
    handlers["LobbyCreated"] = (data) {
      var lobby = Lobby(data);
      _listenForUserChange(lobby);
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

  void exitLobbyIfNotStarted(Lobby lobby) {
    if (!lobby.started) {
      socket.sink.add(jsonEncode({"ExitLobby": lobby.pin}));
    }
  }

  void addUser(String name, Lobby lobby) async {
    socket.sink.add(jsonEncode({
      "UserAdd": [lobby.pin, name]
    }));
  }

  void startGame(Lobby lobby) {
    socket.sink.add(jsonEncode({"StartGame": lobby.pin}));
  }

  void _listenForUserChange(Lobby lobby) {
    handlers["UserAdd"] = (data) {
      var lobbyID = data["lobby_id"];
      var username = data["username"];
      var clientID = data["client_id"];
      if (lobbyID == lobby.pin) {
        if (clientID == deviceID()) {
          lobby._addUser(User(username, onlineData: OnlineData(clientID)));
        } else {
          lobby._addUser(User(username));
        }

        return true;
      }
      return false;
    };
    handlers["UserRemove"] = (data) {
      if (data["lobby_id"] == lobby.pin) {
        lobby._removeUser(data["username"]);
        return true;
      }
      return false;
    };
  }
}

class Lobby extends ChangeNotifier {
  Lobby(this.pin);
  final int pin;
  bool started = false;

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
