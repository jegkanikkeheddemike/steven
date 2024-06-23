import 'package:flutter/material.dart';
import 'package:steven/host/lobby_page.dart';
import 'package:steven/socket.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage(this.conn, {super.key});
  final Conn conn;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Steven", style: TextStyle(fontSize: 40))),
          Padding(
              padding: const EdgeInsets.all(5),
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HostLobbyPage(conn)),
                    ).then((_) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                    });
                  },
                  child: const Text("HOST"))),
          const Padding(
              padding: EdgeInsets.all(5),
              child: ElevatedButton(onPressed: null, child: Text("JOIN"))),
        ],
      ),
    );
  }
}
