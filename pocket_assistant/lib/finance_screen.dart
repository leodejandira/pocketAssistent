import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  // Controladores para os campos de texto
  final _nomeController = TextEditingController();
  final _valorController = TextEditingController();
  final _novaCategoriaController = TextEditingController();

  // Variáveis de estado para os formulários
  int? _selectedTipoId;
  int? _selectedTipoParaDeletarId;
  bool _isLoadingTipos = true;
  List<Map<String, dynamic>> _tipos = [];
  final List<bool> _tipoLancamentoSelections = [
    true,
    false,
  ]; // [Débito, Crédito]

  // Dados para o gráfico
  List<GastoPorCategoria> _dadosGrafico = [];
  bool _isLoadingGrafico = false;

  @override
  void initState() {
    super.initState();
    // Carrega as categorias do banco de dados assim que a tela inicia
    _carregarTipos();
  }

  @override
  void dispose() {
    // Limpa os controladores quando a tela for descartada
    _nomeController.dispose();
    _valorController.dispose();
    _novaCategoriaController.dispose();
    super.dispose();
  }

  // Função para buscar as categorias da tabela 'tipo' no Supabase
  Future<void> _carregarTipos() async {
    setState(() {
      _isLoadingTipos = true;
    });
    try {
      final data = await Supabase.instance.client.from('tipo').select();
      setState(() {
        _tipos = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      _showSnackBar('Erro ao carregar categorias', isError: true);
    } finally {
      setState(() {
        _isLoadingTipos = false;
      });
    }
  }

  // Função para carregar dados do gráfico (gastos do mês atual)
  Future<void> _carregarDadosGrafico() async {
    setState(() {
      _isLoadingGrafico = true;
    });

    try {
      // Obtém o primeiro e último dia do mês atual
      final now = DateTime.now();
      final primeiroDiaMes = DateTime(now.year, now.month, 1);
      final ultimoDiaMes = DateTime(now.year, now.month + 1, 0);

      // Busca os registros financeiros do mês atual (apenas débitos/gastos)
      final response = await Supabase.instance.client
          .from('financ_regis')
          .select('valor, tipo_id, tipo(nome_tipo)')
          .lt('valor', 0) // Apenas gastos (valores negativos)
          .gte('data_registro', primeiroDiaMes.toIso8601String())
          .lte('data_registro', ultimoDiaMes.toIso8601String());

      // Agrupa os gastos por categoria
      final Map<String, double> gastosPorCategoria = {};

      for (final registro in response) {
        final tipoNome = registro['tipo']['nome_tipo'] as String;
        final valor = (registro['valor'] as num)
            .toDouble()
            .abs(); // Converte para positivo

        gastosPorCategoria.update(
          tipoNome,
          (existing) => existing + valor,
          ifAbsent: () => valor,
        );
      }

      // Prepara os dados para o gráfico
      final List<GastoPorCategoria> dadosGrafico = [];
      gastosPorCategoria.forEach((categoria, total) {
        dadosGrafico.add(GastoPorCategoria(categoria, total));
      });

      // Ordena por valor (maior para menor)
      dadosGrafico.sort((a, b) => b.valor.compareTo(a.valor));

      setState(() {
        _dadosGrafico = dadosGrafico;
      });
    } catch (e) {
      _showSnackBar('Erro ao carregar dados do gráfico: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingGrafico = false;
      });
    }
  }

  // Função para salvar um novo registro financeiro
  Future<void> _salvarRegistro() async {
    final nome = _nomeController.text;
    final valorStr = _valorController.text.replaceAll(',', '.');
    final valor = double.tryParse(valorStr);
    final isDebito = _tipoLancamentoSelections[0];

    // Validação dos campos
    if (nome.isEmpty ||
        valor == null ||
        valor == 0.0 ||
        _selectedTipoId == null) {
      _showSnackBar('Preencha todos os campos corretamente.', isError: true);
      return;
    }

    // Define o valor como negativo se for débito
    final valorFinal = isDebito ? -valor.abs() : valor.abs();

    try {
      await Supabase.instance.client.from('financ_regis').insert({
        'nome': nome,
        'valor': valorFinal,
        'tipo_id': _selectedTipoId, // Salva o ID da categoria
        'data_registro': DateTime.now().toIso8601String(),
      });

      _showSnackBar('Registro salvo com sucesso!');
      // Limpa os campos após o sucesso
      _nomeController.clear();
      _valorController.clear();
      setState(() {
        _selectedTipoId = null;
      });
    } catch (e) {
      _showSnackBar('Erro ao salvar o registro: $e', isError: true);
    }
  }

  // Função para cadastrar uma nova categoria
  Future<void> _cadastrarCategoria() async {
    final nomeCategoria = _novaCategoriaController.text.trim();
    if (nomeCategoria.isEmpty) {
      _showSnackBar('O nome da categoria não pode ser vazio.', isError: true);
      return;
    }

    try {
      await Supabase.instance.client.from('tipo').insert({
        'nome_tipo': nomeCategoria,
      });
      _showSnackBar('Categoria "$nomeCategoria" cadastrada com sucesso!');
      _novaCategoriaController.clear();
      _carregarTipos(); // Recarrega a lista de categorias para atualizar os dropdowns
    } catch (e) {
      _showSnackBar('Erro ao cadastrar categoria: $e', isError: true);
    }
  }

  // Função para deletar uma categoria existente
  Future<void> _deletarCategoria() async {
    if (_selectedTipoParaDeletarId == null) {
      _showSnackBar('Selecione uma categoria para deletar.', isError: true);
      return;
    }

    // Confirmação do usuário
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja deletar esta categoria? Esta ação não pode ser desfeita.',
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
          .from('tipo')
          .delete()
          .eq('id', _selectedTipoParaDeletarId!);

      _showSnackBar('Categoria deletada com sucesso!');
      setState(() {
        _selectedTipoParaDeletarId = null;
      });
      _carregarTipos(); // Recarrega a lista de categorias
    } catch (e) {
      // Trata erro de chave estrangeira (se a categoria estiver em uso)
      if (e.toString().contains('violates foreign key constraint')) {
        _showSnackBar(
          'Erro: Categoria está em uso por um ou mais registros.',
          isError: true,
        );
      } else {
        _showSnackBar('Erro ao deletar categoria: $e', isError: true);
      }
    }
  }

  // Helper para mostrar SnackBars de feedback
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance'),
          backgroundColor: const Color.fromARGB(255, 16, 151, 185),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lançamentos'),
              Tab(text: 'Registros'),
              Tab(text: 'Gráfico de gastos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ABA 1 - LANÇAMENTOS E CATEGORIAS
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Seção: Registrar Gasto ---
                  _buildSectionTitle('Registrar Gasto'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _valorController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTipoDropdown(), // Dropdown de categorias
                  const SizedBox(height: 16),
                  ToggleButtons(
                    isSelected: _tipoLancamentoSelections,
                    onPressed: (index) {
                      setState(() {
                        for (
                          int i = 0;
                          i < _tipoLancamentoSelections.length;
                          i++
                        ) {
                          _tipoLancamentoSelections[i] = i == index;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    constraints: BoxConstraints(
                      minWidth: (MediaQuery.of(context).size.width - 40) / 2,
                      minHeight: 40,
                    ),
                    children: const [Text('Débito'), Text('Crédito')],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _salvarRegistro,
                    icon: const Icon(Icons.send),
                    label: const Text('Registrar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                  const Divider(height: 48, thickness: 1),

                  // --- Seção: Cadastrar Nova Categoria ---
                  _buildSectionTitle('Cadastrar Nova Categoria'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _novaCategoriaController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Categoria',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _cadastrarCategoria,
                    icon: const Icon(Icons.add),
                    label: const Text('Salvar Categoria'),
                  ),

                  const Divider(height: 48, thickness: 1),

                  // --- Seção: Deletar Categoria ---
                  _buildSectionTitle('Deletar Categoria'),
                  const SizedBox(height: 16),
                  _buildDeletarDropdown(), // Dropdown para deletar
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _deletarCategoria,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Deletar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const Center(child: Text('Lista de Registros')),
            // ABA 3 - GRÁFICO DE GASTOS
            _buildGraficoGastos(),
          ],
        ),
      ),
    );
  }

  // Widget para a aba do gráfico de gastos
  Widget _buildGraficoGastos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Gastos do Mês Atual - ${_getMesAtual()}'),
          const SizedBox(height: 16),

          // Botão para atualizar o gráfico
          ElevatedButton.icon(
            onPressed: _carregarDadosGrafico,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar Gráfico'),
          ),

          const SizedBox(height: 24),

          if (_isLoadingGrafico)
            const Center(child: CircularProgressIndicator())
          else if (_dadosGrafico.isEmpty)
            const Center(
              child: Text(
                'Nenhum gasto encontrado para o mês atual',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          else
            Column(
              children: [
                // Gráfico de barras
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${_dadosGrafico[groupIndex].categoria}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: 'R\$${rod.toY.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.yellow),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < _dadosGrafico.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _dadosGrafico[index].categoria,
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                'R\$${value.toInt()}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _dadosGrafico.asMap().entries.map((entry) {
                        final index = entry.key;
                        final gasto = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: gasto.valor,
                              color: _getColorForIndex(index),
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Legenda dos gastos
                ..._buildLegendaGastos(),
              ],
            ),
        ],
      ),
    );
  }

  // Função para obter o valor máximo do eixo Y
  double _getMaxY() {
    if (_dadosGrafico.isEmpty) return 100;
    final maxValor = _dadosGrafico
        .map((e) => e.valor)
        .reduce((a, b) => a > b ? a : b);
    return (maxValor * 1.2).ceilToDouble(); // Adiciona 20% de margem
  }

  // Função para obter o nome do mês atual
  String _getMesAtual() {
    final now = DateTime.now();
    final meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return meses[now.month - 1];
  }

  // Widget para construir a legenda dos gastos
  List<Widget> _buildLegendaGastos() {
    return [
      _buildSectionTitle('Resumo dos Gastos'),
      const SizedBox(height: 16),
      ..._dadosGrafico.asMap().entries.map((entry) {
        final index = entry.key;
        final gasto = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getColorForIndex(index),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      gasto.categoria,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    'R\$${gasto.valor.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    ];
  }

  // Função auxiliar para obter cor baseada no índice
  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
    ];
    return colors[index % colors.length];
  }

  // Widget auxiliar para os títulos das seções
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  // Widget para o Dropdown de seleção de tipo/categoria
  Widget _buildTipoDropdown() {
    if (_isLoadingTipos) {
      return const Center(child: CircularProgressIndicator());
    }
    return DropdownButtonFormField<int>(
      value: _selectedTipoId,
      hint: const Text('Selecione o Tipo'),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Tipo',
      ),
      items: _tipos.map((tipo) {
        return DropdownMenuItem<int>(
          value: tipo['id'],
          child: Text(tipo['nome_tipo']),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedTipoId = newValue;
        });
      },
    );
  }

  // Widget para o Dropdown de deleção de tipo/categoria
  Widget _buildDeletarDropdown() {
    if (_isLoadingTipos) {
      return const Center(child: Text("Carregando categorias..."));
    }
    return DropdownButtonFormField<int>(
      value: _selectedTipoParaDeletarId,
      hint: const Text('Selecione para deletar'),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Categoria',
      ),
      items: _tipos.map((tipo) {
        return DropdownMenuItem<int>(
          value: tipo['id'],
          child: Text(tipo['nome_tipo']),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedTipoParaDeletarId = newValue;
        });
      },
    );
  }
}

// Classe para representar os dados do gráfico
class GastoPorCategoria {
  final String categoria;
  final double valor;

  GastoPorCategoria(this.categoria, this.valor);
}
