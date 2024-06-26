import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:steven/socket.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage(this.conn, {super.key, this.givenLobby});
  final Conn conn;
  final Lobby? givenLobby;

  @override
  State<StatefulWidget> createState() {
    return LobbyPageState();
  }
}

class LobbyPageState extends State<LobbyPage> {
  Lobby? lobby;

  @override
  void initState() {
    super.initState();

    switch (widget.givenLobby) {
      case null:
        widget.conn.createLobby().then((newLobby) {
          setState(() {
            lobby = newLobby;
          });
        });
      case var givenLobby:
        setState(() {
          lobby = givenLobby;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: switch (lobby) {
              null => null,
              var lobby => () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(inviteSnackbar(context, lobby.pin));
                }
            },
            child: const Text("Invite"),
          )
        ],
      ),
      body: Center(
          child: switch (lobby) {
        null => const Center(
              child: Text(
            "Creating Lobby",
            style: TextStyle(fontSize: 35),
          )),
        var lobby => ListenableBuilder(
            listenable: lobby,
            builder: (context, _) {
              return Column(children: [
                Text(
                  "Lobby ${lobby.pin}",
                  style: const TextStyle(fontSize: 35),
                ),
                Wrap(
                  direction: Axis.horizontal,
                  spacing: 20,
                  children: lobby.users.map((u) => Text(u.toString())).toList(),
                ),
                addLocalUserWidget(context, lobby),
                ElevatedButton(
                  onPressed: () {
                    widget.conn.startGame(lobby);
                  },
                  child: const Text("START"),
                ),
              ]);
            },
          ),
      }),
    );
  }

  TextEditingController localUserController = TextEditingController();

  Widget addLocalUserWidget(BuildContext context, Lobby lobby) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: localUserController,
              decoration: const InputDecoration(hintText: "Add player"),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          TextButton(
            onPressed: localUserController.text.isEmpty
                ? null
                : () {
                    setState(() {
                      widget.conn.addUser(localUserController.text, lobby);
                      localUserController.clear();
                    });
                  },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  SnackBar inviteSnackbar(BuildContext context, int pin) {
    double width = MediaQuery.of(context).size.width / 2;
    return SnackBar(
      duration: const Duration(hours: 1),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Invite your friends!", style: TextStyle(fontSize: 25)),
          const Text("(and enemies)"),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: width,
              child: QrImageView(data: "$pin"),
            )
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(
              'assets/nfc.png',
              width: width,
            )
          ]),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    if (lobby != null) {
      widget.conn.exitLobbyIfNotStarted(lobby!);
    }
  }
}
