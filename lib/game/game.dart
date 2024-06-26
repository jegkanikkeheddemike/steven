import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:steven/device.dart';
import 'package:steven/game/steven_rules_widget.dart';
import 'package:steven/game/user.dart';
import 'package:steven/socket.dart';

class Game extends ChangeNotifier {
  Game(this.conn, this.lobby) {
    if (lobby.started) {
      // Bare et sanity check at den ikke er gået helt galt
      throw "Lobby er allerede started wtf.";
    }
    lobby.started = true;

    if (lobby.users.isEmpty) {
      throw "Cannot start empty game?? Handle this somewhere else";
    }
    currentTurn = lobby.users.first;

    lobby.addListener(notifyListeners);

    conn.handlers["SetTurn"] = (data) {
      var lobbyID = data["lobby_id"];
      if (lobbyID != lobby.pin) {
        return false;
      }

      var [username, clientID] = data["user"];
      currentTurn = lobby.users.firstWhere(
          (user) => user.name == username && user.device == clientID);

      currentCard = null;

      notifyListeners();
      return true;
    };

    conn.handlers["DrawCard"] = (data) {
      var lobbyID = data["lobby_id"];
      if (lobbyID != lobby.pin) {
        return false;
      }

      int cardIndex = data["card"];
      currentCard = deck.cardAtIndex(cardIndex);

      notifyListeners();
      return true;
    };
  }
  final Conn conn;
  final Lobby lobby;
  late User currentTurn;
  GameCard? currentCard;
  final CardDeck deck = CardDeck();

  bool isCurrentTurn() {
    return currentTurn.device == deviceID();
  }

  void passTurn() {
    conn.socket.sink.add(jsonEncode({"PassTurn": lobby.pin}));
  }
}
