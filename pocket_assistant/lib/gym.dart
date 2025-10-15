import 'package:flutter/material.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({super.key});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Número de abas
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Workout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color.fromARGB(255, 16, 151, 185),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'iniciar'),
              Tab(text: 'Novo'),
              Tab(text: 'Gráficos'),
              Tab(text: 'relatórios'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Conteúdo da aba 1 - Inserir
            Center(child: Text('Aqui selecionar o treino e começar')),

            // Conteúdo da aba 2 - Registros
            Center(child: Text('Aqui registrar treinos novos')),

            // Conteúdo da aba 3 - Gráficos
            Center(child: Text('Aqui ver os gráficos semanias, mensais, etc')),

            // Conteúdo da aba 3 - Gráficos
            Center(child: Text('Gerar relatório')),
          ],
        ),
      ),
    );
  }
}
