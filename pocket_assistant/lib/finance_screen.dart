import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
              Tab(text: 'Gráficos'),
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
            const Center(child: Text('Gráficos e Relatórios')),
          ],
        ),
      ),
    );
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
