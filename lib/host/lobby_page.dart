import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:steven/host/user.dart';

class HostLobbyPage extends StatefulWidget {
  const HostLobbyPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HostLobbyPageState();
  }
}

class HostLobbyPageState extends State<HostLobbyPage> {
  List<User> users = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Hosting!"),
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
        body: showUsers(context));
  }

  Widget showUsers(BuildContext context) {
    if (users.isEmpty) {
      return const Center(
          child: Text(
        "No users?? Add or invite your friends",
        style: TextStyle(fontSize: 35),
      ));
    }

    throw UnimplementedError();
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
