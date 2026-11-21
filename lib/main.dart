import 'package:flutter/material.dart';
import 'common.dart';
import 'screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await save.load();
  runApp(const PandaWorldApp());
}

class PandaWorldApp extends StatelessWidget {
  const PandaWorldApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "Panda's Magical Bamboo World",
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: leaf),
      fontFamily: 'Arial',
    ),
    home: const MenuScreen(),
  );
}
