import 'package:flutter/material.dart';
import 'package:steven/game/game.dart';
import 'package:steven/game/steven_rules_widget.dart';
import 'package:steven/socket.dart';

class GamePage extends StatefulWidget {
  const GamePage(this.conn, this.game, {super.key});

  final Conn conn;
  final Game game;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(30),
            child: SizedBox(
              height: 100,
              child: Center(
                child: ListenableBuilder(
                  listenable: widget.game,
                  builder: (context, _) => Wrap(
                    spacing: 10,
                    direction: Axis.horizontal,
                    children: widget.game.lobby.users
                        .map((user) => Text(
                              user.toString(),
                              style: TextStyle(
                                fontWeight: user == widget.game.currentTurn
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          StevenRule(widget.game),
          ListenableBuilder(
            listenable: widget.game,
            builder: (context, _) => ElevatedButton(
              onPressed: widget.game.isCurrentTurn()
                  ? () {
                      widget.game.passTurn();
                    }
                  : null,
              child: const Text("Pass"),
            ),
          )
        ],
      ),
    );
  }
}
