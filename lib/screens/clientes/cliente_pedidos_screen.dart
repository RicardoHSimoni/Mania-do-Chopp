import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../models/pedido.dart';
import '../../services/pedido_service.dart';
import 'cliente_pedido_detalhe_screen.dart';

/// Histórico de pedidos de um cliente.
///
/// Mostra um resumo no topo (total de pedidos e valor total) e a lista de
/// pedidos do mais recente para o mais antigo, pela data de entrega.
/// Os dados são carregados uma única vez ao abrir a tela.
class ClientePedidosScreen extends StatefulWidget {
  final Cliente cliente;

  const ClientePedidosScreen({super.key, required this.cliente});

  @override
  State<ClientePedidosScreen> createState() => _ClientePedidosScreenState();
}

class _ClientePedidosScreenState extends State<ClientePedidosScreen> {
  final _pedidoService = PedidoService();
  late Future<List<Pedido>> _pedidosFuture;

  @override
  void initState() {
    super.initState();
    _pedidosFuture = _pedidoService.buscarPedidosPorCliente(widget.cliente.id);
  }

  void _recarregar() {
    setState(() {
      _pedidosFuture = _pedidoService.buscarPedidosPorCliente(
        widget.cliente.id,
      );
    });
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _moeda(double valor) => 'R\$ ${valor.toStringAsFixed(2)}';

  Widget _construirResumo(List<Pedido> pedidos) {
    final valorTotal = pedidos.fold<double>(
      0,
      (soma, pedido) => soma + pedido.valorTotal,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _itemResumo('Total de pedidos', pedidos.length.toString()),
            ),
            Expanded(child: _itemResumo('Valor total', _moeda(valorTotal))),
          ],
        ),
      ),
    );
  }

  Widget _itemResumo(String titulo, String valor) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _construirPedido(Pedido pedido) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.shopping_cart)),
        title: Text(
          'Pedido ${pedido.codigoFormatado}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_formatarData(pedido.dataEntrega)),
        trailing: Text(
          _moeda(pedido.valorTotal),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ClientePedidoDetalheScreen(
                pedido: pedido,
                cliente: widget.cliente,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pedidos de ${widget.cliente.nome}')),
      body: FutureBuilder<List<Pedido>>(
        future: _pedidosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Erro ao carregar pedidos: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _recarregar,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final pedidos = snapshot.data ?? const <Pedido>[];
          if (pedidos.isEmpty) {
            return const Center(
              child: Text('Nenhum pedido encontrado para este cliente.'),
            );
          }

          // O primeiro item da lista é o resumo; os demais são os pedidos.
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) return _construirResumo(pedidos);
              return _construirPedido(pedidos[index - 1]);
            },
          );
        },
      ),
    );
  }
}
