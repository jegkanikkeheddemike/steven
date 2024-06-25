import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:steven/socket.dart';

class HostLobbyPage extends StatefulWidget {
  const HostLobbyPage(this.conn, {super.key});
  final Conn conn;

  @override
  State<StatefulWidget> createState() {
    return HostLobbyPageState();
  }
}

class HostLobbyPageState extends State<HostLobbyPage> {
  Lobby? lobby;

  @override
  void initState() {
    super.initState();

    widget.conn.createLobby().then((newLobby) {
      setState(() {
        lobby = newLobby;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hosting"),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context)
                  .showSnackBar(inviteSnackbar(context));
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
                  "Lobby ${lobby.lobbyNr}",
                  style: const TextStyle(fontSize: 35),
                ),
                Wrap(
                  direction: Axis.horizontal,
                  spacing: 20,
                  children: lobby.users.map((u) => Text(u.toString())).toList(),
                ),
                addLocalUserWidget(context, lobby)
              ]);
            },
          ),
      }),
    );
  }

  TextEditingController localUserController = TextEditingController();

  Widget addLocalUserWidget(BuildContext context, Lobby lobby) {
    return Padding(
      padding: const EdgeInsets.all(5),
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
              child: const Text("Add")),
        ],
      ),
    );
  }

  SnackBar inviteSnackbar(BuildContext context) {
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
              child: QrImageView(data: "jensogkarsten.site"),
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
}
