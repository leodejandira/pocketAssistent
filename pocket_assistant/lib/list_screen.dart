import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListMainScreen extends StatefulWidget {
  const ListMainScreen({super.key});

  @override
  State<ListMainScreen> createState() => _ListMainScreenState();
}

class _ListMainScreenState extends State<ListMainScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Listas'),
          backgroundColor: const Color(0xFF06B6D4),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Visualizar Listas'),
              Tab(text: 'Gerenciar Itens'),
              Tab(text: 'Criar Lista'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ViewListsScreen(),
            ManageItemsScreen(),
            CreateListScreen(),
          ],
        ),
      ),
    );
  }
}

// TELA 1: Visualizar Listas
class ViewListsScreen extends StatefulWidget {
  const ViewListsScreen({super.key});

  @override
  State<ViewListsScreen> createState() => _ViewListsScreenState();
}

class _ViewListsScreenState extends State<ViewListsScreen> {
  List<Map<String, dynamic>> _listas = [];
  List<Map<String, dynamic>> _itens = [];
  int? _selectedListaId;
  Map<String, dynamic>? _selectedLista;

  @override
  void initState() {
    super.initState();
    _carregarListas();
  }

  Future<void> _carregarListas() async {
    try {
      final listasData = await Supabase.instance.client
          .from('listas')
          .select('*')
          .order('data_criacao', ascending: false);

      setState(() {
        _listas = List<Map<String, dynamic>>.from(listasData);
      });
    } catch (e) {
      _showSnackBar('Erro ao carregar listas: $e', isError: true);
    }
  }

  Future<void> _carregarItensLista(int listaId) async {
    try {
      final lista = _listas.firstWhere((lista) => lista['id'] == listaId);
      final query = Supabase.instance.client
          .from('itens_lista')
          .select('*')
          .eq('lista_id', listaId);

      // Ordenação: se a lista tem data de entrega, ordena pela data mais próxima
      if (lista['tem_data_entrega'] == true) {
        query.order('data_entrega', ascending: true);
      } else {
        query.order('data_criacao', ascending: false);
      }

      final itensData = await query;

      setState(() {
        _itens = List<Map<String, dynamic>>.from(itensData);
        _selectedListaId = listaId;
        _selectedLista = lista;
      });
    } catch (e) {
      _showSnackBar('Erro ao carregar itens: $e', isError: true);
    }
  }

  Future<void> _marcarComoConcluido(int itemId, bool concluido) async {
    try {
      await Supabase.instance.client
          .from('itens_lista')
          .update({
            'concluido': concluido,
            'data_conclusao': concluido
                ? DateTime.now().toIso8601String()
                : null,
          })
          .eq('id', itemId);

      if (_selectedListaId != null) {
        _carregarItensLista(_selectedListaId!);
      }
    } catch (e) {
      _showSnackBar('Erro ao atualizar item: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildComplexidadeIcon(String? complexidade) {
    if (complexidade == null) return const SizedBox.shrink();

    Color color;
    switch (complexidade) {
      case 'alta':
        color = Colors.red;
        break;
      case 'media':
        color = Colors.orange;
        break;
      case 'baixa':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Icon(Icons.circle, color: color, size: 12),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Menu suspenso para selecionar lista
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<int>(
            value: _selectedListaId,
            decoration: const InputDecoration(
              labelText: 'Selecione uma lista',
              border: OutlineInputBorder(),
            ),
            items: _listas.map((lista) {
              return DropdownMenuItem<int>(
                value: lista['id'],
                child: Text(lista['nome']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                _carregarItensLista(newValue);
              }
            },
          ),
        ),

        // Lista de itens
        Expanded(
          child: _selectedListaId == null
              ? const Center(
                  child: Text(
                    'Selecione uma lista para visualizar os itens',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : _itens.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum item encontrado nesta lista',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _itens.length,
                  itemBuilder: (context, index) {
                    final item = _itens[index];
                    final isConcluido = item['concluido'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isConcluido ? Colors.grey[100] : null,
                      child: ListTile(
                        leading: Checkbox(
                          value: isConcluido,
                          onChanged: (value) {
                            _marcarComoConcluido(item['id'], value ?? false);
                          },
                        ),
                        title: Text(
                          item['nome_item'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: isConcluido
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: isConcluido ? Colors.grey : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item['data_entrega'] != null)
                              Text(
                                'Entrega: ${_formatDate(item['data_entrega'])}',
                                style: TextStyle(
                                  color: isConcluido ? Colors.grey : null,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedLista?['tem_nivel_complexidade'] ==
                                true)
                              _buildComplexidadeIcon(item['complexidade']),
                            const SizedBox(width: 8),
                            if (item['data_entrega'] != null)
                              Icon(
                                Icons.calendar_today,
                                color: isConcluido ? Colors.grey : Colors.blue,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// TELA 2: Gerenciar Itens
class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  final _nomeItemController = TextEditingController();
  List<Map<String, dynamic>> _listas = [];
  List<Map<String, dynamic>> _itens = [];
  int? _selectedListaAdicionar;
  int? _selectedListaDeletar;
  int? _selectedItemDeletar;
  String? _selectedComplexidade;
  DateTime? _selectedDataEntrega;

  final List<String> _complexidades = ['baixa', 'media', 'alta'];

  @override
  void initState() {
    super.initState();
    _carregarListas();
  }

  @override
  void dispose() {
    _nomeItemController.dispose();
    super.dispose();
  }

  Future<void> _carregarListas() async {
    try {
      final listasData = await Supabase.instance.client
          .from('listas')
          .select('*')
          .order('data_criacao', ascending: false);

      setState(() {
        _listas = List<Map<String, dynamic>>.from(listasData);
      });
    } catch (e) {
      _showSnackBar('Erro ao carregar listas: $e', isError: true);
    }
  }

  Future<void> _carregarItensPorLista(int listaId) async {
    try {
      final itensData = await Supabase.instance.client
          .from('itens_lista')
          .select('*')
          .eq('lista_id', listaId)
          .order('data_criacao', ascending: false);

      setState(() {
        _itens = List<Map<String, dynamic>>.from(itensData);
      });
    } catch (e) {
      _showSnackBar('Erro ao carregar itens: $e', isError: true);
    }
  }

  Future<void> _adicionarItem() async {
    if (_selectedListaAdicionar == null || _nomeItemController.text.isEmpty) {
      _showSnackBar(
        'Preencha nome do item e selecione uma lista',
        isError: true,
      );
      return;
    }

    final lista = _listas.firstWhere(
      (lista) => lista['id'] == _selectedListaAdicionar,
    );

    // Validações
    if (lista['tem_nivel_complexidade'] == true &&
        _selectedComplexidade == null) {
      _showSnackBar('Esta lista requer nível de complexidade', isError: true);
      return;
    }

    if (lista['tem_data_entrega'] == true && _selectedDataEntrega == null) {
      _showSnackBar('Esta lista requer data de entrega', isError: true);
      return;
    }

    try {
      await Supabase.instance.client.from('itens_lista').insert({
        'lista_id': _selectedListaAdicionar,
        'nome_item': _nomeItemController.text,
        'complexidade': _selectedComplexidade,
        'data_entrega': _selectedDataEntrega?.toIso8601String().split('T')[0],
        'data_criacao': DateTime.now().toIso8601String(),
      });

      _showSnackBar('Item adicionado com sucesso!');
      _nomeItemController.clear();
      setState(() {
        _selectedComplexidade = null;
        _selectedDataEntrega = null;
      });

      // Recarregar itens se estiver na mesma lista
      if (_selectedListaDeletar == _selectedListaAdicionar) {
        _carregarItensPorLista(_selectedListaAdicionar!);
      }
    } catch (e) {
      _showSnackBar('Erro ao adicionar item: $e', isError: true);
    }
  }

  Future<void> _deletarItem() async {
    if (_selectedItemDeletar == null) {
      _showSnackBar('Selecione um item para deletar', isError: true);
      return;
    }

    try {
      await Supabase.instance.client
          .from('itens_lista')
          .delete()
          .eq('id', _selectedItemDeletar!);

      _showSnackBar('Item deletado com sucesso!');
      if (_selectedListaDeletar != null) {
        _carregarItensPorLista(_selectedListaDeletar!);
      }
      setState(() {
        _selectedItemDeletar = null;
      });
    } catch (e) {
      _showSnackBar('Erro ao deletar item: $e', isError: true);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDataEntrega = picked;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Adicionar Item
          _buildSectionTitle('Adicionar Item à Lista'),
          const SizedBox(height: 16),

          TextField(
            controller: _nomeItemController,
            decoration: const InputDecoration(
              labelText: 'Nome do Item *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _selectedListaAdicionar,
            decoration: const InputDecoration(
              labelText: 'Selecionar Lista *',
              border: OutlineInputBorder(),
            ),
            items: _listas.map((lista) {
              return DropdownMenuItem<int>(
                value: lista['id'],
                child: Text(lista['nome']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedListaAdicionar = newValue;
                if (newValue != null) {
                  final lista = _listas.firstWhere(
                    (lista) => lista['id'] == newValue,
                  );
                  // Resetar campos opcionais se a lista não os suporta
                  if (lista['tem_nivel_complexidade'] != true) {
                    _selectedComplexidade = null;
                  }
                  if (lista['tem_data_entrega'] != true) {
                    _selectedDataEntrega = null;
                  }
                }
              });
            },
          ),
          const SizedBox(height: 16),

          // Complexidade (condicional)
          if (_selectedListaAdicionar != null)
            _listas.firstWhere(
                      (lista) => lista['id'] == _selectedListaAdicionar,
                    )['tem_nivel_complexidade'] ==
                    true
                ? Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedComplexidade,
                        decoration: const InputDecoration(
                          labelText: 'Nível de Complexidade *',
                          border: OutlineInputBorder(),
                        ),
                        items: _complexidades.map((complexidade) {
                          return DropdownMenuItem<String>(
                            value: complexidade,
                            child: Text(complexidade),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedComplexidade = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  )
                : const SizedBox(),

          // Data de entrega (condicional)
          if (_selectedListaAdicionar != null)
            _listas.firstWhere(
                      (lista) => lista['id'] == _selectedListaAdicionar,
                    )['tem_data_entrega'] ==
                    true
                ? Column(
                    children: [
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data de Entrega *',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDataEntrega != null
                                    ? '${_selectedDataEntrega!.day}/${_selectedDataEntrega!.month}/${_selectedDataEntrega!.year}'
                                    : 'Selecione a data',
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  )
                : const SizedBox(),

          ElevatedButton(
            onPressed: _adicionarItem,
            child: const Text('Adicionar Item'),
          ),

          const Divider(height: 48, thickness: 2),

          // Deletar Item
          _buildSectionTitle('Deletar Item da Lista'),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _selectedListaDeletar,
            decoration: const InputDecoration(
              labelText: 'Selecionar Lista',
              border: OutlineInputBorder(),
            ),
            items: _listas.map((lista) {
              return DropdownMenuItem<int>(
                value: lista['id'],
                child: Text(lista['nome']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedListaDeletar = newValue;
                _selectedItemDeletar = null;
                if (newValue != null) {
                  _carregarItensPorLista(newValue);
                } else {
                  _itens.clear();
                }
              });
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _selectedItemDeletar,
            decoration: const InputDecoration(
              labelText: 'Selecionar Item',
              border: OutlineInputBorder(),
            ),
            items: _itens.map((item) {
              return DropdownMenuItem<int>(
                value: item['id'],
                child: Text(item['nome_item']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedItemDeletar = newValue;
              });
            },
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _deletarItem,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deletar Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF06B6D4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF06B6D4), width: 1),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF06B6D4),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// TELA 3: Criar Lista
class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _nomeListaController = TextEditingController();
  bool _temDataEntrega = false;
  bool _temNivelComplexidade = false;

  @override
  void dispose() {
    _nomeListaController.dispose();
    super.dispose();
  }

  Future<void> _criarLista() async {
    if (_nomeListaController.text.isEmpty) {
      _showSnackBar('Digite o nome da lista', isError: true);
      return;
    }

    try {
      await Supabase.instance.client.from('listas').insert({
        'nome': _nomeListaController.text,
        'tem_data_entrega': _temDataEntrega,
        'tem_nivel_complexidade': _temNivelComplexidade,
        'data_criacao': DateTime.now().toIso8601String(),
      });

      _showSnackBar('Lista criada com sucesso!');
      _nomeListaController.clear();
      setState(() {
        _temDataEntrega = false;
        _temNivelComplexidade = false;
      });
    } catch (e) {
      _showSnackBar('Erro ao criar lista: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Criar Lista
          _buildSectionTitle('Criar Nova Lista'),
          const SizedBox(height: 16),

          TextField(
            controller: _nomeListaController,
            decoration: const InputDecoration(
              labelText: 'Nome da lista *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Tem data de entrega'),
            value: _temDataEntrega,
            onChanged: (value) {
              setState(() {
                _temDataEntrega = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Tem nível de complexidade'),
            value: _temNivelComplexidade,
            onChanged: (value) {
              setState(() {
                _temNivelComplexidade = value;
              });
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _criarLista,
            child: const Text('Criar Lista'),
          ),

          const Divider(height: 48, thickness: 2),

          // Deletar Lista
          const _DeletarListaWidget(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF06B6D4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF06B6D4), width: 1),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF06B6D4),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Widget para deletar lista
class _DeletarListaWidget extends StatefulWidget {
  const _DeletarListaWidget();

  @override
  State<_DeletarListaWidget> createState() => _DeletarListaWidgetState();
}

class _DeletarListaWidgetState extends State<_DeletarListaWidget> {
  List<Map<String, dynamic>> _listas = [];
  int? _selectedListaId;

  @override
  void initState() {
    super.initState();
    _carregarListas();
  }

  Future<void> _carregarListas() async {
    try {
      final listasData = await Supabase.instance.client
          .from('listas')
          .select('id, nome')
          .order('data_criacao', ascending: false);

      setState(() {
        _listas = List<Map<String, dynamic>>.from(listasData);
      });
    } catch (e) {
      _showSnackBar('Erro ao carregar listas: $e', isError: true);
    }
  }

  Future<void> _deletarLista() async {
    if (_selectedListaId == null) {
      _showSnackBar('Selecione uma lista para deletar', isError: true);
      return;
    }

    try {
      await Supabase.instance.client
          .from('listas')
          .delete()
          .eq('id', _selectedListaId!);

      _showSnackBar('Lista deletada com sucesso!');
      _carregarListas();
      setState(() {
        _selectedListaId = null;
      });
    } catch (e) {
      _showSnackBar('Erro ao deletar lista: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Deletar Lista'),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _selectedListaId,
          decoration: const InputDecoration(
            labelText: 'Selecione a lista',
            border: OutlineInputBorder(),
          ),
          items: _listas.map((lista) {
            return DropdownMenuItem<int>(
              value: lista['id'],
              child: Text(lista['nome']),
            );
          }).toList(),
          onChanged: (int? newValue) {
            setState(() {
              _selectedListaId = newValue;
            });
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _deletarLista,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Deletar Lista'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF06B6D4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF06B6D4), width: 1),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF06B6D4),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
