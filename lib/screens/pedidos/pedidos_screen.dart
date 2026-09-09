import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../models/pedido.dart';
import '../../services/cliente_service.dart';
import '../../services/pedido_service.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final _pedidoService = PedidoService();
  final _clienteService = ClienteService();

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
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

  Widget _construirPedido(Pedido pedido) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: FutureBuilder<Cliente?>(
          future: _clienteService.buscarCliente(pedido.clienteId),
          builder: (context, snapshot) {
            final cliente = snapshot.data;
            final nomeCliente =
                snapshot.connectionState == ConnectionState.waiting
                ? 'Carregando cliente...'
                : cliente?.nome ?? 'Cliente não encontrado';

            return Column(
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
                          Text('Orçamento: ${pedido.orcamentoId}'),
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
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: StreamBuilder<List<Pedido>>(
        stream: _pedidoService.listarPedidos(),
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
          if (pedidos.isEmpty) {
            return const Center(child: Text('Nenhum pedido cadastrado.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _construirPedido(pedidos[index]),
          );
        },
      ),
    );
  }
}
