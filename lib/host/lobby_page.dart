import 'package:flutter/material.dart';
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (users.isEmpty) ...[
            const Center(
                child: Text(
              "No users?? Add or invite your friends",
              style: TextStyle(fontSize: 35),
            ))
          ] else ...[
            Wrap(
              direction: Axis.horizontal,
              spacing: 20,
              children: users.map((u) => Text(u.toString())).toList(),
            )
          ],
          addLocalUserWidget(context)
        ],
      ),
    );
  }

  TextEditingController localUserController = TextEditingController();

  Widget addLocalUserWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: localUserController,
              decoration: const InputDecoration(hintText: "Add local player"),
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
                        users.add(User(localUserController.text));
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
