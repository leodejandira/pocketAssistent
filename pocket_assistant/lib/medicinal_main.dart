// medicinal_main.dart
import 'package:flutter/material.dart';
import 'medicinal.dart'; // O arquivo unificado que criamos

class MedicinalMainScreen extends StatelessWidget {
  const MedicinalMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MedicinalScreen(); // Retorna a tela com abas
  }
}
