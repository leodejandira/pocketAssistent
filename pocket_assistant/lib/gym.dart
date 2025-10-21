import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class GymScreen extends StatefulWidget {
  const GymScreen({super.key});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  // Controladores para cadastro de exercício
  final _nomeExercicioController = TextEditingController();
  final _exercicioParaDeletarController = TextEditingController();

  // Controladores para cadastro de treino
  final _nomeRotinaController = TextEditingController();

  // Variáveis de estado - exercícios
  String? _selectedEquipamentoNome;
  String? _selectedGrupoPrimarioNome;
  String? _selectedTipoExercicioNome;
  final List<String> _selectedGruposSecundariosNomes = [];
  int? _selectedExercicioParaDeletarId;

  // Variáveis para cadastro de treino
  final List<Map<String, dynamic>> _exerciciosAdicionados = [];
  int? _selectedRotinaParaDeletarId;

  // Variáveis para registrar treino
  int? _selectedRotinaId;
  Map<String, dynamic>? _rotinaSelecionada;
  List<Map<String, dynamic>> _exerciciosRotina = [];
  final List<List<Map<String, dynamic>>> _dadosSeries = [];
  bool _timerRodando = false;
  int _tempoDecorrido = 0;
  late Timer _timer;
  bool _isLoadingExerciciosRotina = false;

  // Listas de dados
  List<Map<String, dynamic>> _equipamentos = [];
  List<Map<String, dynamic>> _gruposMusculares = [];
  List<Map<String, dynamic>> _tiposExercicio = [];
  List<Map<String, dynamic>> _exercicios = [];
  List<Map<String, dynamic>> _rotinas = [];

  // Estados de loading
  bool _isLoadingEquipamentos = true;
  bool _isLoadingGruposMusculares = true;
  bool _isLoadingTiposExercicio = true;
  bool _isLoadingExercicios = true;
  bool _isLoadingRotinas = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _timer = Timer.periodic(const Duration(seconds: 1), _atualizarTimer);
  }

  @override
  void dispose() {
    _nomeExercicioController.dispose();
    _exercicioParaDeletarController.dispose();
    _nomeRotinaController.dispose();
    _timer.cancel();
    super.dispose();
  }

  // Função para buscar últimos valores dos exercícios - MELHORADA
  Future<Map<String, dynamic>> _buscarUltimosValoresExercicio(
    int exercicioId,
  ) async {
    try {
      print('🔍 Buscando últimos valores para exercício ID: $exercicioId');

      final response = await Supabase.instance.client
          .from('registro_exercicios')
          .select('''
            peso, 
            repeticoes, 
            tempo, 
            distancia
          ''')
          .eq('exercicio_id', exercicioId)
          .order('created_at', ascending: false)
          .limit(1);

      print('📊 Resultado da busca: ${response.length} registros encontrados');

      if (response.isNotEmpty) {
        final dados = response[0];
        print('🎯 Dados encontrados: $dados');

        // Só retorna valores que não são nulos
        final result = {
          'peso': dados['peso'],
          'repeticoes': dados['repeticoes'],
          'tempo': dados['tempo'],
          'distancia': dados['distancia'],
        };

        // Verifica se tem pelo menos um valor não nulo
        final hasValidData = result.values.any((value) => value != null);

        if (hasValidData) {
          return result;
        } else {
          print('⚠️ Registro encontrado mas todos os valores são nulos');
        }
      } else {
        print('⚠️ Nenhum registro anterior encontrado para este exercício');
      }
    } catch (e) {
      print('❌ Erro ao buscar últimos valores: $e');
    }

    return {'peso': null, 'repeticoes': null, 'tempo': null, 'distancia': null};
  }

  void _atualizarTimer(Timer timer) {
    if (_timerRodando) {
      setState(() {
        _tempoDecorrido++;
      });
    }
  }

  String _formatarTempo(int segundos) {
    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;
    final segs = segundos % 60;
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  void _iniciarTimer() {
    setState(() {
      _timerRodando = true;
    });
  }

  void _pausarTimer() {
    setState(() {
      _timerRodando = false;
    });
  }

  void _resetarTimer() {
    setState(() {
      _timerRodando = false;
      _tempoDecorrido = 0;
    });
  }

  // Carrega todos os dados necessários
  Future<void> _carregarDados() async {
    await Future.wait([
      _carregarEquipamentos(),
      _carregarGruposMusculares(),
      _carregarTiposExercicio(),
      _carregarExercicios(),
      _carregarRotinas(),
    ]);
  }

  Future<void> _carregarEquipamentos() async {
    setState(() => _isLoadingEquipamentos = true);
    try {
      final data = await Supabase.instance.client.from('equipamentos').select();
      setState(() => _equipamentos = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      _showSnackBar('Erro ao carregar equipamentos', isError: true);
    } finally {
      setState(() => _isLoadingEquipamentos = false);
    }
  }

  Future<void> _carregarGruposMusculares() async {
    setState(() => _isLoadingGruposMusculares = true);
    try {
      final data = await Supabase.instance.client
          .from('grupos_musculares')
          .select();
      setState(() => _gruposMusculares = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      _showSnackBar('Erro ao carregar grupos musculares', isError: true);
    } finally {
      setState(() => _isLoadingGruposMusculares = false);
    }
  }

  Future<void> _carregarTiposExercicio() async {
    setState(() => _isLoadingTiposExercicio = true);
    try {
      final data = await Supabase.instance.client
          .from('tipos_exercicio')
          .select();
      setState(() => _tiposExercicio = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      _showSnackBar('Erro ao carregar tipos de exercício', isError: true);
    } finally {
      setState(() => _isLoadingTiposExercicio = false);
    }
  }

  Future<void> _carregarExercicios() async {
    setState(() => _isLoadingExercicios = true);
    try {
      final data = await Supabase.instance.client.from('exercicios').select();
      setState(() => _exercicios = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      _showSnackBar('Erro ao carregar exercícios', isError: true);
    } finally {
      setState(() => _isLoadingExercicios = false);
    }
  }

  Future<void> _carregarRotinas() async {
    setState(() => _isLoadingRotinas = true);
    try {
      final data = await Supabase.instance.client.from('rotinas').select('''
            *,
            rotina_exercicios(
              numero_series,
              exercicios(*)
            )
          ''');
      setState(() => _rotinas = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      _showSnackBar('Erro ao carregar rotinas', isError: true);
    } finally {
      setState(() => _isLoadingRotinas = false);
    }
  }

  void _selecionarRotina(int? rotinaId) async {
    print('🎯 Selecionando rotina: $rotinaId');

    setState(() {
      _selectedRotinaId = rotinaId;
      _rotinaSelecionada = _rotinas.firstWhere(
        (rotina) => rotina['id'] == rotinaId,
        orElse: () => <String, dynamic>{},
      );
      _isLoadingExerciciosRotina = true;
    });

    if (_rotinaSelecionada != null && _rotinaSelecionada!.isNotEmpty) {
      final exerciciosData = _rotinaSelecionada!['rotina_exercicios'];
      print('📋 Exercícios da rotina: ${exerciciosData?.length ?? 0}');

      if (exerciciosData is List && exerciciosData.isNotEmpty) {
        _exerciciosRotina = List<Map<String, dynamic>>.from(exerciciosData);

        // Carregar últimos valores para cada exercício
        for (int i = 0; i < _exerciciosRotina.length; i++) {
          final exercicio =
              _exerciciosRotina[i]['exercicios'] as Map<String, dynamic>;
          print(
            '🔍 Buscando últimos valores para: ${exercicio['nome']} (ID: ${exercicio['id']})',
          );

          final ultimosValores = await _buscarUltimosValoresExercicio(
            exercicio['id'],
          );
          print('📊 Últimos valores encontrados: $ultimosValores');

          _exerciciosRotina[i]['ultimos_valores'] = ultimosValores;
        }

        _inicializarDadosSeries();
      } else {
        _exerciciosRotina = [];
        _dadosSeries.clear();
      }
    } else {
      _exerciciosRotina = [];
      _dadosSeries.clear();
    }

    setState(() {
      _isLoadingExerciciosRotina = false;
    });
    _resetarTimer();
  }

  void _inicializarDadosSeries() {
    _dadosSeries.clear();

    for (int i = 0; i < _exerciciosRotina.length; i++) {
      final exercicio = _exerciciosRotina[i];
      final numeroSeries = exercicio['numero_series'] as int;
      final ultimosValores =
          exercicio['ultimos_valores'] as Map<String, dynamic>?;
      final tipoExercicio =
          (exercicio['exercicios'] as Map<String, dynamic>)['tipo_exercicio']
              as String;

      print(
        '🔄 Inicializando $numeroSeries séries para ${(exercicio['exercicios'] as Map<String, dynamic>)['nome']}',
      );
      print('📋 Últimos valores disponíveis: $ultimosValores');

      final series = List<Map<String, dynamic>>.generate(numeroSeries, (index) {
        Map<String, dynamic> serie = {'concluido': false};

        // Aplicar últimos valores para TODAS as séries
        if (ultimosValores != null) {
          // Só copia valores que não são nulos
          if (ultimosValores['peso'] != null) {
            serie['peso'] = ultimosValores['peso'];
          }
          if (ultimosValores['repeticoes'] != null) {
            serie['repeticoes'] = ultimosValores['repeticoes'];
          }
          if (ultimosValores['tempo'] != null) {
            serie['tempo'] = ultimosValores['tempo'];
          }
          if (ultimosValores['distancia'] != null) {
            serie['distancia'] = ultimosValores['distancia'];
          }
        }

        // Se não tem últimos valores, usar padrão baseado no tipo
        bool hasData =
            serie['peso'] != null ||
            serie['repeticoes'] != null ||
            serie['tempo'] != null ||
            serie['distancia'] != null;

        if (!hasData) {
          print('   Usando valores padrão para tipo: $tipoExercicio');
          switch (tipoExercicio) {
            case 'Repetições x KG':
              serie['peso'] = 20.0;
              serie['repeticoes'] = 12;
              break;
            case 'Peso x Distância':
              serie['peso'] = 0.0;
              serie['distancia'] = 100.0;
              break;
            case 'Tempo':
              serie['tempo'] = 60;
              break;
            case 'Repetições':
              serie['repeticoes'] = 15;
              break;
            case 'Tempo x KG':
              serie['tempo'] = 60;
              serie['peso'] = 20.0;
              break;
            case 'Tempo x Metros':
              serie['tempo'] = 60;
              serie['distancia'] = 100.0;
              break;
            case 'Distância':
              serie['distancia'] = 100.0;
              break;
          }
        }

        print('   Série ${index + 1}: $serie');
        return serie;
      });

      _dadosSeries.add(series);
    }

    print(
      '✅ Total de ${_dadosSeries.length} exercícios inicializados com séries',
    );
  }

  void _atualizarDadosSerie(
    int exercicioIndex,
    int serieIndex,
    String campo,
    dynamic valor,
  ) {
    if (_dadosSeries.isEmpty ||
        exercicioIndex >= _dadosSeries.length ||
        serieIndex >= _dadosSeries[exercicioIndex].length) {
      return;
    }

    setState(() {
      _dadosSeries[exercicioIndex][serieIndex][campo] = valor;
    });
  }

  void _marcarSerieConcluida(
    int exercicioIndex,
    int serieIndex,
    bool concluido,
  ) {
    if (_dadosSeries.isEmpty ||
        exercicioIndex >= _dadosSeries.length ||
        serieIndex >= _dadosSeries[exercicioIndex].length) {
      return;
    }

    setState(() {
      _dadosSeries[exercicioIndex][serieIndex]['concluido'] = concluido;
    });
  }

  // REGISTRAR TREINO - VERSÃO CORRIGIDA
  Future<void> _registrarTreino() async {
    if (_selectedRotinaId == null) {
      _showSnackBar('Selecione uma rotina', isError: true);
      return;
    }

    if (!_timerRodando && _tempoDecorrido == 0) {
      _showSnackBar('Inicie o timer antes de registrar', isError: true);
      return;
    }

    _debugDadosSeries();

    try {
      // 1. Insere o registro do treino
      final response =
          await Supabase.instance.client.from('registros_treino').insert({
            'rotina_id': _selectedRotinaId,
            'tempo_total': _tempoDecorrido,
            'data_treino': DateTime.now().toIso8601String(),
          }).select();

      if (response.isNotEmpty) {
        final registroId = response[0]['id'] as int;

        // 2. Insere os dados de CADA exercício e CADA série
        final registrosExercicios = <Map<String, dynamic>>[];

        for (
          int exercicioIndex = 0;
          exercicioIndex < _exerciciosRotina.length;
          exercicioIndex++
        ) {
          final exercicioRotina = _exerciciosRotina[exercicioIndex];
          final exercicio =
              exercicioRotina['exercicios'] as Map<String, dynamic>;

          if (exercicioIndex < _dadosSeries.length) {
            final series = _dadosSeries[exercicioIndex];

            for (int serieIndex = 0; serieIndex < series.length; serieIndex++) {
              final serie = series[serieIndex];

              registrosExercicios.add({
                'registro_treino_id': registroId,
                'exercicio_id': exercicio['id'],
                'ordem': exercicioIndex,
                'numero_serie': serieIndex + 1,
                'peso': serie['peso'],
                'repeticoes': serie['repeticoes'],
                'tempo': serie['tempo'],
                'distancia': serie['distancia'],
                'concluido': serie['concluido'] ?? false,
              });
            }
          }
        }

        // 3. Insere TODOS os registros de exercícios
        if (registrosExercicios.isNotEmpty) {
          await Supabase.instance.client
              .from('registro_exercicios')
              .insert(registrosExercicios);

          print(
            '✅ Foram inseridos ${registrosExercicios.length} registros de séries',
          );
        }

        _showSnackBar(
          'Treino registrado com sucesso! ${registrosExercicios.length} séries salvas',
        );
        _resetarTreino();
      }
    } catch (e) {
      print('❌ Erro detalhado ao registrar treino: $e');
      _showSnackBar('Erro ao registrar treino: $e', isError: true);
    }
  }

  void _debugDadosSeries() {
    print('=== DEBUG DADOS SERIES ===');
    for (int i = 0; i < _dadosSeries.length; i++) {
      print('Exercício $i: ${_dadosSeries[i].length} séries');
      for (int j = 0; j < _dadosSeries[i].length; j++) {
        print('  Série ${j + 1}: ${_dadosSeries[i][j]}');
      }
    }
    print('==========================');
  }

  void _resetarTreino() {
    setState(() {
      _selectedRotinaId = null;
      _rotinaSelecionada = null;
      _exerciciosRotina = [];
      _dadosSeries.clear();
      _isLoadingExerciciosRotina = false;
      _resetarTimer();
    });
  }

  // Cadastrar novo exercício
  Future<void> _cadastrarExercicio() async {
    final nome = _nomeExercicioController.text.trim();

    if (nome.isEmpty ||
        _selectedEquipamentoNome == null ||
        _selectedGrupoPrimarioNome == null ||
        _selectedTipoExercicioNome == null) {
      _showSnackBar('Preencha todos os campos obrigatórios', isError: true);
      return;
    }

    try {
      await Supabase.instance.client.from('exercicios').insert({
        'nome': nome,
        'equipamento': _selectedEquipamentoNome,
        'grupo_muscular_primario': _selectedGrupoPrimarioNome,
        'grupos_musculares_secundarios': _selectedGruposSecundariosNomes,
        'tipo_exercicio': _selectedTipoExercicioNome,
      });

      _showSnackBar('Exercício cadastrado com sucesso!');
      _limparFormularioExercicio();
      _carregarExercicios();
    } catch (e) {
      _showSnackBar('Erro ao cadastrar exercício: $e', isError: true);
    }
  }

  // Deletar exercício
  Future<void> _deletarExercicio() async {
    if (_selectedExercicioParaDeletarId == null) {
      _showSnackBar('Selecione um exercício para deletar', isError: true);
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja deletar este exercício?'),
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
          .from('exercicios')
          .delete()
          .eq('id', _selectedExercicioParaDeletarId!);

      _showSnackBar('Exercício deletado com sucesso!');
      setState(() => _selectedExercicioParaDeletarId = null);
      _carregarExercicios();
    } catch (e) {
      _showSnackBar('Erro ao deletar exercício: $e', isError: true);
    }
  }

  // Cadastrar nova rotina
  Future<void> _cadastrarRotina() async {
    final nomeRotina = _nomeRotinaController.text.trim();

    if (nomeRotina.isEmpty) {
      _showSnackBar('Digite um nome para a rotina', isError: true);
      return;
    }

    if (_exerciciosAdicionados.isEmpty) {
      _showSnackBar('Adicione pelo menos um exercício', isError: true);
      return;
    }

    try {
      final response = await Supabase.instance.client.from('rotinas').insert({
        'nome': nomeRotina,
      }).select();

      if (response.isNotEmpty) {
        final rotinaId = response[0]['id'] as int;

        final exerciciosParaInserir = _exerciciosAdicionados
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final exercicio = entry.value;
              return {
                'rotina_id': rotinaId,
                'exercicio_id': exercicio['id'],
                'numero_series': exercicio['series'],
                'ordem': index,
              };
            })
            .toList();

        await Supabase.instance.client
            .from('rotina_exercicios')
            .insert(exerciciosParaInserir);

        _showSnackBar('Rotina cadastrada com sucesso!');
        _limparFormularioRotina();
        _carregarRotinas();
      }
    } catch (e) {
      _showSnackBar('Erro ao cadastrar rotina: $e', isError: true);
    }
  }

  // Deletar rotina
  Future<void> _deletarRotina() async {
    if (_selectedRotinaParaDeletarId == null) {
      _showSnackBar('Selecione uma rotina para deletar', isError: true);
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja deletar esta rotina?'),
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
          .from('rotinas')
          .delete()
          .eq('id', _selectedRotinaParaDeletarId!);

      _showSnackBar('Rotina deletada com sucesso!');
      setState(() => _selectedRotinaParaDeletarId = null);
      _carregarRotinas();
    } catch (e) {
      _showSnackBar('Erro ao deletar rotina: $e', isError: true);
    }
  }

  // Adicionar exercício à rotina
  void _adicionarExercicioRotina() {
    showDialog(
      context: context,
      builder: (context) => _buildDialogAdicionarExercicio(),
    );
  }

  // Remover exercício da rotina
  void _removerExercicioRotina(int index) {
    setState(() {
      _exerciciosAdicionados.removeAt(index);
    });
    _showSnackBar('Exercício removido');
  }

  void _limparFormularioExercicio() {
    _nomeExercicioController.clear();
    setState(() {
      _selectedEquipamentoNome = null;
      _selectedGrupoPrimarioNome = null;
      _selectedTipoExercicioNome = null;
      _selectedGruposSecundariosNomes.clear();
    });
  }

  void _limparFormularioRotina() {
    _nomeRotinaController.clear();
    setState(() {
      _exerciciosAdicionados.clear();
    });
  }

  void _descartarTreino() {
    _limparFormularioRotina();
    _showSnackBar('Treino descartado');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
              Tab(text: 'Registrar treino'),
              Tab(text: 'Cadastrar Treino'),
              Tab(text: 'Cadastrar Exercicio'),
              Tab(text: 'Editar rotina'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRegistrarTreino(),
            _buildCadastrarTreino(),
            _buildCadastrarExercicio(),
            const Center(child: Text('Editar rotina - Em desenvolvimento')),
          ],
        ),
      ),
    );
  }

  // ========== ABA REGISTRAR TREINO ==========
  Widget _buildRegistrarTreino() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Registrar Treino'),
          const SizedBox(height: 16),

          // Seleção de rotina
          DropdownButtonFormField<int>(
            value: _selectedRotinaId,
            hint: const Text('Selecione a rotina'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Rotina',
            ),
            items: _rotinas.map((rotina) {
              return DropdownMenuItem<int>(
                value: rotina['id'],
                child: Text(rotina['nome']),
              );
            }).toList(),
            onChanged: _selecionarRotina,
          ),

          if (_isLoadingExerciciosRotina)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (_rotinaSelecionada != null &&
              _rotinaSelecionada!.isNotEmpty &&
              !_isLoadingExerciciosRotina) ...[
            const SizedBox(height: 24),

            // Timer
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _formatarTempo(_tempoDecorrido),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!_timerRodando)
                          ElevatedButton.icon(
                            onPressed: _iniciarTimer,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Iniciar'),
                          ),
                        if (_timerRodando)
                          ElevatedButton.icon(
                            onPressed: _pausarTimer,
                            icon: const Icon(Icons.pause),
                            label: const Text('Pausar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: _resetarTimer,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Resetar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Lista de exercícios
            if (_exerciciosRotina.isNotEmpty)
              ..._exerciciosRotina.asMap().entries.map((entry) {
                final index = entry.key;
                final exercicioRotina = entry.value;
                final exercicio =
                    exercicioRotina['exercicios'] as Map<String, dynamic>;
                final numeroSeries = exercicioRotina['numero_series'] as int;
                final tipoExercicio = exercicio['tipo_exercicio'] as String;

                final hasDadosSeries = index < _dadosSeries.length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercicio['nome'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$numeroSeries séries - $tipoExercicio',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Séries
                        if (hasDadosSeries)
                          ...List.generate(numeroSeries, (serieIndex) {
                            return _buildSerieWidget(
                              exercicioIndex: index,
                              serieIndex: serieIndex,
                              tipoExercicio: tipoExercicio,
                            );
                          })
                        else
                          const Text('Carregando séries...'),
                      ],
                    ),
                  ),
                );
              })
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Nenhum exercício encontrado nesta rotina'),
              ),

            const SizedBox(height: 24),

            // Botão concluir treino
            ElevatedButton.icon(
              onPressed: _registrarTreino,
              icon: const Icon(Icons.check),
              label: const Text('Concluir Treino'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSerieWidget({
    required int exercicioIndex,
    required int serieIndex,
    required String tipoExercicio,
  }) {
    if (_dadosSeries.isEmpty ||
        exercicioIndex >= _dadosSeries.length ||
        serieIndex >= _dadosSeries[exercicioIndex].length) {
      return const Card(
        margin: EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Erro ao carregar série'),
        ),
      );
    }

    final serie = _dadosSeries[exercicioIndex][serieIndex];
    final concluido = serie['concluido'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: concluido ? Colors.green[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Série ${serieIndex + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: concluido ? Colors.green : null,
                  ),
                ),
                const Spacer(),
                Checkbox(
                  value: concluido,
                  onChanged: (value) {
                    _marcarSerieConcluida(
                      exercicioIndex,
                      serieIndex,
                      value ?? false,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Campos dinâmicos baseados no tipo de exercício
            if (!concluido)
              _buildCamposExercicio(tipoExercicio, exercicioIndex, serieIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildCamposExercicio(
    String tipoExercicio,
    int exercicioIndex,
    int serieIndex,
  ) {
    if (_dadosSeries.isEmpty ||
        exercicioIndex >= _dadosSeries.length ||
        serieIndex >= _dadosSeries[exercicioIndex].length) {
      return const Text('Erro ao carregar campos');
    }

    final serie = _dadosSeries[exercicioIndex][serieIndex];

    switch (tipoExercicio) {
      case 'Peso x Distância':
        return Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  border: const OutlineInputBorder(),
                  // Mostra o valor atual como hint
                  hintText: serie['peso']?.toString() ?? '0.0',
                ),
                onChanged: (value) {
                  _atualizarDadosSerie(
                    exercicioIndex,
                    serieIndex,
                    'peso',
                    double.tryParse(value),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Distância (metros)',
                  border: const OutlineInputBorder(),
                  hintText: serie['distancia']?.toString() ?? '0.0',
                ),
                onChanged: (value) {
                  _atualizarDadosSerie(
                    exercicioIndex,
                    serieIndex,
                    'distancia',
                    double.tryParse(value),
                  );
                },
              ),
            ),
          ],
        );
      case 'Repetições x KG':
        return Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  border: const OutlineInputBorder(),
                  hintText: serie['peso']?.toString() ?? '0.0',
                ),
                onChanged: (value) {
                  _atualizarDadosSerie(
                    exercicioIndex,
                    serieIndex,
                    'peso',
                    double.tryParse(value),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Repetições',
                  border: const OutlineInputBorder(),
                  hintText: serie['repeticoes']?.toString() ?? '0',
                ),
                onChanged: (value) {
                  _atualizarDadosSerie(
                    exercicioIndex,
                    serieIndex,
                    'repeticoes',
                    int.tryParse(value),
                  );
                },
              ),
            ),
          ],
        );

      case 'Repetições':
        return TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Repetições',
            border: const OutlineInputBorder(),
            hintText: serie['repeticoes']?.toString() ?? '0',
          ),
          onChanged: (value) {
            _atualizarDadosSerie(
              exercicioIndex,
              serieIndex,
              'repeticoes',
              int.tryParse(value),
            );
          },
        );

      case 'Tempo':
        return TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Tempo (segundos)',
            border: const OutlineInputBorder(),
            hintText: serie['tempo']?.toString() ?? '0',
          ),
          onChanged: (value) {
            _atualizarDadosSerie(
              exercicioIndex,
              serieIndex,
              'tempo',
              int.tryParse(value),
            );
          },
        );

      case 'Tempo x KG':
        return Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tempo (segundos)',
                  border: const OutlineInputBorder(),
                  hintText: serie['tempo']?.toString() ?? '0',
                ),
                onChanged: (value) {
                  _atualizarDadosSerie(
                    exercicioIndex,
                    serieIndex,
                    'tempo',
                    int.tryParse(value),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  border: const OutlineInputBorder(),
                  hintText: serie['peso']?.toString() ?? '0.0',
                ),
                onChanged: (value) {
                  _atualizarDadosSerie(
                    exercicioIndex,
                    serieIndex,
                    'peso',
                    double.tryParse(value),
                  );
                },
              ),
            ),
          ],
        );

      case 'Tempo x Metros':
        return Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tempo (segundos)',
                  border: const OutlineInputBorder(),
                  hintText: serie['tempo']?.toString() ?? '0',
                ),
                onChanged: (value) {
                  _atualizarDadosSerie(
                    exercicioIndex,
                    serieIndex,
                    'tempo',
                    int.tryParse(value),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Distância (metros)',
                  border: const OutlineInputBorder(),
                  hintText: serie['distancia']?.toString() ?? '0.0',
                ),
                onChanged: (value) {
                  _atualizarDadosSerie(
                    exercicioIndex,
                    serieIndex,
                    'distancia',
                    double.tryParse(value),
                  );
                },
              ),
            ),
          ],
        );

      case 'Distância':
        return TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Distância (metros)',
            border: const OutlineInputBorder(),
            hintText: serie['distancia']?.toString() ?? '0.0',
          ),
          onChanged: (value) {
            _atualizarDadosSerie(
              exercicioIndex,
              serieIndex,
              'distancia',
              double.tryParse(value),
            );
          },
        );

      default:
        return const Text('Tipo de exercício não suportado');
    }
  }

  // ========== ABA CADASTRAR TREINO ==========
  Widget _buildCadastrarTreino() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Criar Nova Rotina'),
          const SizedBox(height: 16),

          TextField(
            controller: _nomeRotinaController,
            decoration: const InputDecoration(
              labelText: 'Nome da Rotina*',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _adicionarExercicioRotina,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Exercício'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _descartarTreino,
                  icon: const Icon(Icons.delete),
                  label: const Text('Descartar Treino'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (_exerciciosAdicionados.isNotEmpty) ...[
            _buildSectionTitle('Exercícios da Rotina'),
            const SizedBox(height: 8),
            ..._exerciciosAdicionados.asMap().entries.map((entry) {
              final index = entry.key;
              final exercicio = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(exercicio['nome']),
                  subtitle: Text('${exercicio['series']} séries'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removerExercicioRotina(index),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cadastrarRotina,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Rotina'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.green,
              ),
            ),
          ],

          const Divider(height: 48, thickness: 1),

          _buildSectionTitle('Deletar Rotina'),
          const SizedBox(height: 16),

          _buildDeletarRotinaDropdown(),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _deletarRotina,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Deletar Rotina'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),

          const Divider(height: 48, thickness: 1),

          _buildSectionTitle('Rotinas Cadastradas'),
          const SizedBox(height: 16),

          _buildListaRotinas(),
        ],
      ),
    );
  }

  Widget _buildDialogAdicionarExercicio() {
    int? selectedExercicioId;
    int numeroSeries = 3;
    final seriesController = TextEditingController(text: '3');

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Adicionar Exercício'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedExercicioId,
                hint: const Text('Selecione o exercício'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Exercício',
                ),
                items: _exercicios.map((exercicio) {
                  return DropdownMenuItem<int>(
                    value: exercicio['id'],
                    child: Text(exercicio['nome']),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    selectedExercicioId = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: seriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de Séries',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    numeroSeries = int.tryParse(value) ?? 3;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedExercicioId == null) {
                  _showSnackBar('Selecione um exercício', isError: true);
                  return;
                }

                final exercicio = _exercicios.firstWhere(
                  (e) => e['id'] == selectedExercicioId,
                );

                this.setState(() {
                  _exerciciosAdicionados.add({
                    'id': selectedExercicioId,
                    'nome': exercicio['nome'],
                    'series': numeroSeries,
                  });
                });

                Navigator.pop(context);
                _showSnackBar('Exercício adicionado');
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeletarRotinaDropdown() {
    if (_isLoadingRotinas) {
      return const Center(child: Text("Carregando rotinas..."));
    }
    return DropdownButtonFormField<int>(
      value: _selectedRotinaParaDeletarId,
      hint: const Text('Selecione a rotina para deletar'),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Rotina',
      ),
      items: _rotinas.map((rotina) {
        return DropdownMenuItem<int>(
          value: rotina['id'],
          child: Text(rotina['nome']),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() => _selectedRotinaParaDeletarId = newValue);
      },
    );
  }

  Widget _buildListaRotinas() {
    if (_isLoadingRotinas) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rotinas.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma rotina cadastrada',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: _rotinas.map((rotina) {
        final exercicios = (rotina['rotina_exercicios'] as List?) ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotina['nome'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...exercicios.map((re) {
                  final exercicio = re['exercicios'] as Map<String, dynamic>;
                  final series = re['numero_series'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${exercicio['nome']} - $series séries'),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ========== ABA CADASTRAR EXERCICIO ==========
  Widget _buildCadastrarExercicio() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Cadastrar Novo Exercício'),
          const SizedBox(height: 16),

          TextField(
            controller: _nomeExercicioController,
            decoration: const InputDecoration(
              labelText: 'Nome do Exercício*',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          _buildEquipamentoChips(),
          const SizedBox(height: 16),

          _buildGrupoPrimarioChips(),
          const SizedBox(height: 16),

          _buildGruposSecundariosChips(),
          const SizedBox(height: 16),

          _buildTipoExercicioChips(),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _cadastrarExercicio,
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar Exercício'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const Divider(height: 48, thickness: 1),

          _buildSectionTitle('Deletar Exercício'),
          const SizedBox(height: 16),

          _buildDeletarExercicioDropdown(),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _deletarExercicio,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Deletar Exercício'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),

          const Divider(height: 48, thickness: 1),

          _buildSectionTitle('Exercícios Cadastrados'),
          const SizedBox(height: 16),

          _buildListaExercicios(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildEquipamentoChips() {
    if (_isLoadingEquipamentos) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Equipamento*',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _equipamentos.map((equipamento) {
            final isSelected = _selectedEquipamentoNome == equipamento['nome'];
            return ChoiceChip(
              label: Text(equipamento['nome']),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedEquipamentoNome = selected
                      ? equipamento['nome']
                      : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGrupoPrimarioChips() {
    if (_isLoadingGruposMusculares) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grupo Muscular Primário*',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _gruposMusculares.map((grupo) {
            final isSelected = _selectedGrupoPrimarioNome == grupo['nome'];
            return ChoiceChip(
              label: Text(grupo['nome']),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedGrupoPrimarioNome = selected ? grupo['nome'] : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGruposSecundariosChips() {
    if (_isLoadingGruposMusculares) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grupos Musculares Secundários',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _gruposMusculares.map((grupo) {
            final isSelected = _selectedGruposSecundariosNomes.contains(
              grupo['nome'],
            );
            return FilterChip(
              label: Text(grupo['nome']),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedGruposSecundariosNomes.add(grupo['nome']);
                  } else {
                    _selectedGruposSecundariosNomes.remove(grupo['nome']);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTipoExercicioChips() {
    if (_isLoadingTiposExercicio) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Exercício*',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tiposExercicio.map((tipo) {
            final isSelected = _selectedTipoExercicioNome == tipo['nome'];
            return ChoiceChip(
              label: Text(tipo['nome']),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedTipoExercicioNome = selected ? tipo['nome'] : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDeletarExercicioDropdown() {
    if (_isLoadingExercicios) {
      return const Center(child: Text("Carregando exercícios..."));
    }
    return DropdownButtonFormField<int>(
      value: _selectedExercicioParaDeletarId,
      hint: const Text('Selecione o exercício para deletar'),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Exercício',
      ),
      items: _exercicios.map((exercicio) {
        return DropdownMenuItem<int>(
          value: exercicio['id'],
          child: Text(exercicio['nome']),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() => _selectedExercicioParaDeletarId = newValue);
      },
    );
  }

  Widget _buildListaExercicios() {
    if (_isLoadingExercicios) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_exercicios.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum exercício cadastrado',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: _exercicios.map((exercicio) {
        final gruposSecundarios =
            (exercicio['grupos_musculares_secundarios'] as List?)?.join(', ') ??
            '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercicio['nome'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Equipamento: ${exercicio['equipamento']}'),
                Text('Grupo Primário: ${exercicio['grupo_muscular_primario']}'),
                if (gruposSecundarios.isNotEmpty)
                  Text('Grupos Secundários: $gruposSecundarios'),
                Text('Tipo: ${exercicio['tipo_exercicio']}'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
