import 'package:flutter/material.dart';

import '../../models/chopeira.dart';
import '../../models/enum_chopeira.dart';
import '../../services/chopeira_service.dart';
import 'chopeira_form_screen.dart';

enum _AcaoChopeira { editar, excluir }

class ChopeirasScreen extends StatefulWidget {
  const ChopeirasScreen({super.key});

  @override
  State<ChopeirasScreen> createState() => _ChopeirasScreenState();
}

class _ChopeirasScreenState extends State<ChopeirasScreen> {
  final ChopeiraService _service = ChopeiraService();
  final TextEditingController _buscaController = TextEditingController();
  late final Stream<List<Chopeira>> _chopeirasStream;

  String _busca = '';
  StatusChopeira? _statusFiltro;
  ModeloChopeira? _modeloFiltro;
  VoltagemChopeira? _voltagemFiltro;

  @override
  void initState() {
    super.initState();
    _chopeirasStream = _service.listarChopeiras();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String _label(Object valor) {
    return switch (valor) {
      VoltagemChopeira.v110 => '110 V',
      VoltagemChopeira.v220 => '220 V',
      ModeloChopeira.grande => 'Grande',
      ModeloChopeira.normal => 'Normal',
      ModeloChopeira.gelo => 'Gelo',
      StatusChopeira.disponivel => 'Disponível',
      StatusChopeira.emUso => 'Em uso',
      StatusChopeira.manutencao => 'Manutenção',
      StatusChopeira.reservada => 'Reservada',
      _ => valor.toString().split('.').last,
    };
  }

  List<Chopeira> _filtrar(List<Chopeira> chopeiras) {
    final busca = _busca.trim().toLowerCase();
    return chopeiras.where((chopeira) {
      final correspondeBusca =
          busca.isEmpty ||
          chopeira.codigo.toString().contains(busca) ||
          _label(chopeira.modelo).toLowerCase().contains(busca) ||
          _label(chopeira.voltagem).toLowerCase().contains(busca) ||
          _label(chopeira.status).toLowerCase().contains(busca);

      return correspondeBusca &&
          (_statusFiltro == null || chopeira.status == _statusFiltro) &&
          (_modeloFiltro == null || chopeira.modelo == _modeloFiltro) &&
          (_voltagemFiltro == null || chopeira.voltagem == _voltagemFiltro);
    }).toList()..sort((a, b) => a.codigo.compareTo(b.codigo));
  }

  Future<void> _abrirFormulario(
    List<Chopeira> existentes, {
    Chopeira? chopeira,
  }) async {
    final salvo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ChopeiraFormScreen(chopeira: chopeira, existentes: existentes),
      ),
    );

    if (salvo == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            chopeira == null
                ? 'Chopeira cadastrada com sucesso'
                : 'Chopeira atualizada com sucesso',
          ),
        ),
      );
    }
  }

  Future<void> _excluir(Chopeira chopeira) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir chopeira?'),
        content: Text('A chopeira #${chopeira.codigo} será removida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _service.excluirChopeira(chopeira.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chopeira excluída com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir chopeira: $e')));
      }
    }
  }

  Color _corStatus(StatusChopeira status, BuildContext context) {
    return switch (status) {
      StatusChopeira.disponivel => Colors.green,
      StatusChopeira.emUso => Colors.orange,
      StatusChopeira.manutencao => Theme.of(context).colorScheme.error,
      StatusChopeira.reservada => Colors.blue,
    };
  }

  IconData _iconeStatus(StatusChopeira status) {
    return switch (status) {
      StatusChopeira.disponivel => Icons.check_circle_outline,
      StatusChopeira.emUso => Icons.local_bar_outlined,
      StatusChopeira.manutencao => Icons.build_outlined,
      StatusChopeira.reservada => Icons.event_available_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chopeiras')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _buscaController,
              onChanged: (valor) => setState(() => _busca = valor),
              decoration: InputDecoration(
                hintText: 'Buscar por código ou característica',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busca.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          _buscaController.clear();
                          setState(() => _busca = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _filtroDropdown<StatusChopeira>(
                  titulo: 'Status',
                  valor: _statusFiltro,
                  valores: StatusChopeira.values,
                  aoMudar: (valor) => setState(() => _statusFiltro = valor),
                ),
                const SizedBox(width: 8),
                _filtroDropdown<ModeloChopeira>(
                  titulo: 'Modelo',
                  valor: _modeloFiltro,
                  valores: ModeloChopeira.values,
                  aoMudar: (valor) => setState(() => _modeloFiltro = valor),
                ),
                const SizedBox(width: 8),
                _filtroDropdown<VoltagemChopeira>(
                  titulo: 'Voltagem',
                  valor: _voltagemFiltro,
                  valores: VoltagemChopeira.values,
                  aoMudar: (valor) => setState(() => _voltagemFiltro = valor),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Chopeira>>(
              stream: _chopeirasStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar chopeiras: ${snapshot.error}',
                    ),
                  );
                }

                final todas = snapshot.data ?? [];
                final filtradas = _filtrar(todas);
                if (todas.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma chopeira cadastrada'),
                  );
                }
                if (filtradas.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma chopeira encontrada'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: filtradas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final chopeira = filtradas[index];
                    final cor = _corStatus(chopeira.status, context);
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        onTap: () =>
                            _abrirFormulario(todas, chopeira: chopeira),
                        leading: CircleAvatar(
                          backgroundColor: cor.withValues(alpha: 0.14),
                          foregroundColor: cor,
                          child: Icon(_iconeStatus(chopeira.status)),
                        ),
                        title: Text('Chopeira #${chopeira.codigo}'),
                        subtitle: Text(
                          '${_label(chopeira.modelo)} · '
                          '${_label(chopeira.voltagem)} · '
                          '${_label(chopeira.status)}',
                        ),
                        trailing: PopupMenuButton<_AcaoChopeira>(
                          tooltip: 'Ações da chopeira',
                          onSelected: (acao) {
                            if (acao == _AcaoChopeira.editar) {
                              _abrirFormulario(todas, chopeira: chopeira);
                            } else {
                              _excluir(chopeira);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _AcaoChopeira.editar,
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Editar'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: _AcaoChopeira.excluir,
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Excluir'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(const []),
        icon: const Icon(Icons.add),
        label: const Text('Nova chopeira'),
      ),
    );
  }

  Widget _filtroDropdown<T>({
    required String titulo,
    required T? valor,
    required List<T> valores,
    required ValueChanged<T?> aoMudar,
  }) {
    return DropdownButton<T?>(
      value: valor,
      hint: Text(titulo),
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem<T?>(value: null, child: Text('$titulo: Todos')),
        ...valores.map(
          (item) => DropdownMenuItem<T?>(
            value: item,
            child: Text('$titulo: ${_label(item as Object)}'),
          ),
        ),
      ],
      onChanged: aoMudar,
    );
  }
}
