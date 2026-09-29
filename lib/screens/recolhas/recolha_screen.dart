import 'package:flutter/material.dart';

import '../../models/recolha.dart';
import '../../services/recolha_service.dart';

/// Filtros aplicados na lista.
class RecolhaFiltros {
  final bool recolhida;
  final bool naoRecolhida;
  final bool filtrarPorData;
  final DateTimeRange? periodo;

  const RecolhaFiltros({
    this.recolhida = false,
    this.naoRecolhida = false,
    this.filtrarPorData = false,
    this.periodo,
  });

  RecolhaFiltros copyWith({
    bool? recolhida,
    bool? naoRecolhida,
    bool? filtrarPorData,
    DateTimeRange? periodo,
    bool limparPeriodo = false,
  }) {
    return RecolhaFiltros(
      recolhida: recolhida ?? this.recolhida,
      naoRecolhida: naoRecolhida ?? this.naoRecolhida,
      filtrarPorData: filtrarPorData ?? this.filtrarPorData,
      periodo: limparPeriodo ? null : (periodo ?? this.periodo),
    );
  }

  int get ativos =>
      (recolhida ? 1 : 0) +
      (naoRecolhida ? 1 : 0) +
      (filtrarPorData && periodo != null ? 1 : 0);
}

class RecolhasPage extends StatefulWidget {
  final List<Recolha>? recolhas;

  const RecolhasPage({super.key, this.recolhas});

  @override
  State<RecolhasPage> createState() => _RecolhasPageState();
}

class _RecolhasPageState extends State<RecolhasPage> {
  final _buscaController = TextEditingController();
  final RecolhaService _recolhaService = RecolhaService();
  RecolhaFiltros _filtros = const RecolhaFiltros();
  late final Stream<List<Recolha>> _recolhasStream;
  List<Recolha>? _recolhasCarregadas;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _recolhasStream = _recolhaService.listarRecolhas();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String _normalizar(String s) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const para = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    var r = s;
    for (var i = 0; i < de.length; i++) {
      r = r.replaceAll(de[i], para[i]);
    }
    return r.toLowerCase();
  }

  DateTime _soData(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Recolha> _filtrarLista(List<Recolha> origem) {
    final q = _normalizar(_busca.trim());
    final f = _filtros;

    final lista = origem.where((r) {
      if (q.isNotEmpty) {
        final texto = _normalizar(
          '${r.pedidoId} ${r.endereco} ${r.observacao ?? ''}',
        );
        if (!texto.contains(q)) return false;
      }

      if (f.recolhida || f.naoRecolhida) {
        final passa =
            (f.recolhida && r.recolhida) || (f.naoRecolhida && !r.recolhida);
        if (!passa) return false;
      }

      if (f.filtrarPorData && f.periodo != null) {
        final d = _soData(r.dataRecolha);
        if (d.isBefore(_soData(f.periodo!.start)) ||
            d.isAfter(_soData(f.periodo!.end))) {
          return false;
        }
      }
      return true;
    }).toList()..sort((a, b) => a.dataRecolha.compareTo(b.dataRecolha));

    return lista;
  }

  Future<void> _abrirFiltros() async {
    final resultado = await showModalBottomSheet<RecolhaFiltros>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FiltrosSheet(inicial: _filtros),
    );
    if (resultado != null) setState(() => _filtros = resultado);
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.recolhas != null
        ? Stream.value(widget.recolhas!)
        : _recolhaService.listarRecolhas();

    return Scaffold(
      appBar: AppBar(title: const Text('Recolhas')),
      body: StreamBuilder<List<Recolha>>(
        stream: _recolhasStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar recolhas: ${snapshot.error}'),
            );
          }

          final recolhas = snapshot.data ?? [];
          if (!identical(_recolhasCarregadas, recolhas)) {
            _recolhasCarregadas = recolhas;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _buscaController,
                        onChanged: (v) => setState(() => _busca = v),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Buscar por pedido, endereço ou observação',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _busca.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Limpar busca',
                                  onPressed: () {
                                    _buscaController.clear();
                                    setState(() => _busca = '');
                                  },
                                ),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Badge(
                      isLabelVisible: _filtros.ativos > 0,
                      label: Text('${_filtros.ativos}'),
                      child: IconButton.filled(
                        onPressed: _abrirFiltros,
                        tooltip: 'Filtros',
                        icon: const Icon(Icons.filter_list),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    recolhas.length == 1
                        ? '1 recolha encontrada'
                        : '${recolhas.length} recolhas encontradas',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: recolhas.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nenhuma recolha encontrada.\nAjuste a busca ou os filtros.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: recolhas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _RecolhaCard(recolha: recolhas[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecolhaCard extends StatelessWidget {
  final Recolha recolha;
  const _RecolhaCard({required this.recolha});

  @override
  Widget build(BuildContext context) {
    final cor = recolha.recolhida ? Colors.green : Colors.orange;
    final observacao = recolha.observacao?.trim();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: cor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pedido ${recolha.pedidoId}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(recolha.endereco),
                          Text(
                            observacao != null && observacao.isNotEmpty
                                ? '$observacao · ${_formatarData(recolha.dataRecolha)}'
                                : _formatarData(recolha.dataRecolha),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(recolha.recolhida ? 'Recolhida' : 'Pendente'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: cor.withOpacity(0.15),
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: cor.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltrosSheet extends StatefulWidget {
  final RecolhaFiltros inicial;
  const _FiltrosSheet({required this.inicial});

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late RecolhaFiltros _f = widget.inicial;

  Future<void> _escolherPeriodo() async {
    final agora = DateTime.now();
    final periodo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(agora.year - 2),
      lastDate: DateTime(agora.year + 2),
      initialDateRange: _f.periodo,
      helpText: 'Selecione o período',
      saveText: 'Confirmar',
    );
    if (periodo != null) {
      setState(() => _f = _f.copyWith(periodo: periodo));
    } else if (_f.periodo == null) {
      setState(() => _f = _f.copyWith(filtrarPorData: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodo = _f.periodo;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrar por', style: Theme.of(context).textTheme.titleMedium),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Recolhida'),
              value: _f.recolhida,
              onChanged: (v) => setState(() => _f = _f.copyWith(recolhida: v)),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Não recolhida'),
              value: _f.naoRecolhida,
              onChanged: (v) =>
                  setState(() => _f = _f.copyWith(naoRecolhida: v)),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Filtrar por data'),
              value: _f.filtrarPorData,
              onChanged: (v) {
                setState(() => _f = _f.copyWith(filtrarPorData: v));
                if (v == true && _f.periodo == null) _escolherPeriodo();
              },
            ),
            if (_f.filtrarPorData)
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 8),
                child: OutlinedButton.icon(
                  onPressed: _escolherPeriodo,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    periodo == null
                        ? 'Selecionar período'
                        : '${_formatarData(periodo.start)} – ${_formatarData(periodo.end)}',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _f = const RecolhaFiltros()),
                  child: const Text('Limpar'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _f),
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatarData(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
