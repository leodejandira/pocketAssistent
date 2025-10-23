import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicinalScreen extends StatefulWidget {
  const MedicinalScreen({super.key});

  @override
  State<MedicinalScreen> createState() => _MedicinalScreenState();
}

class _MedicinalScreenState extends State<MedicinalScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medicinal'),
          backgroundColor: const Color.fromARGB(255, 16, 151, 185),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Registros'),
              Tab(text: 'Controle Diário'),
              Tab(text: 'Perfil Paciente'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MedicinalRegistrosScreen(),
            MedicinalGeralScreen(),
            MedicinalPerfilScreen(),
          ],
        ),
      ),
    );
  }
}

// TELA 1: REGISTROS (antigo medicinal.dart)
class MedicinalRegistrosScreen extends StatefulWidget {
  const MedicinalRegistrosScreen({super.key});

  @override
  State<MedicinalRegistrosScreen> createState() =>
      _MedicinalRegistrosScreenState();
}

class _MedicinalRegistrosScreenState extends State<MedicinalRegistrosScreen> {
  // Controladores para FORMULÁRIO 1 - Lembrete de Exame
  final _nomeLembreteController = TextEditingController();
  final _motivoLembreteController = TextEditingController();

  // Controladores para FORMULÁRIO 2 - Agendamento
  final _nomeAgendamentoController = TextEditingController();
  final _motivoAgendamentoController = TextEditingController();
  final _clinicaController = TextEditingController();
  final _medicoAgendamentoController = TextEditingController();

  // Controladores para FORMULÁRIO 3 - Resultado de Exames
  final _nomeResultadoController = TextEditingController();
  final _clinicaResultadoController = TextEditingController();
  final _medicoResultadoController = TextEditingController();
  final _motivoResultadoController = TextEditingController();
  final _pontoAtencaoController = TextEditingController();
  final _linkLaudoController = TextEditingController();

  // Controladores para FORMULÁRIO 4 - Medicamentos
  final _nomeMedicamentoController = TextEditingController();
  final _motivoMedicamentoController = TextEditingController();
  final _medicoPrescritorController = TextEditingController();
  final _duracaoController = TextEditingController();
  final _intervaloController = TextEditingController();

  // Controladores para FORMULÁRIO 5 - Condições Médicas
  final _tipoCondicaoController = TextEditingController();
  final _descricaoCondicaoController = TextEditingController();
  final _observacoesCondicaoController = TextEditingController();

  // Controladores para FORMULÁRIO 6 - Vacinas
  final _nomeVacinaController = TextEditingController();
  final _doseVacinaController = TextEditingController();
  final _localAplicacaoController = TextEditingController();
  final _loteVacinaController = TextEditingController();

  // Variáveis de estado
  bool _isExame = true;
  int? _selectedPacienteLembrete;
  int? _selectedPacienteAgendamento;
  int? _selectedPacienteResultado;
  int? _selectedPacienteMedicamento;
  int? _selectedPacienteCondicao;
  int? _selectedPacienteVacina;
  int? _selectedStatusResultado;
  String? _selectedGravidadeCondicao;
  DateTime? _dataAgendamento;
  DateTime? _dataExame;
  DateTime? _dataResultado;
  DateTime? _dataDiagnosticoCondicao;
  DateTime? _dataAplicacaoVacina;
  DateTime? _proximaDoseVacina;

  // Listas do banco
  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _statusExames = [];
  List<Map<String, dynamic>> _statusLembretes = [];

  // Horários pré-definidos
  final List<String> _horarios = [
    '07:00',
    '07:30',
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
  ];
  String? _selectedHorario;

  // Opções de gravidade
  final List<String> _gravidades = ['Leve', 'Moderada', 'Grave', 'Crítica'];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeLembreteController.dispose();
    _motivoLembreteController.dispose();
    _nomeAgendamentoController.dispose();
    _motivoAgendamentoController.dispose();
    _clinicaController.dispose();
    _medicoAgendamentoController.dispose();
    _nomeResultadoController.dispose();
    _clinicaResultadoController.dispose();
    _medicoResultadoController.dispose();
    _motivoResultadoController.dispose();
    _pontoAtencaoController.dispose();
    _linkLaudoController.dispose();
    _nomeMedicamentoController.dispose();
    _motivoMedicamentoController.dispose();
    _medicoPrescritorController.dispose();
    _duracaoController.dispose();
    _intervaloController.dispose();
    _tipoCondicaoController.dispose();
    _descricaoCondicaoController.dispose();
    _observacoesCondicaoController.dispose();
    _nomeVacinaController.dispose();
    _doseVacinaController.dispose();
    _localAplicacaoController.dispose();
    _loteVacinaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final pacientesData = await Supabase.instance.client
          .from('paciente')
          .select('id, nome');
      if (mounted) {
        setState(() {
          _pacientes = List<Map<String, dynamic>>.from(pacientesData);
        });
      }

      final statusExamesData = await Supabase.instance.client
          .from('exames_status')
          .select('id, nome');
      if (mounted) {
        setState(() {
          _statusExames = List<Map<String, dynamic>>.from(statusExamesData);
        });
      }

      final statusLembretesData = await Supabase.instance.client
          .from('status')
          .select('id, nome');
      if (mounted) {
        setState(() {
          _statusLembretes = List<Map<String, dynamic>>.from(
            statusLembretesData,
          );
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao carregar dados: $e', isError: true);
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _salvarLembrete() async {
    if (_selectedPacienteLembrete == null ||
        _nomeLembreteController.text.isEmpty) {
      _showSnackBar('Preencha paciente e nome do exame', isError: true);
      return;
    }

    try {
      final statusPendente = _statusLembretes.firstWhere(
        (status) => status['nome'] == 'pendente',
        orElse: () => {'id': 1},
      );

      await Supabase.instance.client.from('exames_lembrete').insert({
        'nome_exame': _nomeLembreteController.text,
        'motivo': _motivoLembreteController.text,
        'status_id': statusPendente['id'],
        'paciente_id': _selectedPacienteLembrete,
        'data_registro': DateTime.now().toIso8601String(),
      });

      _showSnackBar('Lembrete salvo com sucesso!');
      _nomeLembreteController.clear();
      _motivoLembreteController.clear();
      if (mounted) {
        setState(() {
          _selectedPacienteLembrete = null;
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao salvar lembrete: $e', isError: true);
    }
  }

  Future<void> _salvarAgendamento() async {
    if (_selectedPacienteAgendamento == null ||
        _nomeAgendamentoController.text.isEmpty ||
        _dataAgendamento == null ||
        _selectedHorario == null) {
      _showSnackBar('Preencha todos os campos obrigatórios', isError: true);
      return;
    }

    try {
      final lembretes = await Supabase.instance.client
          .from('exames_lembrete')
          .select('id, status_id')
          .eq('nome_exame', _nomeAgendamentoController.text)
          .eq('paciente_id', _selectedPacienteAgendamento!);

      if (lembretes.isNotEmpty) {
        final statusAgendado = _statusLembretes.firstWhere(
          (status) => status['nome'] == 'agendado',
          orElse: () => {'id': 2},
        );

        for (final lembrete in lembretes) {
          await Supabase.instance.client
              .from('exames_lembrete')
              .update({'status_id': statusAgendado['id']})
              .eq('id', lembrete['id']);
        }
      }

      if (_isExame) {
        await Supabase.instance.client.from('exames_agendado').insert({
          'nome_exame_consulta': _nomeAgendamentoController.text,
          'paciente_id': _selectedPacienteAgendamento,
          'clinica_hospital': _clinicaController.text,
          'motivo': _motivoAgendamentoController.text,
          'data_agendado': _dataAgendamento!.toIso8601String().split('T')[0],
          'horario': _selectedHorario,
          'data_registro': DateTime.now().toIso8601String(),
        });
      } else {
        await Supabase.instance.client.from('consultas').insert({
          'paciente_id': _selectedPacienteAgendamento,
          'medico': _medicoAgendamentoController.text,
          'especialidade': _nomeAgendamentoController.text,
          'data_consulta': _dataAgendamento!.toIso8601String().split('T')[0],
          'horario': _selectedHorario!,
          'local_consulta': _clinicaController.text,
          'motivo': _motivoAgendamentoController.text,
          'data_registro': DateTime.now().toIso8601String(),
        });
      }

      _showSnackBar('Agendamento salvo com sucesso!');
      _nomeAgendamentoController.clear();
      _motivoAgendamentoController.clear();
      _clinicaController.clear();
      _medicoAgendamentoController.clear();
      if (mounted) {
        setState(() {
          _selectedPacienteAgendamento = null;
          _dataAgendamento = null;
          _selectedHorario = null;
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao salvar agendamento: $e', isError: true);
    }
  }

  Future<void> _salvarResultado() async {
    if (_selectedPacienteResultado == null ||
        _nomeResultadoController.text.isEmpty ||
        _dataExame == null ||
        _selectedStatusResultado == null) {
      _showSnackBar('Preencha todos os campos obrigatórios', isError: true);
      return;
    }

    try {
      await Supabase.instance.client.from('resultado_exames').insert({
        'nome_exame': _nomeResultadoController.text,
        'paciente_id': _selectedPacienteResultado,
        'motivo': _motivoResultadoController.text,
        'data_exame': _dataExame!.toIso8601String().split('T')[0],
        'data_resultado': _dataResultado?.toIso8601String().split('T')[0],
        'exames_status_id': _selectedStatusResultado,
        'ponto_atencao': _pontoAtencaoController.text,
        'link_laudo_drive': _linkLaudoController.text,
        'clinica_realizada': _clinicaResultadoController.text,
        'nome_medico': _medicoResultadoController.text,
        'data_registro': DateTime.now().toIso8601String(),
      });

      _showSnackBar('Resultado salvo com sucesso!');
      _nomeResultadoController.clear();
      _clinicaResultadoController.clear();
      _medicoResultadoController.clear();
      _motivoResultadoController.clear();
      _pontoAtencaoController.clear();
      _linkLaudoController.clear();
      if (mounted) {
        setState(() {
          _selectedPacienteResultado = null;
          _selectedStatusResultado = null;
          _dataExame = null;
          _dataResultado = null;
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao salvar resultado: $e', isError: true);
    }
  }

  Future<void> _salvarMedicamento() async {
    if (_selectedPacienteMedicamento == null ||
        _nomeMedicamentoController.text.isEmpty ||
        _duracaoController.text.isEmpty) {
      _showSnackBar('Preencha todos os campos obrigatórios', isError: true);
      return;
    }

    try {
      await Supabase.instance.client.from('medicamentos').insert({
        'nome_medicamento': _nomeMedicamentoController.text,
        'motivo_medicamento': _motivoMedicamentoController.text,
        'paciente_id': _selectedPacienteMedicamento,
        'medico_prescrito': _medicoPrescritorController.text,
        'data_inicio': DateTime.now().toIso8601String().split('T')[0],
        'duracao_dias': int.tryParse(_duracaoController.text) ?? 7,
        'frequencia_diaria': 1,
        'intervalo_medicamento': _intervaloController.text.isNotEmpty
            ? _intervaloController.text
            : '1 vez ao dia',
        'data_registro': DateTime.now().toIso8601String(),
      });

      _showSnackBar('Medicamento salvo com sucesso!');
      _nomeMedicamentoController.clear();
      _motivoMedicamentoController.clear();
      _medicoPrescritorController.clear();
      _duracaoController.clear();
      _intervaloController.clear();
      if (mounted) {
        setState(() {
          _selectedPacienteMedicamento = null;
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao salvar medicamento: $e', isError: true);
    }
  }

  Future<void> _salvarCondicaoMedica() async {
    if (_selectedPacienteCondicao == null ||
        _tipoCondicaoController.text.isEmpty ||
        _descricaoCondicaoController.text.isEmpty ||
        _dataDiagnosticoCondicao == null) {
      _showSnackBar('Preencha todos os campos obrigatórios', isError: true);
      return;
    }

    try {
      await Supabase.instance.client.from('condicoes_medicas').insert({
        'paciente_id': _selectedPacienteCondicao,
        'tipo': _tipoCondicaoController.text,
        'descricao': _descricaoCondicaoController.text,
        'diagnostico_data': _dataDiagnosticoCondicao!.toIso8601String().split(
          'T',
        )[0],
        'gravidade': _selectedGravidadeCondicao,
        'observacoes': _observacoesCondicaoController.text,
        'data_registro': DateTime.now().toIso8601String(),
      });

      _showSnackBar('Condição médica salva com sucesso!');
      _tipoCondicaoController.clear();
      _descricaoCondicaoController.clear();
      _observacoesCondicaoController.clear();
      if (mounted) {
        setState(() {
          _selectedPacienteCondicao = null;
          _selectedGravidadeCondicao = null;
          _dataDiagnosticoCondicao = null;
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao salvar condição médica: $e', isError: true);
    }
  }

  Future<void> _salvarVacina() async {
    if (_selectedPacienteVacina == null ||
        _nomeVacinaController.text.isEmpty ||
        _doseVacinaController.text.isEmpty ||
        _dataAplicacaoVacina == null) {
      _showSnackBar('Preencha todos os campos obrigatórios', isError: true);
      return;
    }

    try {
      await Supabase.instance.client.from('vacinas').insert({
        'paciente_id': _selectedPacienteVacina,
        'nome_vacina': _nomeVacinaController.text,
        'dose': _doseVacinaController.text,
        'data_aplicacao': _dataAplicacaoVacina!.toIso8601String().split('T')[0],
        'proxima_dose': _proximaDoseVacina?.toIso8601String().split('T')[0],
        'local_aplicacao': _localAplicacaoController.text,
        'lote': _loteVacinaController.text,
        'data_registro': DateTime.now().toIso8601String(),
      });

      _showSnackBar('Vacina salva com sucesso!');
      _nomeVacinaController.clear();
      _doseVacinaController.clear();
      _localAplicacaoController.clear();
      _loteVacinaController.clear();
      if (mounted) {
        setState(() {
          _selectedPacienteVacina = null;
          _dataAplicacaoVacina = null;
          _proximaDoseVacina = null;
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao salvar vacina: $e', isError: true);
    }
  }

  // Helper para mostrar SnackBars de feedback com tratamento de erro
  void _showSnackBar(String message, {bool isError = false}) {
    try {
      // Verifica se o widget ainda está montado e se o context é válido
      if (mounted && context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.redAccent : Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        print('SnackBar não mostrado: $message');
      }
    } catch (e) {
      // Fallback seguro se algo der errado
      print('Erro ao mostrar SnackBar: $e - Mensagem: $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FORMULÁRIO 1: Registrar Lembrete de Exame
          _buildSectionTitle('1. Registrar Lembrete de Exame'),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _selectedPacienteLembrete,
            decoration: const InputDecoration(
              labelText: 'Paciente *',
              border: OutlineInputBorder(),
            ),
            items: _pacientes.map((paciente) {
              return DropdownMenuItem<int>(
                value: paciente['id'],
                child: Text(paciente['nome']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedPacienteLembrete = newValue;
              });
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nomeLembreteController,
            decoration: const InputDecoration(
              labelText: 'Nome do exame *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _motivoLembreteController,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _salvarLembrete,
            icon: const Icon(Icons.add_alert),
            label: const Text('Salvar Lembrete'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const Divider(height: 48, thickness: 2),

          // FORMULÁRIO 2: Registrar Exame/Consulta Agendado
          _buildSectionTitle('2. Registrar Exame/Consulta Agendado'),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Exame',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: _isExame,
                onChanged: (value) {
                  setState(() {
                    _isExame = value;
                  });
                },
              ),
              const Text(
                'Consulta',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _selectedPacienteAgendamento,
            decoration: const InputDecoration(
              labelText: 'Paciente *',
              border: OutlineInputBorder(),
            ),
            items: _pacientes.map((paciente) {
              return DropdownMenuItem<int>(
                value: paciente['id'],
                child: Text(paciente['nome']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedPacienteAgendamento = newValue;
              });
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nomeAgendamentoController,
            decoration: InputDecoration(
              labelText: _isExame ? 'Nome do exame *' : 'Especialidade *',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _motivoAgendamentoController,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _clinicaController,
            decoration: const InputDecoration(
              labelText: 'Clínica agendada *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          if (!_isExame) ...[
            TextField(
              controller: _medicoAgendamentoController,
              decoration: const InputDecoration(
                labelText: 'Nome médico *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () => _selectDate(context, (picked) {
                    setState(() {
                      _dataAgendamento = picked;
                    });
                  }),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data agendada *',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dataAgendamento != null
                              ? '${_dataAgendamento!.day}/${_dataAgendamento!.month}/${_dataAgendamento!.year}'
                              : 'Selecione a data',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedHorario,
                  decoration: const InputDecoration(
                    labelText: 'Horário *',
                    border: OutlineInputBorder(),
                  ),
                  items: _horarios.map((horario) {
                    return DropdownMenuItem<String>(
                      value: horario,
                      child: Text(horario),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedHorario = newValue;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _salvarAgendamento,
            icon: const Icon(Icons.calendar_today),
            label: Text(_isExame ? 'Agendar Exame' : 'Agendar Consulta'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const Divider(height: 48, thickness: 2),

          // FORMULÁRIO 3: Registrar Resultado de Exames
          _buildSectionTitle('3. Registrar Resultado de Exames'),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _selectedPacienteResultado,
            decoration: const InputDecoration(
              labelText: 'Paciente *',
              border: OutlineInputBorder(),
            ),
            items: _pacientes.map((paciente) {
              return DropdownMenuItem<int>(
                value: paciente['id'],
                child: Text(paciente['nome']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedPacienteResultado = newValue;
              });
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nomeResultadoController,
            decoration: const InputDecoration(
              labelText: 'Nome do exame *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _clinicaResultadoController,
            decoration: const InputDecoration(
              labelText: 'Clínica/Hospital realizado *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _medicoResultadoController,
            decoration: const InputDecoration(
              labelText: 'Nome médico',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _motivoResultadoController,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, (picked) {
                    setState(() {
                      _dataExame = picked;
                    });
                  }),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data do exame *',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dataExame != null
                              ? '${_dataExame!.day}/${_dataExame!.month}/${_dataExame!.year}'
                              : 'Selecione',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, (picked) {
                    setState(() {
                      _dataResultado = picked;
                    });
                  }),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data resultado',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dataResultado != null
                              ? '${_dataResultado!.day}/${_dataResultado!.month}/${_dataResultado!.year}'
                              : 'Selecione',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _selectedStatusResultado,
            decoration: const InputDecoration(
              labelText: 'Status do exame *',
              border: OutlineInputBorder(),
            ),
            items: _statusExames.map((status) {
              return DropdownMenuItem<int>(
                value: status['id'],
                child: Text(status['nome']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedStatusResultado = newValue;
              });
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _pontoAtencaoController,
            decoration: const InputDecoration(
              labelText: 'Ponto de atenção',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _linkLaudoController,
            decoration: const InputDecoration(
              labelText: 'Link do laudo (Google Drive)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _salvarResultado,
            icon: const Icon(Icons.assignment_turned_in),
            label: const Text('Salvar Resultado'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const Divider(height: 48, thickness: 2),

          // FORMULÁRIO 4: Registrar Medicamento
          _buildSectionTitle('4. Registrar Medicamento'),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _selectedPacienteMedicamento,
            decoration: const InputDecoration(
              labelText: 'Paciente *',
              border: OutlineInputBorder(),
            ),
            items: _pacientes.map((paciente) {
              return DropdownMenuItem<int>(
                value: paciente['id'],
                child: Text(paciente['nome']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedPacienteMedicamento = newValue;
              });
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nomeMedicamentoController,
            decoration: const InputDecoration(
              labelText: 'Nome da medicação *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _medicoPrescritorController,
            decoration: const InputDecoration(
              labelText: 'Médico que prescreveu',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _motivoMedicamentoController,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _duracaoController,
                  decoration: const InputDecoration(
                    labelText: 'Duração (dias) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _intervaloController,
                  decoration: const InputDecoration(
                    labelText: 'Intervalo (ex: 8h/8h)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _salvarMedicamento,
            icon: const Icon(Icons.medication),
            label: const Text('Salvar Medicamento'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const Divider(height: 48, thickness: 2),

          // FORMULÁRIO 5: Registrar Condição Médica
          _buildSectionTitle('5. Registrar Condição Médica'),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _selectedPacienteCondicao,
            decoration: const InputDecoration(
              labelText: 'Paciente *',
              border: OutlineInputBorder(),
            ),
            items: _pacientes.map((paciente) {
              return DropdownMenuItem<int>(
                value: paciente['id'],
                child: Text(paciente['nome']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedPacienteCondicao = newValue;
              });
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _tipoCondicaoController,
            decoration: const InputDecoration(
              labelText: 'Tipo da condição *',
              border: OutlineInputBorder(),
              hintText: 'Ex: Diabetes, Hipertensão, Asma...',
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _descricaoCondicaoController,
            decoration: const InputDecoration(
              labelText: 'Descrição *',
              border: OutlineInputBorder(),
              hintText: 'Descreva a condição médica...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, (picked) {
                    setState(() {
                      _dataDiagnosticoCondicao = picked;
                    });
                  }),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data do diagnóstico *',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dataDiagnosticoCondicao != null
                              ? '${_dataDiagnosticoCondicao!.day}/${_dataDiagnosticoCondicao!.month}/${_dataDiagnosticoCondicao!.year}'
                              : 'Selecione a data',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGravidadeCondicao,
                  decoration: const InputDecoration(
                    labelText: 'Gravidade',
                    border: OutlineInputBorder(),
                  ),
                  items: _gravidades.map((gravidade) {
                    return DropdownMenuItem<String>(
                      value: gravidade,
                      child: Text(gravidade),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGravidadeCondicao = newValue;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _observacoesCondicaoController,
            decoration: const InputDecoration(
              labelText: 'Observações',
              border: OutlineInputBorder(),
              hintText: 'Observações adicionais...',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _salvarCondicaoMedica,
            icon: const Icon(Icons.medical_services),
            label: const Text('Salvar Condição Médica'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const Divider(height: 48, thickness: 2),

          // FORMULÁRIO 6: Registrar Vacina
          _buildSectionTitle('6. Registrar Vacina'),
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: _selectedPacienteVacina,
            decoration: const InputDecoration(
              labelText: 'Paciente *',
              border: OutlineInputBorder(),
            ),
            items: _pacientes.map((paciente) {
              return DropdownMenuItem<int>(
                value: paciente['id'],
                child: Text(paciente['nome']),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                _selectedPacienteVacina = newValue;
              });
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nomeVacinaController,
            decoration: const InputDecoration(
              labelText: 'Nome da vacina *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _doseVacinaController,
            decoration: const InputDecoration(
              labelText: 'Dose *',
              border: OutlineInputBorder(),
              hintText: 'Ex: 1ª dose, 2ª dose, reforço...',
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _localAplicacaoController,
            decoration: const InputDecoration(
              labelText: 'Local de aplicação',
              border: OutlineInputBorder(),
              hintText: 'Ex: Posto de saúde, clínica particular...',
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _loteVacinaController,
            decoration: const InputDecoration(
              labelText: 'Lote da vacina',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, (picked) {
                    setState(() {
                      _dataAplicacaoVacina = picked;
                    });
                  }),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data de aplicação *',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dataAplicacaoVacina != null
                              ? '${_dataAplicacaoVacina!.day}/${_dataAplicacaoVacina!.month}/${_dataAplicacaoVacina!.year}'
                              : 'Selecione a data',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, (picked) {
                    setState(() {
                      _proximaDoseVacina = picked;
                    });
                  }),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Próxima dose',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _proximaDoseVacina != null
                              ? '${_proximaDoseVacina!.day}/${_proximaDoseVacina!.month}/${_proximaDoseVacina!.year}'
                              : 'Selecione a data',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _salvarVacina,
            icon: const Icon(Icons.vaccines),
            label: const Text('Salvar Vacina'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 16, 151, 185).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromARGB(255, 16, 151, 185),
          width: 1,
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 16, 151, 185),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// TELA 2: CONTROLE DIÁRIO (antigo medicinal_geral.dart)
class MedicinalGeralScreen extends StatefulWidget {
  const MedicinalGeralScreen({super.key});

  @override
  State<MedicinalGeralScreen> createState() => _MedicinalGeralScreenState();
}

class _MedicinalGeralScreenState extends State<MedicinalGeralScreen> {
  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _examesAgendados = [];
  List<Map<String, dynamic>> _consultasAgendadas = [];
  List<Map<String, dynamic>> _lembretesExames = [];
  List<Map<String, dynamic>> _medicamentos = [];
  List<Map<String, dynamic>> _condicoesMedicas = [];
  List<Map<String, dynamic>> _vacinas = [];

  bool _isLoading = true;
  int? _selectedPacienteId;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    // Limpeza segura para evitar chamadas após dispose
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final pacientesData = await Supabase.instance.client
          .from('paciente')
          .select('id, nome');

      if (mounted) {
        setState(() {
          _pacientes = List<Map<String, dynamic>>.from(pacientesData);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar dados gerais: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Erro ao carregar dados: $e', isError: true);
      }
    }
  }

  Future<void> _carregarDadosPaciente(int pacienteId) async {
    try {
      final [
        examesAgendadosData,
        consultasData,
        lembretesData,
        medicamentosData,
        condicoesData,
        vacinasData,
      ] = await Future.wait([
        Supabase.instance.client
            .from('exames_agendado')
            .select('*')
            .eq('paciente_id', pacienteId)
            .order('data_agendado'),
        Supabase.instance.client
            .from('consultas')
            .select('*')
            .eq('paciente_id', pacienteId)
            .order('data_consulta'),
        Supabase.instance.client
            .from('exames_lembrete')
            .select('*, status(nome)')
            .eq('paciente_id', pacienteId)
            .order('data_registro', ascending: false),
        Supabase.instance.client
            .from('medicamentos')
            .select('*')
            .eq('paciente_id', pacienteId)
            .order('data_registro', ascending: false),
        Supabase.instance.client
            .from('condicoes_medicas')
            .select('*')
            .eq('paciente_id', pacienteId)
            .order('data_registro', ascending: false),
        Supabase.instance.client
            .from('vacinas')
            .select('*')
            .eq('paciente_id', pacienteId)
            .order('data_registro', ascending: false),
      ]);

      if (mounted) {
        setState(() {
          _examesAgendados = List<Map<String, dynamic>>.from(
            examesAgendadosData,
          );
          _consultasAgendadas = List<Map<String, dynamic>>.from(consultasData);
          _lembretesExames = List<Map<String, dynamic>>.from(lembretesData);
          _medicamentos = List<Map<String, dynamic>>.from(medicamentosData);
          _condicoesMedicas = List<Map<String, dynamic>>.from(condicoesData);
          _vacinas = List<Map<String, dynamic>>.from(vacinasData);
        });
      }
    } catch (e) {
      print('Erro ao carregar dados do paciente: $e');
      if (mounted) {
        _showSnackBar('Erro ao carregar dados do paciente: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    try {
      if (mounted && context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.redAccent : Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        print('SnackBar não mostrado: $message');
      }
    } catch (e) {
      print('Erro ao mostrar SnackBar: $e - Mensagem: $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Seletor de Paciente
                  _buildSectionTitle('Selecionar Paciente'),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: _selectedPacienteId,
                    decoration: const InputDecoration(
                      labelText: 'Selecione um paciente',
                      border: OutlineInputBorder(),
                    ),
                    items: _pacientes.map((paciente) {
                      return DropdownMenuItem<int>(
                        value: paciente['id'],
                        child: Text(paciente['nome']),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (mounted) {
                        setState(() {
                          _selectedPacienteId = newValue;
                        });
                      }
                      if (newValue != null) {
                        _carregarDadosPaciente(newValue);
                      }
                    },
                  ),

                  if (_selectedPacienteId != null) ...[
                    const SizedBox(height: 32),

                    // Exames Agendados
                    if (_examesAgendados.isNotEmpty) ...[
                      _buildSectionTitle('Exames Agendados'),
                      const SizedBox(height: 16),
                      ..._examesAgendados.map(
                        (exame) => _buildExameCard(exame),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Consultas Agendadas
                    if (_consultasAgendadas.isNotEmpty) ...[
                      _buildSectionTitle('Consultas Agendadas'),
                      const SizedBox(height: 16),
                      ..._consultasAgendadas.map(
                        (consulta) => _buildConsultaCard(consulta),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Lembretes de Exames
                    if (_lembretesExames.isNotEmpty) ...[
                      _buildSectionTitle('Lembretes de Exames'),
                      const SizedBox(height: 16),
                      ..._lembretesExames.map(
                        (lembrete) => _buildLembreteCard(lembrete),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Medicamentos
                    if (_medicamentos.isNotEmpty) ...[
                      _buildSectionTitle('Medicamentos em Uso'),
                      const SizedBox(height: 16),
                      ..._medicamentos.map(
                        (medicamento) => _buildMedicamentoCard(medicamento),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Condições Médicas
                    if (_condicoesMedicas.isNotEmpty) ...[
                      _buildSectionTitle('Condições Médicas'),
                      const SizedBox(height: 16),
                      ..._condicoesMedicas.map(
                        (condicao) => _buildCondicaoCard(condicao),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Vacinas
                    if (_vacinas.isNotEmpty) ...[
                      _buildSectionTitle('Vacinas'),
                      const SizedBox(height: 16),
                      ..._vacinas.map((vacina) => _buildVacinaCard(vacina)),
                    ],

                    if (_examesAgendados.isEmpty &&
                        _consultasAgendadas.isEmpty &&
                        _lembretesExames.isEmpty &&
                        _medicamentos.isEmpty &&
                        _condicoesMedicas.isEmpty &&
                        _vacinas.isEmpty) ...[
                      const SizedBox(height: 32),
                      const Center(
                        child: Text(
                          'Nenhum dado encontrado para este paciente',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        'Selecione um paciente para visualizar os dados',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 16, 151, 185).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromARGB(255, 16, 151, 185),
          width: 1,
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 16, 151, 185),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildExameCard(Map<String, dynamic> exame) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exame['nome_exame_consulta'] ?? 'Exame',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.medical_services, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 8),
            Text('Clínica: ${exame['clinica_hospital'] ?? 'Não informado'}'),
            Text('Data: ${_formatDate(exame['data_agendado'])}'),
            if (exame['horario'] != null) Text('Horário: ${exame['horario']}'),
            if (exame['motivo'] != null) Text('Motivo: ${exame['motivo']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultaCard(Map<String, dynamic> consulta) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    consulta['especialidade'] ?? 'Consulta',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            Text('Médico: ${consulta['medico'] ?? 'Não informado'}'),
            Text('Local: ${consulta['local_consulta'] ?? 'Não informado'}'),
            Text('Data: ${_formatDate(consulta['data_consulta'])}'),
            if (consulta['horario'] != null)
              Text('Horário: ${consulta['horario']}'),
            if (consulta['motivo'] != null)
              Text('Motivo: ${consulta['motivo']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildLembreteCard(Map<String, dynamic> lembrete) {
    final status = lembrete['status']?['nome'] ?? 'pendente';
    Color statusColor = Colors.orange;

    if (status == 'agendado') statusColor = Colors.blue;
    if (status == 'realizado') statusColor = Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    lembrete['nome_exame'] ?? 'Lembrete',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (lembrete['motivo'] != null)
              Text('Motivo: ${lembrete['motivo']}'),
            Text('Registrado em: ${_formatDate(lembrete['data_registro'])}'),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicamentoCard(Map<String, dynamic> medicamento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    medicamento['nome_medicamento'] ?? 'Medicamento',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.medication, color: Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            if (medicamento['medico_prescrito'] != null)
              Text('Médico: ${medicamento['medico_prescrito']}'),
            if (medicamento['motivo_medicamento'] != null)
              Text('Motivo: ${medicamento['motivo_medicamento']}'),
            Text('Duração: ${medicamento['duracao_dias'] ?? 'N/A'} dias'),
            if (medicamento['intervalo_medicamento'] != null)
              Text('Intervalo: ${medicamento['intervalo_medicamento']}'),
            Text('Início: ${_formatDate(medicamento['data_inicio'])}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCondicaoCard(Map<String, dynamic> condicao) {
    Color gravidadeColor = Colors.green;
    switch (condicao['gravidade']) {
      case 'Moderada':
        gravidadeColor = Colors.orange;
        break;
      case 'Grave':
        gravidadeColor = Colors.red;
        break;
      case 'Crítica':
        gravidadeColor = Colors.purple;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    condicao['tipo'] ?? 'Condição',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (condicao['gravidade'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: gravidadeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gravidadeColor),
                    ),
                    child: Text(
                      condicao['gravidade'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: gravidadeColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (condicao['descricao'] != null)
              Text('Descrição: ${condicao['descricao']}'),
            if (condicao['diagnostico_data'] != null)
              Text('Diagnóstico: ${_formatDate(condicao['diagnostico_data'])}'),
            if (condicao['observacoes'] != null)
              Text('Observações: ${condicao['observacoes']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildVacinaCard(Map<String, dynamic> vacina) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    vacina['nome_vacina'] ?? 'Vacina',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.vaccines, color: Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            if (vacina['dose'] != null) Text('Dose: ${vacina['dose']}'),
            if (vacina['local_aplicacao'] != null)
              Text('Local: ${vacina['local_aplicacao']}'),
            if (vacina['lote'] != null) Text('Lote: ${vacina['lote']}'),
            Text('Aplicação: ${_formatDate(vacina['data_aplicacao'])}'),
            if (vacina['proxima_dose'] != null)
              Text('Próxima dose: ${_formatDate(vacina['proxima_dose'])}'),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Data não informada';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

// TELA 3: PERFIL DO PACIENTE (antigo medicinal_perfil.dart)
class MedicinalPerfilScreen extends StatefulWidget {
  const MedicinalPerfilScreen({super.key});

  @override
  State<MedicinalPerfilScreen> createState() => _MedicinalPerfilScreenState();
}

class _MedicinalPerfilScreenState extends State<MedicinalPerfilScreen> {
  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _resultadosExames = [];
  List<Map<String, dynamic>> _condicoesMedicas = [];
  List<Map<String, dynamic>> _medicamentos = [];
  List<Map<String, dynamic>> _vacinas = [];

  bool _isLoading = true;
  int? _selectedPacienteId;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final pacientesData = await Supabase.instance.client
          .from('paciente')
          .select('id, nome');

      if (mounted) {
        setState(() {
          _pacientes = List<Map<String, dynamic>>.from(pacientesData);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar dados do perfil: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Erro ao carregar dados: $e', isError: true);
      }
    }
  }

  Future<void> _carregarDadosPaciente(int pacienteId) async {
    try {
      final [
        resultadosData,
        condicoesData,
        medicamentosData,
        vacinasData,
      ] = await Future.wait([
        Supabase.instance.client
            .from('resultado_exames')
            .select('*, exames_status(nome)')
            .eq('paciente_id', pacienteId)
            .order('data_exame', ascending: false),
        Supabase.instance.client
            .from('condicoes_medicas')
            .select('*')
            .eq('paciente_id', pacienteId)
            .order('diagnostico_data', ascending: false),
        Supabase.instance.client
            .from('medicamentos')
            .select('*')
            .eq('paciente_id', pacienteId)
            .order('data_inicio', ascending: false),
        Supabase.instance.client
            .from('vacinas')
            .select('*')
            .eq('paciente_id', pacienteId)
            .order('data_aplicacao', ascending: false),
      ]);

      if (mounted) {
        setState(() {
          _resultadosExames = List<Map<String, dynamic>>.from(resultadosData);
          _condicoesMedicas = List<Map<String, dynamic>>.from(condicoesData);
          _medicamentos = List<Map<String, dynamic>>.from(medicamentosData);
          _vacinas = List<Map<String, dynamic>>.from(vacinasData);
        });
      }
    } catch (e) {
      print('Erro ao carregar dados completos do paciente: $e');
      if (mounted) {
        _showSnackBar('Erro ao carregar dados completos: $e', isError: true);
      }
    }
  }

  Future<void> _deletarCondicaoMedica(int id) async {
    try {
      await Supabase.instance.client
          .from('condicoes_medicas')
          .delete()
          .eq('id', id);

      if (mounted) {
        setState(() {
          _condicoesMedicas.removeWhere((condicao) => condicao['id'] == id);
        });
        _showSnackBar('Condição médica excluída com sucesso!');
      }
    } catch (e) {
      _showSnackBar('Erro ao excluir condição médica: $e', isError: true);
    }
  }

  Future<void> _deletarMedicamento(int id) async {
    try {
      await Supabase.instance.client.from('medicamentos').delete().eq('id', id);

      if (mounted) {
        setState(() {
          _medicamentos.removeWhere((medicamento) => medicamento['id'] == id);
        });
        _showSnackBar('Medicamento excluído com sucesso!');
      }
    } catch (e) {
      _showSnackBar('Erro ao excluir medicamento: $e', isError: true);
    }
  }

  Future<void> _deletarResultadoExame(int id) async {
    try {
      await Supabase.instance.client
          .from('resultado_exames')
          .delete()
          .eq('id', id);

      if (mounted) {
        setState(() {
          _resultadosExames.removeWhere((exame) => exame['id'] == id);
        });
        _showSnackBar('Resultado de exame excluído com sucesso!');
      }
    } catch (e) {
      _showSnackBar('Erro ao excluir resultado de exame: $e', isError: true);
    }
  }

  void _showDeleteDialog(String tipo, String nome, int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir "$nome"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                switch (tipo) {
                  case 'condicao':
                    _deletarCondicaoMedica(id);
                    break;
                  case 'medicamento':
                    _deletarMedicamento(id);
                    break;
                  case 'exame':
                    _deletarResultadoExame(id);
                    break;
                }
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    try {
      if (mounted && context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.redAccent : Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        print('SnackBar não mostrado: $message');
      }
    } catch (e) {
      print('Erro ao mostrar SnackBar: $e - Mensagem: $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Seletor de Paciente
                  _buildSectionTitle('Selecionar Paciente'),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: _selectedPacienteId,
                    decoration: const InputDecoration(
                      labelText: 'Selecione um paciente',
                      border: OutlineInputBorder(),
                    ),
                    items: _pacientes.map((paciente) {
                      return DropdownMenuItem<int>(
                        value: paciente['id'],
                        child: Text(paciente['nome']),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        _selectedPacienteId = newValue;
                      });
                      if (newValue != null) {
                        _carregarDadosPaciente(newValue);
                      }
                    },
                  ),

                  if (_selectedPacienteId != null) ...[
                    const SizedBox(height: 32),

                    // Resultados de Exames
                    if (_resultadosExames.isNotEmpty) ...[
                      _buildSectionTitle('Resultados de Exames'),
                      const SizedBox(height: 16),
                      ..._resultadosExames.map(
                        (exame) => _buildResultadoExameCard(exame),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Condições Médicas
                    if (_condicoesMedicas.isNotEmpty) ...[
                      _buildSectionTitle('Condições Médicas'),
                      const SizedBox(height: 16),
                      ..._condicoesMedicas.map(
                        (condicao) => _buildCondicaoPerfilCard(condicao),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Medicamentos
                    if (_medicamentos.isNotEmpty) ...[
                      _buildSectionTitle('Medicamentos'),
                      const SizedBox(height: 16),
                      ..._medicamentos.map(
                        (medicamento) =>
                            _buildMedicamentoPerfilCard(medicamento),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Vacinas
                    if (_vacinas.isNotEmpty) ...[
                      _buildSectionTitle('Vacinas'),
                      const SizedBox(height: 16),
                      ..._vacinas.map(
                        (vacina) => _buildVacinaPerfilCard(vacina),
                      ),
                    ],

                    if (_resultadosExames.isEmpty &&
                        _condicoesMedicas.isEmpty &&
                        _medicamentos.isEmpty &&
                        _vacinas.isEmpty) ...[
                      const SizedBox(height: 32),
                      const Center(
                        child: Text(
                          'Nenhum dado encontrado para este paciente',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        'Selecione um paciente para visualizar o perfil',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 16, 151, 185).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromARGB(255, 16, 151, 185),
          width: 1,
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 16, 151, 185),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResultadoExameCard(Map<String, dynamic> exame) {
    final status = exame['exames_status']?['nome'] ?? 'desconhecido';
    Color statusColor = Colors.grey;

    if (status == 'normal') statusColor = Colors.green;
    if (status == 'alterado') statusColor = Colors.orange;
    if (status == 'critico') statusColor = Colors.red;

    final hasLink =
        exame['link_laudo_drive'] != null &&
        exame['link_laudo_drive'].toString().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exame['nome_exame'] ?? 'Exame',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(
                        'exame',
                        exame['nome_exame'] ?? 'Exame',
                        exame['id'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (exame['clinica_realizada'] != null)
              Text('Clínica: ${exame['clinica_realizada']}'),
            if (exame['nome_medico'] != null)
              Text('Médico: ${exame['nome_medico']}'),
            if (exame['motivo'] != null) Text('Motivo: ${exame['motivo']}'),
            Text('Data do exame: ${_formatDate(exame['data_exame'])}'),
            if (exame['data_resultado'] != null)
              Text(
                'Data do resultado: ${_formatDate(exame['data_resultado'])}',
              ),
            if (exame['ponto_atencao'] != null)
              Text('Ponto de atenção: ${exame['ponto_atencao']}'),
            if (hasLink) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  _abrirLink(exame['link_laudo_drive']);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Abrir laudo',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCondicaoPerfilCard(Map<String, dynamic> condicao) {
    Color gravidadeColor = Colors.green;
    switch (condicao['gravidade']) {
      case 'Moderada':
        gravidadeColor = Colors.orange;
        break;
      case 'Grave':
        gravidadeColor = Colors.red;
        break;
      case 'Crítica':
        gravidadeColor = Colors.purple;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    condicao['tipo'] ?? 'Condição',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (condicao['gravidade'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: gravidadeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: gravidadeColor),
                        ),
                        child: Text(
                          condicao['gravidade'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: gravidadeColor,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(
                        'condicao',
                        condicao['tipo'] ?? 'Condição',
                        condicao['id'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (condicao['descricao'] != null)
              Text('Descrição: ${condicao['descricao']}'),
            if (condicao['diagnostico_data'] != null)
              Text('Diagnóstico: ${_formatDate(condicao['diagnostico_data'])}'),
            if (condicao['observacoes'] != null)
              Text('Observações: ${condicao['observacoes']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicamentoPerfilCard(Map<String, dynamic> medicamento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    medicamento['nome_medicamento'] ?? 'Medicamento',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(
                    'medicamento',
                    medicamento['nome_medicamento'] ?? 'Medicamento',
                    medicamento['id'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (medicamento['medico_prescrito'] != null)
              Text('Médico: ${medicamento['medico_prescrito']}'),
            if (medicamento['motivo_medicamento'] != null)
              Text('Motivo: ${medicamento['motivo_medicamento']}'),
            Text('Duração: ${medicamento['duracao_dias'] ?? 'N/A'} dias'),
            if (medicamento['intervalo_medicamento'] != null)
              Text('Intervalo: ${medicamento['intervalo_medicamento']}'),
            Text('Início: ${_formatDate(medicamento['data_inicio'])}'),
          ],
        ),
      ),
    );
  }

  Widget _buildVacinaPerfilCard(Map<String, dynamic> vacina) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    vacina['nome_vacina'] ?? 'Vacina',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (vacina['dose'] != null) Text('Dose: ${vacina['dose']}'),
            if (vacina['local_aplicacao'] != null)
              Text('Local: ${vacina['local_aplicacao']}'),
            if (vacina['lote'] != null) Text('Lote: ${vacina['lote']}'),
            Text('Aplicação: ${_formatDate(vacina['data_aplicacao'])}'),
            if (vacina['proxima_dose'] != null)
              Text('Próxima dose: ${_formatDate(vacina['proxima_dose'])}'),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Data não informada';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _abrirLink(String url) {
    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        // Usar url_launcher em uma aplicação real
        // launchUrl(Uri.parse(url));
        _showSnackBar('Abrindo link: $url');
      } else {
        _showSnackBar('Link inválido', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro ao abrir link: $e', isError: true);
    }
  }
}
