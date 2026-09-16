import 'package:flutter/material.dart';

import '../../models/chopeira.dart';
import '../../models/enum_chopeira.dart';
import '../../services/chopeira_service.dart';

/// Tela que lista as chopeiras (com filtros de status, modelo e voltagem),
/// permite selecionar várias e, ao confirmar, retorna a lista selecionada
/// para a tela anterior via Navigator.pop.
class ChopeiraSearchScreen extends StatefulWidget {
  /// IDs já selecionados anteriormente, caso a tela seja reaberta
  /// para editar uma seleção existente.
  final List<int> selecionadosIniciais;

  const ChopeiraSearchScreen({super.key, this.selecionadosIniciais = const []});

  @override
  State<ChopeiraSearchScreen> createState() => _ChopeiraSearchScreenState();
}

class _ChopeiraSearchScreenState extends State<ChopeiraSearchScreen> {
  final ChopeiraService _service = ChopeiraService();

  StatusChopeira? _filtroStatus;
  ModeloChopeira? _filtroModelo;
  VoltagemChopeira? _filtroVoltagem;

  // Guardamos os IDs selecionados (e não os objetos) porque o Stream
  // pode reemitir novas instâncias de Chopeira a cada atualização.
  late final Set<int> _codigosSelecionados;

  // Mantemos o último snapshot completo para conseguir montar a lista
  // final de objetos Chopeira selecionados na hora de confirmar.
  List<Chopeira> _ultimaListaCompleta = [];

  @override
  void initState() {
    super.initState();
    _codigosSelecionados = widget.selecionadosIniciais.toSet();
  }

  String _label(dynamic valorEnum) => valorEnum.toString().split('.').last;

  List<Chopeira> _aplicarFiltros(List<Chopeira> lista) {
    return lista.where((c) {
      if (_filtroStatus != null && c.status != _filtroStatus) return false;
      if (_filtroModelo != null && c.modelo != _filtroModelo) return false;
      if (_filtroVoltagem != null && c.voltagem != _filtroVoltagem) {
        return false;
      }
      return true;
    }).toList();
  }

  void _alternarSelecao(int id) {
    setState(() {
      if (_codigosSelecionados.contains(id)) {
        _codigosSelecionados.remove(id);
      } else {
        _codigosSelecionados.add(id);
      }
    });
  }

  void _limparFiltros() {
    setState(() {
      _filtroStatus = null;
      _filtroModelo = null;
      _filtroVoltagem = null;
    });
  }

  void _confirmarSelecao() {
    final selecionadas = _ultimaListaCompleta
        .where((c) => _codigosSelecionados.contains(c.codigo))
        .toList();
    Navigator.pop(context, selecionadas);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Chopeiras'),
        actions: [
          TextButton(
            onPressed: _limparFiltros,
            child: const Text(
              'Limpar filtros',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Chopeira>>(
              stream: _service.listarChopeiras(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar chopeiras: ${snapshot.error}',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                _ultimaListaCompleta = snapshot.data!;
                final chopeiras = _aplicarFiltros(_ultimaListaCompleta);

                if (chopeiras.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma chopeira encontrada para esse filtro'),
                  );
                }

                return ListView.builder(
                  itemCount: chopeiras.length,
                  itemBuilder: (context, index) {
                    final chopeira = chopeiras[index];
                    final selecionada = _codigosSelecionados.contains(
                      chopeira.codigo,
                    );

                    return CheckboxListTile(
                      value: selecionada,
                      onChanged: (_) => _alternarSelecao(chopeira.codigo),
                      title: Text('Chopeira #${chopeira.codigo}'),
                      subtitle: Text(
                        'Modelo: ${_label(chopeira.modelo)}  •  '
                        'Voltagem: ${_label(chopeira.voltagem)}  •  '
                        'Status: ${_label(chopeira.status)}',
                      ),
                      secondary: _statusIcon(chopeira.status),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: _codigosSelecionados.isEmpty ? null : _confirmarSelecao,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(
            _codigosSelecionados.isEmpty
                ? 'Selecione ao menos uma chopeira'
                : 'Confirmar seleção (${_codigosSelecionados.length})',
          ),
        ),
      ),
    );
  }

  Icon _statusIcon(StatusChopeira status) {
    switch (status) {
      case StatusChopeira.disponivel:
        return const Icon(Icons.check_circle, color: Colors.green);
      case StatusChopeira.emUso:
        return const Icon(Icons.local_bar, color: Colors.orange);
      case StatusChopeira.manutencao:
        return const Icon(Icons.build, color: Colors.red);
      case StatusChopeira.reservada:
        return const Icon(Icons.event_available, color: Colors.blue);
    }
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _buildFiltroDropdown<StatusChopeira>(
            label: 'Status',
            valor: _filtroStatus,
            valores: StatusChopeira.values,
            onChanged: (v) => setState(() => _filtroStatus = v),
          ),
          _buildFiltroDropdown<ModeloChopeira>(
            label: 'Modelo',
            valor: _filtroModelo,
            valores: ModeloChopeira.values,
            onChanged: (v) => setState(() => _filtroModelo = v),
          ),
          _buildFiltroDropdown<VoltagemChopeira>(
            label: 'Voltagem',
            valor: _filtroVoltagem,
            valores: VoltagemChopeira.values,
            onChanged: (v) => setState(() => _filtroVoltagem = v),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroDropdown<T>({
    required String label,
    required T? valor,
    required List<T> valores,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<T?>(
          hint: Text(label),
          value: valor,
          items: [
            DropdownMenuItem<T?>(value: null, child: Text('$label: Todos')),
            ...valores.map(
              (v) => DropdownMenuItem<T?>(value: v, child: Text(_label(v))),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
