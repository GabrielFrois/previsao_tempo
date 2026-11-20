import 'package:flutter/material.dart';

import 'telas/tela_busca.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PrevisaoApp());
}

class PrevisaoApp extends StatelessWidget {
  const PrevisaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Previsão do tempo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TelaBusca(),
    );
  }
}