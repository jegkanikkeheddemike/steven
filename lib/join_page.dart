import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
              Row(
                children: [
                  const Text("Lobby pin:"),
                  TextButton(
                      onPressed: () async {
                        var pinraw = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const QRScannerPage()));
                        if (pinraw == null) {
                          return;
                        }
                        // print("Scanned $pinraw");

                        switch (int.tryParse(pinraw)) {
                          case null:
                            setState(() {
                              errorMsg = "Scanned invalid pin $pinraw";
                            });
                          case var pin:
                            Lobby? lobby = await widget.conn.joinLobby(pin);

                            switch (lobby) {
                              case null:
                                setState(() {
                                  errorMsg = "Failed to join lobby";
                                });
                              case var lobby:
                                if (mounted) {
                                  setState(() {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LobbyPage(
                                            widget.conn,
                                            givenLobby: lobby),
                                      ),
                                    );
                                  });
                                }
                            }
                        }
                      },
                      child: const Text(" Or scan QR"))
                ],
              ),
              TextField(
                controller: lobbyInController,
                keyboardType: TextInputType.number,
                onSubmitted: (rawNumber) {
                  int pin = int.parse(rawNumber);
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

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool discovored = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: MobileScanner(
        onDetect: (capture) async {
          //Prevents double scanning
          if (discovored) {
            return;
          }
          discovored = true;
          print(capture.barcodes.map((e) => e.rawValue!).toList());

          if (mounted) {
            setState(() {
              Navigator.pop(context, capture.barcodes[0].rawValue!);
            });
          }
        },
      ),
    );
  }
}
