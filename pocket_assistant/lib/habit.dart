import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen>
    with SingleTickerProviderStateMixin {
  // Controladores
  final _nomeHabitoController = TextEditingController();
  final List<TextEditingController> _niveisControllers = [
    TextEditingController(),
  ];
  String _iconeSelecionado = 'emoji_objects';
  int? _habitoParaDeletarId;
  List<Map<String, dynamic>> _todosHabitos = [];
  bool _carregandoHabitos = true;

  // Estado para registro diário
  final Map<int, int?> _niveisSelecionados = {};
  final Map<int, bool> _imprevistos = {};
  final Map<int, bool> _habitosRegistradosHoje = {};
  final Map<int, List<Map<String, dynamic>>> _niveisHabitos = {};
  List<Map<String, dynamic>> _habitosDoDia = [];
  bool _carregandoHabitosDoDia = false;

  // Lista de ícones disponíveis
  final List<String> _iconesDisponiveis = [
    'emoji_objects', // Ideias/geral
    'fitness_center', // Exercícios
    'local_dining', // Comida geral
    'book', // Leitura/estudo
    'self_improvement', // Meditação/autoajuda
    'bedtime', // Sono
    'water_drop', // Água
    'mood', // Humor
    'spa', // Relaxamento
    'directions_run', // Corrida
    'restaurant', // Refeições
    'code', // Programação ✅ NOVO
    'calculate', // Matemática ✅ NOVO
    'clean_hands', // Higiene ✅ NOVO
    'local_florist', // Natureza/vegetariano
    'work', // Trabalho
    'school', // Estudos
    'music_note', // Música
    'movie', // Filmes
    'shopping_cart', // Compras
    'savings', // Economia
    'family_restroom', // Família
    'pets', // Pets
    'eco', // Sustentabilidade
    'volunteer_activism', // Voluntariado
  ];

  // Controlador para as abas
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _carregarTodosHabitos();
    _carregarHabitosDoDia();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });

      // Recarregar hábitos do dia quando voltar para a primeira aba
      if (_tabController.index == 0) {
        _carregarHabitosDoDia();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeHabitoController.dispose();
    for (var controller in _niveisControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarTodosHabitos() async {
    setState(() {
      _carregandoHabitos = true;
    });
    try {
      final data = await Supabase.instance.client
          .from('habitos')
          .select()
          .eq('ativo', true)
          .order('data_criacao');

      setState(() {
        _todosHabitos = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      _showSnackBar('Erro ao carregar hábitos: $e', isError: true);
    } finally {
      setState(() {
        _carregandoHabitos = false;
      });
    }
  }

  Future<void> _carregarHabitosDoDia() async {
    if (_carregandoHabitosDoDia) return;

    setState(() {
      _carregandoHabitosDoDia = true;
    });

    try {
      // LIMPAR ESTADOS ANTES DE CARREGAR
      _niveisSelecionados.clear();
      _imprevistos.clear();
      _habitosRegistradosHoje.clear();
      _niveisHabitos.clear();

      final habitos = await Supabase.instance.client
          .from('habitos')
          .select()
          .eq('ativo', true)
          .order('data_criacao');

      final hoje = DateTime.now().toIso8601String().split('T')[0];
      final registrosHoje = await Supabase.instance.client
          .from('habitos_registros')
          .select()
          .eq('data_registro', hoje);

      // Carregar níveis de todos os hábitos de uma vez
      for (final habito in habitos) {
        final habitoId = habito['id'] as int;

        // Carregar níveis do hábito
        final niveis = await Supabase.instance.client
            .from('habitos_niveis')
            .select()
            .eq('habito_id', habitoId)
            .order('ordem');

        _niveisHabitos[habitoId] = List<Map<String, dynamic>>.from(niveis);

        final registroHoje = registrosHoje.firstWhere(
          (reg) => reg['habito_id'] == habitoId,
          orElse: () => {},
        );

        if (registroHoje.isNotEmpty) {
          // Já foi registrado hoje
          _niveisSelecionados[habitoId] = registroHoje['nivel'] as int?;
          _imprevistos[habitoId] = registroHoje['nivel'] == null;
          _habitosRegistradosHoje[habitoId] = true;
        } else {
          // Ainda não registrado hoje - estado inicial
          _niveisSelecionados[habitoId] = 1;
          _imprevistos[habitoId] = false;
          _habitosRegistradosHoje[habitoId] = false;
        }
      }

      setState(() {
        _habitosDoDia = List<Map<String, dynamic>>.from(habitos);
      });
    } catch (e) {
      _showSnackBar('Erro ao carregar hábitos do dia: $e', isError: true);
    } finally {
      setState(() {
        _carregandoHabitosDoDia = false;
      });
    }
  }

  Future<bool> _verificarSeHabitoRegistradoHoje(int habitoId) async {
    try {
      final hoje = DateTime.now().toIso8601String().split('T')[0];
      final registros = await Supabase.instance.client
          .from('habitos_registros')
          .select()
          .eq('habito_id', habitoId)
          .eq('data_registro', hoje);

      return registros.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _salvarHabito() async {
    final nome = _nomeHabitoController.text.trim();
    if (nome.isEmpty) {
      _showSnackBar('Digite um nome para o hábito', isError: true);
      return;
    }

    final niveisValidos = <String>[];
    for (int i = 0; i < _niveisControllers.length; i++) {
      final descricao = _niveisControllers[i].text.trim();
      if (descricao.isNotEmpty) {
        niveisValidos.add(descricao);
      }
    }

    if (niveisValidos.isEmpty) {
      _showSnackBar('Adicione pelo menos um nível', isError: true);
      return;
    }

    try {
      final habitoResponse = await Supabase.instance.client
          .from('habitos')
          .insert({'nome': nome, 'icone': _iconeSelecionado})
          .select()
          .single();

      final habitoId = habitoResponse['id'] as int;

      for (int i = 0; i < niveisValidos.length; i++) {
        await Supabase.instance.client.from('habitos_niveis').insert({
          'habito_id': habitoId,
          'nivel': i + 1,
          'descricao': niveisValidos[i],
          'ordem': i + 1,
        });
      }

      _showSnackBar('Hábito "$nome" cadastrado com sucesso!');
      _nomeHabitoController.clear();
      for (var controller in _niveisControllers) {
        controller.clear();
      }
      _niveisControllers.clear();
      _niveisControllers.add(TextEditingController());
      setState(() {
        _iconeSelecionado = 'emoji_objects';
      });
      _carregarTodosHabitos();
      _carregarHabitosDoDia(); // Recarregar hábitos do dia também
    } catch (e) {
      _showSnackBar('Erro ao salvar hábito: $e', isError: true);
    }
  }

  Future<void> _deletarHabito() async {
    if (_habitoParaDeletarId == null) {
      _showSnackBar('Selecione um hábito para deletar', isError: true);
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja deletar este hábito? Todos os registros serão perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await Supabase.instance.client
          .from('habitos')
          .update({'ativo': false})
          .eq('id', _habitoParaDeletarId!);

      _showSnackBar('Hábito deletado com sucesso!');
      setState(() {
        _habitoParaDeletarId = null;
      });
      _carregarTodosHabitos();
      _carregarHabitosDoDia(); // Recarregar hábitos do dia também
    } catch (e) {
      _showSnackBar('Erro ao deletar hábito: $e', isError: true);
    }
  }

  Future<void> _registrarHabitoDiario(
    int habitoId,
    int? nivel,
    bool imprevisto,
  ) async {
    try {
      final hoje = DateTime.now().toIso8601String().split('T')[0];

      // Verificar se já foi registrado hoje
      final jaRegistrado = await _verificarSeHabitoRegistradoHoje(habitoId);
      if (jaRegistrado) {
        _showSnackBar('Este hábito já foi registrado hoje!', isError: true);
        return;
      }

      await Supabase.instance.client.from('habitos_registros').insert({
        'habito_id': habitoId,
        'nivel': imprevisto ? null : nivel,
        'data_registro': hoje,
      });

      _showSnackBar('Hábito registrado com sucesso!');

      setState(() {
        _habitosRegistradosHoje[habitoId] = true;
        if (imprevisto) {
          _imprevistos[habitoId] = true;
          _niveisSelecionados[habitoId] = null;
        } else {
          _imprevistos[habitoId] = false;
          _niveisSelecionados[habitoId] = nivel;
        }
      });
    } catch (e) {
      _showSnackBar('Erro ao registrar hábito: $e', isError: true);
    }
  }

  void _adicionarNivel() {
    setState(() {
      _niveisControllers.add(TextEditingController());
    });
  }

  void _removerNivel(int index) {
    if (_niveisControllers.length > 1) {
      setState(() {
        _niveisControllers[index].dispose();
        _niveisControllers.removeAt(index);
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'local_dining':
        return Icons.local_dining;
      case 'book':
        return Icons.book;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'bedtime':
        return Icons.bedtime;
      case 'water_drop':
        return Icons.water_drop;
      case 'mood':
        return Icons.mood;
      case 'spa':
        return Icons.spa;
      case 'directions_run':
        return Icons.directions_run;
      case 'restaurant':
        return Icons.restaurant;
      case 'code': // ✅ NOVO - Programação
        return Icons.code;
      case 'calculate': // ✅ NOVO - Matemática
        return Icons.calculate;
      case 'clean_hands': // ✅ NOVO - Higiene
        return Icons.clean_hands;
      case 'local_florist':
        return Icons.local_florist;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'music_note':
        return Icons.music_note;
      case 'movie':
        return Icons.movie;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'savings':
        return Icons.savings;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'pets':
        return Icons.pets;
      case 'eco':
        return Icons.eco;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      default:
        return Icons.emoji_objects;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildNivelField(int index, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nível ${index + 1}',
                border: const OutlineInputBorder(),
                hintText: 'Ex: 1 fruta, 30 minutos...',
              ),
            ),
          ),
          if (_niveisControllers.length > 1) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.red),
              onPressed: () => _removerNivel(index),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _iconesDisponiveis.map((icone) {
        return ChoiceChip(
          label: Icon(_getIconFromString(icone)),
          selected: _iconeSelecionado == icone,
          onSelected: (selected) {
            setState(() {
              _iconeSelecionado = icone;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildDeletarDropdown() {
    if (_carregandoHabitos) return const CircularProgressIndicator();
    if (_todosHabitos.isEmpty) return const Text('Nenhum hábito cadastrado');

    return DropdownButtonFormField<int>(
      value: _habitoParaDeletarId,
      hint: const Text('Selecione um hábito para deletar'),
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: _todosHabitos.map((habito) {
        return DropdownMenuItem<int>(
          value: habito['id'],
          child: Row(
            children: [
              Icon(_getIconFromString(habito['icone'] ?? 'emoji_objects')),
              const SizedBox(width: 8),
              Text(habito['nome']),
            ],
          ),
        );
      }).toList(),
      onChanged: (int? novoValor) {
        setState(() {
          _habitoParaDeletarId = novoValor;
        });
      },
    );
  }

  Widget _buildCardHabito(Map<String, dynamic> habito) {
    final habitoId = habito['id'] as int;
    final nivelSelecionado = _niveisSelecionados[habitoId];
    final imprevisto = _imprevistos[habitoId] ?? false;
    final jaRegistradoHoje = _habitosRegistradosHoje[habitoId] ?? false;
    final niveis = _niveisHabitos[habitoId] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIconFromString(habito['icone'] ?? 'emoji_objects')),
                const SizedBox(width: 8),
                Text(
                  habito['nome'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mostrar controles apenas se NÃO estiver registrado
            if (!jaRegistradoHoje && !imprevisto) ...[
              if (niveis.isEmpty) ...[
                const Text('Nenhum nível configurado'),
              ] else ...[
                Column(
                  children: [
                    Slider(
                      value: (nivelSelecionado ?? 1).toDouble(),
                      min: 1,
                      max: niveis.length.toDouble(),
                      divisions: niveis.length - 1,
                      onChanged: (value) {
                        setState(() {
                          _niveisSelecionados[habitoId] = value.toInt();
                        });
                      },
                    ),
                    Text(
                      niveis.firstWhere(
                        (nivel) => nivel['nivel'] == (nivelSelecionado ?? 1),
                        orElse: () => {
                          'descricao': 'Nível ${nivelSelecionado ?? 1}',
                        },
                      )['descricao'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],

            if (!jaRegistradoHoje) ...[
              Row(
                children: [
                  Checkbox(
                    value: imprevisto,
                    onChanged: (value) {
                      setState(() {
                        _imprevistos[habitoId] = value ?? false;
                        if (value == true) {
                          _niveisSelecionados[habitoId] = null;
                        } else {
                          _niveisSelecionados[habitoId] = 1;
                        }
                      });
                    },
                  ),
                  const Text('Imprevisto'),
                ],
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton.icon(
              onPressed: jaRegistradoHoje
                  ? null
                  : () {
                      final nivel = imprevisto ? null : nivelSelecionado;
                      _registrarHabitoDiario(habitoId, nivel, imprevisto);
                    },
              icon: const Icon(Icons.send),
              label: Text(jaRegistradoHoje ? 'Já Registrado' : 'Send'),
              style: ElevatedButton.styleFrom(
                backgroundColor: jaRegistradoHoje ? Colors.grey : Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistroDiario() {
    if (_carregandoHabitosDoDia) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_habitosDoDia.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_objects, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum hábito cadastrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Cadastre seu primeiro hábito na aba ao lado →',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _habitosDoDia.length,
      itemBuilder: (context, index) {
        return _buildCardHabito(_habitosDoDia[index]);
      },
    );
  }

  Widget _buildCadastrarHabito() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Cadastrar Novo Hábito'),
          const SizedBox(height: 16),
          TextField(
            controller: _nomeHabitoController,
            decoration: const InputDecoration(
              labelText: 'Nome do Hábito',
              border: OutlineInputBorder(),
              hintText: 'Ex: Comer frutas, Exercitar, Estudar...',
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Níveis do Hábito'),
          const SizedBox(height: 8),
          ..._niveisControllers.asMap().entries.map((entry) {
            return _buildNivelField(entry.key, entry.value);
          }).toList(),
          ElevatedButton.icon(
            onPressed: _adicionarNivel,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Nível'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Ícone do Hábito'),
          const SizedBox(height: 8),
          _buildIconSelector(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _salvarHabito,
            icon: const Icon(Icons.save),
            label: const Text('Salvar Hábito'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const Divider(height: 48),
          _buildSectionTitle('Gerenciar Hábitos'),
          const SizedBox(height: 16),
          _buildDeletarDropdown(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _deletarHabito,
            icon: const Icon(Icons.delete),
            label: const Text('Deletar Hábito'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Habits',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 16, 151, 185),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Registro diário'),
            Tab(text: 'Cadastrar Hábito'),
            Tab(text: 'Gráficos'),
            Tab(text: 'Relatórios'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRegistroDiario(),
          _buildCadastrarHabito(),
          const Center(
            child: Text('Aqui ver os gráficos semanais, mensais, etc'),
          ),
          const Center(child: Text('Gerar relatório')),
        ],
      ),
    );
  }
}
