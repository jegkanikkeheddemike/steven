import 'package:flutter/material.dart';
import 'package:steven/menu_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Even Steven!',
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: MainMenuPage(),
      ),
    );
  }
}
