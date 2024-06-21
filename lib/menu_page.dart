import 'package:flutter/material.dart';
import 'package:steven/host/lobby_page.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

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
                          builder: (context) => const HostLobbyPage()),
                    );
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
