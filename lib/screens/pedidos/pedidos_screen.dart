import 'package:flutter/material.dart';

import '../../models/chopeira.dart';
import '../../models/cliente.dart';
import '../../models/enum_chopeira.dart';
import '../../models/orcamento.dart';
import '../../models/orcamento_item.dart';
import '../../models/pedido.dart';
import '../../services/chopeira_service.dart';
import '../../services/cliente_service.dart';
import '../../services/orcamento_service.dart';
import '../../services/pedido_service.dart';
import '../../services/recolha_service.dart';
import '../orcamentos/orcamento_update_screen.dart';
import 'pedido_update_screen.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final _pedidoService = PedidoService();
  final _clienteService = ClienteService();
  final _pesquisaController = TextEditingController();
  final Map<String, Future<Cliente?>> _clientesEmCarregamento = {};
  late final Stream<List<Pedido>> _pedidosStream;
  List<Pedido>? _pedidosCarregados;
  Future<List<Cliente?>>? _clientesFuture;
  String _termoPesquisa = '';

  // Filtros de status (caixas de seleção).
  // Se nenhuma ou as duas opções de um grupo estiverem marcadas,
  // o grupo não restringe a lista.
  bool _filtroPagos = false;
  bool _filtroEmAberto = false;
  bool _filtroEntregues = false;
  bool _filtroNaoEntregues = false;

  // Filtro por período usando a data de entrega.
  DateTimeRange? _filtroPeriodo;

  // Indica que, inicialmente, o filtro é "a partir de hoje".
  bool _aPartirDeHoje = true;

  @override
  void initState() {
    super.initState();
    _pedidosStream = _pedidoService.listarPedidos();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Future<Cliente?> _buscarCliente(String clienteId) {
    return _clientesEmCarregamento.putIfAbsent(
      clienteId,
      () => _clienteService.buscarCliente(clienteId),
    );
  }

  int get _quantidadeFiltrosAtivos {
    var total = 0;
    if (_filtroPagos) total++;
    if (_filtroEmAberto) total++;
    if (_filtroEntregues) total++;
    if (_filtroNaoEntregues) total++;
    if (_filtroPeriodo != null) total++;
    return total;
  }

  bool _passaNosFiltros(Pedido pedido, Cliente? cliente) {
    // Pagamento: só restringe quando exatamente uma opção está marcada.
    if (_filtroPagos != _filtroEmAberto && pedido.pago != _filtroPagos) {
      return false;
    }

    // Entrega: só restringe quando exatamente uma opção está marcada.
    if (_filtroEntregues != _filtroNaoEntregues &&
        pedido.entregue != _filtroEntregues) {
      return false;
    }

    // Filtro de data.
    final data = DateUtils.dateOnly(pedido.dataEntrega);

    if (_aPartirDeHoje) {
      final hoje = DateUtils.dateOnly(DateTime.now());

      if (data.isBefore(hoje)) {
        return false;
      }
    } else {
      final periodo = _filtroPeriodo;

      if (periodo != null) {
        final inicio = DateUtils.dateOnly(periodo.start);
        final fim = DateUtils.dateOnly(periodo.end);

        if (data.isBefore(inicio) || data.isAfter(fim)) {
          return false;
        }
      }
    }

    return _correspondePesquisa(pedido, cliente);
  }

  Future<void> _abrirFiltros() async {
    var pagos = _filtroPagos;
    var emAberto = _filtroEmAberto;
    var entregues = _filtroEntregues;
    var naoEntregues = _filtroNaoEntregues;
    var periodo = _filtroPeriodo;
    var aPartirDeHoje = _aPartirDeHoje;

    final aplicar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtrar pedidos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pagamento',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Pagos'),
                      value: pagos,
                      onChanged: (valor) =>
                          setSheetState(() => pagos = valor ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Em aberto'),
                      value: emAberto,
                      onChanged: (valor) =>
                          setSheetState(() => emAberto = valor ?? false),
                    ),
                    const Divider(),
                    Text(
                      'Entrega',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Entregues'),
                      value: entregues,
                      onChanged: (valor) =>
                          setSheetState(() => entregues = valor ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Não entregues'),
                      value: naoEntregues,
                      onChanged: (valor) =>
                          setSheetState(() => naoEntregues = valor ?? false),
                    ),
                    const Divider(),
                    Text(
                      'Período (data de entrega)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              aPartirDeHoje
                                  ? 'A partir de hoje'
                                  : periodo == null
                                  ? 'Selecionar período'
                                  : '${_formatarData(periodo!.start)} - '
                                        '${_formatarData(periodo!.end)}',
                            ),
                            onPressed: () async {
                              final agora = DateTime.now();

                              final selecionado = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(agora.year - 5),
                                lastDate: DateTime(agora.year + 5),
                                initialDateRange: periodo,
                              );

                              if (selecionado != null) {
                                setSheetState(() {
                                  periodo = selecionado;
                                  aPartirDeHoje = false;
                                });
                              }
                            },
                          ),
                        ),
                        if (!aPartirDeHoje)
                          IconButton(
                            tooltip: 'Voltar para a partir de hoje',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setSheetState(() {
                                periodo = null;
                                aPartirDeHoje = true;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              final hoje = DateUtils.dateOnly(DateTime.now());
                              setSheetState(() {
                                pagos = false;
                                emAberto = false;
                                entregues = false;
                                naoEntregues = false;
                                // Ao limpar, volta para o padrão:
                                // pedidos de hoje em diante.
                                periodo = null;
                                aPartirDeHoje = true;
                              });
                            },
                            child: const Text('Limpar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(true),
                            child: const Text('Aplicar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (aplicar != true || !mounted) return;

    setState(() {
      _filtroPagos = pagos;
      _filtroEmAberto = emAberto;
      _filtroEntregues = entregues;
      _filtroNaoEntregues = naoEntregues;
      _filtroPeriodo = periodo;
      _aPartirDeHoje = aPartirDeHoje;
    });
  }

  bool _correspondePesquisa(Pedido pedido, Cliente? cliente) {
    final termo = _normalizarAcentos(_termoPesquisa.toLowerCase().trim());
    if (termo.isEmpty) return true;

    final partes = termo.split(RegExp(r'\s+')).where((parte) {
      return parte.isNotEmpty;
    });

    for (final parte in partes) {
      final filtro = parte.split(':');
      if (filtro.length == 2) {
        final chave = _normalizar(filtro.first);
        final valor = _normalizar(filtro.last);
        final estado = _lerEstado(valor);
        if (estado != null &&
            (chave == 'entregue' || chave == 'delivered') &&
            pedido.entregue != estado) {
          return false;
        }
        if (estado != null &&
            (chave == 'pago' || chave == 'paid') &&
            pedido.pago != estado) {
          return false;
        }
        if ((chave == 'entregue' ||
                chave == 'delivered' ||
                chave == 'pago' ||
                chave == 'paid') &&
            estado != null) {
          continue;
        }
      }

      final data = _normalizar(_formatarData(pedido.dataEntrega));
      final nome = _normalizar(cliente?.nome ?? '');
      final cpf = _normalizar(cliente?.cpf ?? '');
      final dataIso = _normalizar(
        '${pedido.dataEntrega.year}-${pedido.dataEntrega.month}-'
        '${pedido.dataEntrega.day}',
      );
      final parteNormalizada = _normalizar(parte);
      if (!nome.contains(parteNormalizada) &&
          !cpf.contains(parteNormalizada) &&
          !data.contains(parteNormalizada) &&
          !dataIso.contains(parteNormalizada)) {
        return false;
      }
    }

    return true;
  }

  bool? _lerEstado(String valor) {
    switch (valor) {
      case 'true':
      case 'sim':
      case 'yes':
      case '1':
        return true;
      case 'false':
      case 'nao':
      case 'não':
      case 'no':
      case '0':
        return false;
      default:
        return null;
    }
  }

  String _normalizar(String valor) {
    return _normalizarAcentos(valor.toLowerCase().trim())
        .replaceAll(RegExp(r'[^\w]'), '');
  }

  String _normalizarAcentos(String valor) {
    return valor
        .replaceAll('á', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u');
  }

  Widget _construirStatus(Pedido pedido) {
    final cor = pedido.entregue ? Colors.green : Colors.orange;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: [
        Chip(
          avatar: Icon(
            pedido.entregue ? Icons.check : Icons.schedule,
            size: 16,
            color: cor.shade700,
          ),
          label: Text(pedido.entregue ? 'Entregue' : 'Pendente'),
          labelStyle: TextStyle(color: cor.shade700, fontSize: 12),
          backgroundColor: cor.shade50,
          side: BorderSide(color: cor.shade200),
          visualDensity: VisualDensity.compact,
        ),
        Chip(
          avatar: Icon(
            pedido.pago ? Icons.check : Icons.payments_outlined,
            size: 16,
            color: pedido.pago ? Colors.green.shade700 : Colors.red.shade700,
          ),
          label: Text(pedido.pago ? 'Pago' : 'Em aberto'),
          labelStyle: TextStyle(
            color: pedido.pago ? Colors.green.shade700 : Colors.red.shade700,
            fontSize: 12,
          ),
          backgroundColor: pedido.pago
              ? Colors.green.shade50
              : Colors.red.shade50,
          side: BorderSide(
            color: pedido.pago ? Colors.green.shade200 : Colors.red.shade200,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _construirPedido(Pedido pedido, Cliente? cliente) {
    final nomeCliente = cliente?.nome ?? 'Cliente não encontrado';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                PedidoDetalheScreen(pedido: pedido, cliente: cliente),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(child: Icon(Icons.shopping_cart)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeCliente,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text('Orçamento: ${pedido.codigoOrcamentoFormatado}'),
                      ],
                    ),
                  ),
                  Text(
                    _formatarData(pedido.dataEntrega),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pedido.enderecoEntrega,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _construirStatus(pedido),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: StreamBuilder<List<Pedido>>(
        stream: _pedidosStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar pedidos: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final pedidos = snapshot.data ?? [];
          if (!identical(_pedidosCarregados, pedidos)) {
            _pedidosCarregados = pedidos;
            _clientesFuture = Future.wait(
              pedidos.map((pedido) => _buscarCliente(pedido.clienteId)),
            );
          }
          return FutureBuilder<List<Cliente?>>(
            future: _clientesFuture,
            builder: (context, clientesSnapshot) {
              if (clientesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (clientesSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar clientes: ${clientesSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final clientes = clientesSnapshot.data ?? [];
              final pedidosFiltrados = <int>[];
              for (var index = 0; index < pedidos.length; index++) {
                if (_passaNosFiltros(pedidos[index], clientes[index])) {
                  pedidosFiltrados.add(index);
                }
              }

              final filtrosAtivos = _quantidadeFiltrosAtivos;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pesquisaController,
                            onChanged: (valor) {
                              setState(() => _termoPesquisa = valor);
                            },
                            decoration: InputDecoration(
                              labelText: 'Pesquisar pedidos',
                              hintText:
                                  'Nome, CPF, data ou entregue:true pago:false',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _termoPesquisa.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Limpar pesquisa',
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _pesquisaController.clear();
                                        setState(() => _termoPesquisa = '');
                                      },
                                    ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Filtrar pedidos',
                          onPressed: _abrirFiltros,
                          icon: Badge(
                            isLabelVisible: filtrosAtivos > 0,
                            label: Text('$filtrosAtivos'),
                            child: const Icon(Icons.filter_list),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: pedidosFiltrados.isEmpty
                        ? Center(
                            child: Text(
                              pedidos.isEmpty
                                  ? 'Nenhum pedido cadastrado.'
                                  : 'Nenhum pedido encontrado.',
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: pedidosFiltrados.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final pedidoIndex = pedidosFiltrados[index];
                              return _construirPedido(
                                pedidos[pedidoIndex],
                                clientes[pedidoIndex],
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class PedidoDetalheScreen extends StatefulWidget {
  final Pedido pedido;
  final Cliente? cliente;

  const PedidoDetalheScreen({
    super.key,
    required this.pedido,
    required this.cliente,
  });

  @override
  State<PedidoDetalheScreen> createState() => _PedidoDetalheScreenState();
}

class _PedidoDetalheScreenState extends State<PedidoDetalheScreen> {
  final _pedidoService = PedidoService();
  final _recolhaService = RecolhaService();
  final _orcamentoService = OrcamentoService();
  final _chopeiraService = ChopeiraService();
  late Pedido _pedido;
  late Cliente? _cliente;
  late Future<Orcamento?> _orcamentoFuture;
  late Future<Map<int, Chopeira>> _chopeirasFuture;
  final _clienteService = ClienteService();

  @override
  void initState() {
    super.initState();
    _pedido = widget.pedido;
    _orcamentoFuture = _orcamentoService.buscarOrcamento(_pedido.orcamentoId);
    _chopeirasFuture = _carregarChopeiras();
    _cliente = widget.cliente;
  }

  /// Retorna as chopeiras do pedido indexadas pelo código.
  Future<Map<int, Chopeira>> _carregarChopeiras() async {
    final codigos = _pedido.chopeirasSelecionadas ?? const <int>[];
    if (codigos.isEmpty) return {};

    final todas = await _chopeiraService.listarChopeiras().first;
    return {
      for (final chopeira in todas)
        if (codigos.contains(chopeira.codigo)) chopeira.codigo: chopeira,
    };
  }

  // Callback usado pela tela de edição para mexer nos produtos do orçamento.
  Future<void> _editarProdutosDoOrcamento() async {
    final orcamento = await _orcamentoService.buscarOrcamento(
      _pedido.orcamentoId,
    );
    if (orcamento == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento não encontrado.')),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrcamentoUpdateScreen(orcamento: orcamento),
      ),
    );
  }

  Future<void> _editarPedido() async {
    final atualizado = await Navigator.of(context).push<Pedido>(
      MaterialPageRoute(
        builder: (_) => PedidoUpdateScreen(
          pedido: _pedido,
          cliente: _cliente,
          onEditarOrcamento: _editarProdutosDoOrcamento,
        ),
      ),
    );
    if (atualizado == null || !mounted) return;

    var cliente = _cliente;
    if (atualizado.clienteId != _pedido.clienteId) {
      cliente = await _clienteService.buscarCliente(atualizado.clienteId);
    }
    if (!mounted) return;

    setState(() {
      _pedido = atualizado;
      _cliente = cliente;
      _orcamentoFuture = _orcamentoService.buscarOrcamento(
        atualizado.orcamentoId,
      );
      _chopeirasFuture = _carregarChopeiras();
    });
  }

  String _moeda(double valor) => 'R\$ ${valor.toStringAsFixed(2)}';

  String _rotuloModelo(ModeloChopeira modelo) {
    switch (modelo) {
      case ModeloChopeira.grande:
        return 'Grande';
      case ModeloChopeira.normal:
        return 'Normal';
      case ModeloChopeira.gelo:
        return 'Gelo';
    }
  }

  String _rotuloVoltagem(VoltagemChopeira voltagem) {
    return voltagem == VoltagemChopeira.v110 ? '110V' : '220V';
  }

  String _rotuloStatus(StatusChopeira status) {
    switch (status) {
      case StatusChopeira.disponivel:
        return 'Disponível';
      case StatusChopeira.emUso:
        return 'Em uso';
      case StatusChopeira.manutencao:
        return 'Manutenção';
      case StatusChopeira.reservada:
        return 'Reservada';
    }
  }

  Widget _cabecalhoSecao(String titulo, IconData icone, {int? quantidade}) {
    return ListTile(
      leading: Icon(icone),
      title: Text(
        quantidade == null ? titulo : '$titulo ($quantidade)',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _mensagemSecao(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(texto),
    );
  }

  Widget _construirProdutos() {
    return Card(
      child: FutureBuilder<Orcamento?>(
        future: _orcamentoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cabecalhoSecao('Produtos', Icons.inventory_2_outlined),
                _mensagemSecao('Erro ao carregar produtos: ${snapshot.error}'),
              ],
            );
          }

          final orcamento = snapshot.data;
          if (orcamento == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cabecalhoSecao('Produtos', Icons.inventory_2_outlined),
                _mensagemSecao('Orçamento do pedido não encontrado.'),
              ],
            );
          }

          final produtos = orcamento.produtos;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalhoSecao(
                'Produtos',
                Icons.inventory_2_outlined,
                quantidade: produtos.length,
              ),
              if (produtos.isEmpty)
                _mensagemSecao('Nenhum produto neste pedido.')
              else
                for (final OrcamentoItem item in produtos)
                  ListTile(
                    dense: true,
                    title: Text(item.nomeProduto),
                    subtitle: Text(
                      '${item.quantidade} x ${_moeda(item.valorUnitario)}'
                      '${item.desconto > 0 ? ' (desconto ${_moeda(item.desconto)})' : ''}',
                    ),
                    trailing: Text(
                      _moeda(item.valorTotal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _construirChopeiras() {
    final codigos = _pedido.chopeirasSelecionadas ?? const <int>[];

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalhoSecao(
            'Chopeiras',
            Icons.local_drink_outlined,
            quantidade: codigos.length,
          ),
          if (codigos.isEmpty)
            _mensagemSecao('Nenhuma chopeira selecionada.')
          else
            FutureBuilder<Map<int, Chopeira>>(
              future: _chopeirasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return _mensagemSecao(
                    'Erro ao carregar chopeiras: ${snapshot.error}',
                  );
                }

                final chopeiras = snapshot.data ?? const <int, Chopeira>{};
                return Column(
                  children: [
                    for (final codigo in codigos)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.sports_bar_outlined),
                        title: Text('Chopeira nº $codigo'),
                        subtitle: Text(
                          chopeiras[codigo] == null
                              ? 'Dados não encontrados (cadastro removido?)'
                              : '${_rotuloModelo(chopeiras[codigo]!.modelo)}'
                                    ' • ${_rotuloVoltagem(chopeiras[codigo]!.voltagem)}'
                                    ' • ${_rotuloStatus(chopeiras[codigo]!.status)}',
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  Widget _campo(String titulo, String valor, IconData icone) {
    return ListTile(
      leading: Icon(icone),
      title: Text(titulo),
      subtitle: Text(valor.isEmpty ? 'Não informado' : valor),
    );
  }

  Future<void> _alterarStatus({bool? entregue, bool? pago}) async {
    final pedidoAnterior = _pedido;
    final pedidoAtualizado = Pedido(
      id: _pedido.id,
      codigo: _pedido.codigo,
      clienteId: _pedido.clienteId,
      orcamentoId: _pedido.orcamentoId,
      orcamentoCodigo: _pedido.orcamentoCodigo,
      dataEntrega: _pedido.dataEntrega,
      enderecoEntrega: _pedido.enderecoEntrega,
      observacoes: _pedido.observacoes,
      chopeirasSelecionadas: _pedido.chopeirasSelecionadas,
      valorTotal: _pedido.valorTotal,
      entregue: entregue ?? _pedido.entregue,
      pago: pago ?? _pedido.pago,
    );

    setState(() => _pedido = pedidoAtualizado);
    try {
      await _pedidoService.atualizarPedido(pedidoAtualizado);
      if (pedidoAnterior.entregue != pedidoAtualizado.entregue) {
        _recolhaService.criarRecolha(pedidoAtualizado);
        await _pedidoService.atualizarQuantidadeProdutosVendidos(
          pedidoAtualizado.orcamentoId,
        );
      }
    } catch (erro) {
      if (!mounted) return;
      setState(() => _pedido = pedidoAnterior);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar pedido: $erro')),
      );
    }
  }

  Future<void> _excluirPedido() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir pedido'),
          content: const Text(
            'Deseja realmente excluir este pedido? '
            'Essa ação não poderá ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _pedidoService.excluirPedido(_pedido.id);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido excluído com sucesso.')),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir pedido: $erro')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do pedido'),
        actions: [
          IconButton(
            tooltip: 'Editar pedido',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editarPedido,
          ),
          IconButton(
            tooltip: 'Excluir pedido',
            icon: const Icon(Icons.delete_outline),
            onPressed: _excluirPedido,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido ${_pedido.codigoFormatado}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('Orçamento: ${_pedido.codigoOrcamentoFormatado}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _campo(
                  'Cliente',
                  _cliente?.nome ?? 'Cliente não encontrado',
                  Icons.person_outline,
                ),
                _campo(
                  'Valor total',
                  'R\$ ${_pedido.valorTotal.toStringAsFixed(2)}',
                  Icons.attach_money_outlined,
                ),
                _campo(
                  'Data e hora de entrega',
                  _formatarData(_pedido.dataEntrega),
                  Icons.calendar_month,
                ),
                _campo(
                  'Endereço de entrega',
                  _pedido.enderecoEntrega,
                  Icons.location_on_outlined,
                ),
                _campo(
                  'Observações',
                  _pedido.observacoes,
                  Icons.notes_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _construirProdutos(),
          const SizedBox(height: 12),
          _construirChopeiras(),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Pedido entregue'),
                  value: _pedido.entregue,
                  onChanged: (valor) => _alterarStatus(entregue: valor),
                ),
                SwitchListTile(
                  title: const Text('Pedido pago'),
                  value: _pedido.pago,
                  onChanged: (valor) => _alterarStatus(pago: valor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
