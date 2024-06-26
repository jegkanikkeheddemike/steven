import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:steven/game/lobby_page.dart';
import 'package:steven/join_page.dart';
import 'package:steven/socket.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage(this.conn, {super.key});
  final Conn conn;

  @override
  Widget build(BuildContext context) {
    conn.log = (msg) {
      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(msg)));
    };

    return ListenableBuilder(
      listenable: conn,
      builder: (context, _) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Steven", style: TextStyle(fontSize: 40))),
              ...switch (conn.state) {
                ConnState.connecting => const [
                    SpinKitChasingDots(
                      color: Colors.deepPurple,
                    )
                  ],
                ConnState.failed => [
                    Padding(
                        padding: const EdgeInsets.all(100),
                        child: Image.asset("assets/warning.png")),
                    TextButton(
                      onPressed: () {
                        conn.connect(true);
                      },
                      child: const Text("Reconnect"),
                    )
                  ],
                ConnState.connected => [
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LobbyPage(conn)),
                          ).then((_) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                          });
                        },
                        child: const Text("HOST"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => JoinPage(conn)),
                          ).then((_) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                          });
                        },
                        child: const Text("JOIN"),
                      ),
                    ),
                  ]
              },
            ],
          ),
        );
      },
    );
  }
}
