import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  String _selectType = 'A';
  final List<String> _tipos = ['A', 'B'];

  ////////////Trial
  void _testarConexao() async {
    try {
      print('🔧 Testando conexão com Supabase...');
      final response = await Supabase.instance.client
          .from('financ_regis')
          .select()
          .limit(1);
      print('✅ Conexão funcionando! Resposta: $response');
    } catch (e) {
      print('❌ Erro na conexão: $e');
    }
  }

  void _salvarRegistro() async {
    try {
      // 1. Pegar dados dos campos
      final nome = _nomeController.text;
      final valor = double.tryParse(_valorController.text) ?? 0.0;
      final tipo = _selectType;
      final data = DateTime.now();

      // 2. Validar dados
      if (nome.isEmpty || valor == 0.0) {
        print('Preencha todos os campos!');
        return;
      }

      // 3. Inserir no Supabase (AGORA DE VERDADE!)
      await Supabase.instance.client.from('financ_regis').insert({
        'nome': nome,
        'valor': valor,
        'tipo': tipo,
        'data_registro': data.toIso8601String(),
      });

      // 4. Limpar campos e mostrar sucesso
      _nomeController.clear();
      _valorController.clear();
      setState(() {
        _selectType = 'A';
      });

      print('✅ Registro salvo no SUPABASE com sucesso!');
    } catch (e) {
      print('❌ Erro ao salvar no Supabase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Número de abas
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Finance',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color.fromARGB(255, 16, 151, 185),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Inserir'),
              Tab(text: 'Registros'),
              Tab(text: 'Gráficos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ABA 1 - INSERIR
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Campo 1: Nome do Lançamento
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Lançamento',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Campo 2: Valor
                  TextField(
                    controller: _valorController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Campo 3: Tipo do Lançamento (Dropdown)
                  DropdownButtonFormField<String>(
                    value: _selectType,
                    items: _tipos.map((String tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text('Tipo $tipo'),
                      );
                    }).toList(),
                    onChanged: (String? novoValor) {
                      setState(() {
                        _selectType = novoValor!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Tipo do Lançamento',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botão para salvar
                  ElevatedButton(
                    onPressed: _salvarRegistro,
                    child: const Text('Salvar Registro'),
                  ),

                  ///////////Trial
                  ElevatedButton(
                    onPressed: _testarConexao,
                    child: Text('Testar Conexão Supabase'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            // ABA 2 - REGISTROS
            const Center(child: Text('Lista de Registros')),

            // ABA 3 - GRÁFICOS
            const Center(child: Text('Gráficos e Relatórios')),
          ],
        ),
      ),
    );
  }
}
