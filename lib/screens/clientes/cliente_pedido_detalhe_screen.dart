import 'package:flutter/material.dart';

import '../../models/chopeira.dart';
import '../../models/cliente.dart';
import '../../models/enum_chopeira.dart';
import '../../models/orcamento.dart';
import '../../models/orcamento_item.dart';
import '../../models/pedido.dart';
import '../../services/chopeira_service.dart';
import '../../services/orcamento_service.dart';

/// Detalhes de um pedido em modo somente leitura.
///
/// Não permite alterar status nem excluir o pedido.
class ClientePedidoDetalheScreen extends StatefulWidget {
  final Pedido pedido;
  final Cliente cliente;

  const ClientePedidoDetalheScreen({
    super.key,
    required this.pedido,
    required this.cliente,
  });

  @override
  State<ClientePedidoDetalheScreen> createState() =>
      _ClientePedidoDetalheScreenState();
}

class _ClientePedidoDetalheScreenState
    extends State<ClientePedidoDetalheScreen> {
  final _orcamentoService = OrcamentoService();
  final _chopeiraService = ChopeiraService();
  late final Future<Orcamento?> _orcamentoFuture;
  late final Future<Map<int, Chopeira>> _chopeirasFuture;

  Pedido get _pedido => widget.pedido;

  @override
  void initState() {
    super.initState();
    _orcamentoFuture = _orcamentoService.buscarOrcamento(_pedido.orcamentoId);
    _chopeirasFuture = _carregarChopeiras();
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

  String _moeda(double valor) => 'R\$ ${valor.toStringAsFixed(2)}';

  String _formatarDataHora(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

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

  Widget _campo(String titulo, String valor, IconData icone) {
    return ListTile(
      leading: Icon(icone),
      title: Text(titulo),
      subtitle: Text(valor.isEmpty ? 'Não informado' : valor),
    );
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

  Widget _construirStatus() {
    final entregue = _pedido.entregue;
    final pago = _pedido.pago;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              entregue ? Icons.check_circle : Icons.schedule,
              color: entregue ? Colors.green.shade700 : Colors.orange.shade700,
            ),
            title: const Text('Entrega'),
            subtitle: Text(entregue ? 'Entregue' : 'Pendente'),
          ),
          ListTile(
            leading: Icon(
              pago ? Icons.check_circle : Icons.payments_outlined,
              color: pago ? Colors.green.shade700 : Colors.red.shade700,
            ),
            title: const Text('Pagamento'),
            subtitle: Text(pago ? 'Pago' : 'Em aberto'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do pedido')),
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
                  Text('Orçamento: ${_pedido.orcamentoCodigo}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _campo('Cliente', widget.cliente.nome, Icons.person_outline),
                _campo(
                  'Valor total',
                  _moeda(_pedido.valorTotal),
                  Icons.attach_money_outlined,
                ),
                _campo(
                  'Data e hora de entrega',
                  _formatarDataHora(_pedido.dataEntrega),
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
          _construirStatus(),
        ],
      ),
    );
  }
}
