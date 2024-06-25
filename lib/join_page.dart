import 'package:flutter/material.dart';
import 'package:steven/socket.dart';

class JoinPage extends StatelessWidget {
  JoinPage(this.conn, {super.key});

  final TextEditingController lobbyInController = TextEditingController();
  final Conn conn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Lobby pin:"),
              TextField(
                controller: lobbyInController,
                keyboardType: TextInputType.number,
              )
            ],
          ),
        ),
      ),
    );
  }
}
