import 'package:flutter/material.dart';

class MedicalScreen extends StatefulWidget {
  const MedicalScreen({super.key});

  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Número de abas
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Medical',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color.fromARGB(255, 16, 185, 55),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Calendário'),
              Tab(text: 'Registrar Consulta'),
              Tab(text: 'Salvar resultado'),
              Tab(text: 'Acompanhamentos/Notas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Conteúdo da aba 1 - Inserir
            Center(
              child: Text(
                'Aqui um carrossel calendário com as consultas marcadas, em baixo, a lista do mes',
              ),
            ),

            // Conteúdo da aba 2 - Registros
            Center(child: Text('Aqui registrar consulta ou exame agendado')),

            // Conteúdo da aba 3 - Gráficos
            Center(
              child: Text(
                'Aqui, salvar/consultar exames, com link para o drive',
              ),
            ),

            // Conteúdo da aba 3 - Gráficos
            Center(
              child: Text(
                'Aqui, lista de exames faltantes, com base numa recomendação de manutenção',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
