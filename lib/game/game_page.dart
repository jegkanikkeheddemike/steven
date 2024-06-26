import 'package:flutter/material.dart';
import 'package:steven/socket.dart';

class GamePage extends StatefulWidget {
  const GamePage(this.conn, this.lobby, {super.key});

  final Conn conn;
  final Lobby lobby;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Text("TODO!"),
    );
  }
}
