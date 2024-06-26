import 'package:flutter/material.dart';
import 'package:steven/device.dart';
import 'package:steven/menu_page.dart';
import 'package:steven/socket.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDevice();
  //Conn conn = Conn("82.211.199.161");
  Conn conn = Conn("jensogkarsten.site");
  runApp(MyApp(conn));
}

class MyApp extends StatelessWidget {
  const MyApp(this.conn, {super.key});
  final Conn conn;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Even Steven!',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: MainMenuPage(conn),
      ),
    );
  }
}
