import 'package:flutter/material.dart';

// Classe para a tela de finanças - padrão igual ao HomeScreen
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar específica para tela de finanças
      appBar: AppBar(
        title: const Text('Finanças'), // Título diferente
        backgroundColor: Colors.blue, // Pode ser uma cor diferente
        foregroundColor: Colors.white, // Cor do texto e ícones da appbar
      ),

      body: Container(
        color: Colors.grey[100], // Cor de fundo cinza claro para toda tela
        child: Center(
          // Centraliza o conteúdo horizontal e verticalmente
          child: Column(
            mainAxisAlignment: MainAxisAlignment
                .center, // Centraliza verticalmente DENTRO da Column
            children: [
              // Texto principal da tela
              const Text(
                'FINANCE',
                style: TextStyle(
                  fontSize: 40, // Texto grande
                  fontWeight: FontWeight.bold, // Texto em negrito
                  color: Colors.blue, // Cor azul
                ),
              ),

              // Espaço grande entre o texto e o botão
              const SizedBox(height: 50),

              // Botão elevado (com sombra)
              ElevatedButton(
                onPressed: () {
                  // Navigator.pop REMOVE a tela atual da pilha, voltando para a anterior
                  Navigator.pop(context);
                },
                // Personalização do botão
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Cor de fundo do botão
                  foregroundColor: Colors.white, // Cor do texto do botão
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30, // Espaço interno horizontal
                    vertical: 15, // Espaço interno vertical
                  ),
                ),
                child: const Text('Voltar', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
