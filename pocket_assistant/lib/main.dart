import 'package:flutter/material.dart';
import 'finance_screen.dart';
import 'medicinal.dart';
import 'gym.dart';
import 'db_config.dart';

void main() async {
  // 1. Inicializar binding do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar Supabase
  await SupabaseConfig.initialize();

  // 3. Rodar o app
  runApp(const MyApp());
}

// Classe principal do app - herda de StatelessWidget (widget sem estado)
class MyApp extends StatelessWidget {
  // Construtor da classe - super.key é necessário para widgets Flutter
  const MyApp({super.key});

  // Método OBRIGATÓRIO que constrói a interface do widget
  @override
  Widget build(BuildContext context) {
    // MaterialApp é o widget raiz que configura todo o app
    return MaterialApp(
      title: 'Pocket Assistant', // Nome do app
      debugShowCheckedModeBanner: false, // Remove a faixa "DEBUG"
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ), // Tema visual
      home: const HomeScreen(), // Define a tela inicial
    );
  }
}

// Tela inicial do app - também um StatelessWidget
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold é um layout básico com appbar, body, etc.
    return Scaffold(
      // AppBar - barra superior da tela
      appBar: AppBar(
        title: const Text(
          'Pocket Assistant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2563EB), // Cor de fundo azul
        elevation: 0, // Remove sombra da appbar
      ),
      // Body - conteúdo principal da tela
      body: Padding(
        padding: const EdgeInsets.all(
          16.0,
        ), // Espaço interno de 16px em todas as bordas
        child: Column(
          // Column organiza widgets verticalmente
          children: [
            // Chama a função que cria um card, passando os parâmetros
            _buildModuleCard(
              icon: Icons.attach_money, // Ícone do material design
              title: 'Controle Financeiro',
              subtitle: 'Gerencie suas finanças',
              color: const Color(0xFF8B5CF6), // Cor roxa
              onTap: () {
                // Navigator.push adiciona uma nova tela na pilha de navegação
                Navigator.push(
                  context, // Contexto necessário para navegação
                  MaterialPageRoute(
                    // Cria uma rota para a tela FinanceScreen
                    builder: (context) => const FinanceScreen(),
                  ),
                );
              },
            ),
            // SizedBox cria um espaço fixo de 16px de altura
            const SizedBox(height: 16),
            // Outro card - mesmo padrão mas com onTap vazio por enquanto
            _buildModuleCard(
              icon: Icons.medical_services,
              title: 'Hábitos',
              subtitle: 'Controle de hábitos',
              color: const Color(0xFF10B981), // Cor verde
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MedicalScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildModuleCard(
              icon: Icons.fitness_center,
              title: 'Treinos & Relatórios',
              subtitle: 'Planos e progresso',
              color: const Color(0xFFF59E0B), // Cor laranja
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GymScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildModuleCard(
              icon: Icons.settings,
              title: 'Configurações',
              subtitle: 'Preferências do app',
              color: const Color(0xFF6B7280), // Cor cinza
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  // FUNÇÃO que cria um card reutilizável
  // Widget = qualquer elemento de interface no Flutter
  Widget _buildModuleCard({
    required IconData icon, // Parâmetro obrigatório do tipo ícone
    required String title, // Parâmetro obrigatório do tipo string
    required String subtitle,
    required Color color,
    required VoidCallback onTap, // Função que é chamada quando clica no card
  }) {
    return Card(
      elevation: 2, // Sombra do card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Bordas arredondadas
      child: InkWell(
        // Torna o card clicável (com efeito visual de toque)
        onTap: onTap, // Quando clicar, executa a função passada
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Espaço interno do card
          child: Row(
            // Organiza widgets horizontalmente
            children: [
              // Container para o ícone com fundo colorido
              Container(
                padding: const EdgeInsets.all(12), // Espaço interno do ícone
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), // Cor com 10% de opacidade
                  borderRadius: BorderRadius.circular(8), // Bordas arredondadas
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ), // Ícone propriamente dito
              ),
              const SizedBox(width: 16), // Espaço entre ícone e texto
              // Expanded faz o widget ocupar todo espaço disponível restante
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Alinha à esquerda
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B), // Cinza escuro
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ), // Pequeno espaço entre título e subtítulo
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B), // Cinza médio
                      ),
                    ),
                  ],
                ),
              ),
              // Ícone de setinha à direita
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
