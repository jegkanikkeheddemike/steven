import 'package:flutter/material.dart';
import 'package:steven/game/lobby_page.dart';
import 'package:steven/socket.dart';

class JoinPage extends StatefulWidget {
  const JoinPage(this.conn, {super.key});

  final Conn conn;

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final TextEditingController lobbyInController = TextEditingController();

  String? errorMsg;

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
                onSubmitted: (rawNumber) {
                  int pin = int.parse(rawNumber);
                  print(
                      "---------- Joining $pin\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
                  widget.conn.joinLobby(pin).then((lobby) {
                    switch (lobby) {
                      case null:
                        setState(() {
                          errorMsg = "Failed to join lobby";
                        });

                      case var lobby:
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LobbyPage(widget.conn, givenLobby: lobby),
                          ),
                        );
                    }
                  });
                },
              ),
              ...switch (errorMsg) {
                null => [],
                var errorMsg => {Text(errorMsg)}
              }
            ],
          ),
        ),
      ),
    );
  }
}
