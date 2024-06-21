import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HostLobbyPage extends StatefulWidget {
  const HostLobbyPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HostLobbyPageState();
  }
}

class HostLobbyPageState extends State<HostLobbyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hosting!"),
        actions: [
          TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(inviteSnackbar());
              },
              child: const Text("Invite"))
        ],
      ),
      body: const Column(
        children: [Text("TODO!")],
      ),
    );
  }

  SnackBar inviteSnackbar() {
    double width = MediaQuery.of(context).size.width / 2.5;
    return SnackBar(
      duration: const Duration(hours: 1),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Invite your friends!", style: TextStyle(fontSize: 25)),
          const Text("(and enemies)"),
          Row(
            children: [
              SizedBox(
                width: width,
                child: QrImageView(data: "jensogkarsten.site"),
              ),
              const Spacer(),
              Image.asset(
                'assets/nfc.png',
                width: width,
              )
            ],
          )
        ],
      ),
    );
  }
}
