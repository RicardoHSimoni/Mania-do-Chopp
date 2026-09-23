import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../models/pedido.dart';
import '../../models/recolha.dart';
import '../../services/cliente_service.dart';
import '../../services/pedido_service.dart';
import '../../services/recolha_service.dart';
import '../pedidos/pedidos_screen.dart' show PedidoDetalheScreen;
import '../recolhas/recolha_detalhe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pedidoService = PedidoService();
  final _clienteService = ClienteService();
  final _recolhaService = RecolhaService();
  final Map<String, Future<Cliente?>> _clientesEmCache = {};

  bool _mesmoDia(DateTime data, DateTime referencia) {
    return data.year == referencia.year &&
        data.month == referencia.month &&
        data.day == referencia.day;
  }

  Future<Cliente?> _buscarCliente(String clienteId) {
    return _clientesEmCache.putIfAbsent(
      clienteId,
      () => _clienteService.buscarCliente(clienteId),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mania do Chopp'),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Abrir menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Text(
                  'Mania do Chopp',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Início'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Orçamentos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/orcamentos/orcamentos_screen');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('Pedidos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/pedidos/pedidos_screen');
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outlined),
                title: const Text('Clientes'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/clientes/cliente_screen');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('Produtos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/produtos/produto_screen');
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildPedidosDoDia(hoje)),
          const Divider(height: 1, thickness: 1),
          Expanded(child: _buildRecolhasDoDia(hoje)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/orcamentos/orcamento_form_screen'),
        icon: const Icon(Icons.add),
        label: const Text('Novo orçamento'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSectionHeader(IconData icone, String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(icone, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidosDoDia(DateTime hoje) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.today_outlined, 'Entregas de hoje'),
        Expanded(
          child: StreamBuilder<List<Pedido>>(
            stream: _pedidoService.listarPedidos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar pedidos: ${snapshot.error}'),
                );
              }

              final pedidos =
                  (snapshot.data ?? [])
                      .where(
                        (p) => !p.entregue && _mesmoDia(p.dataEntrega, hoje),
                      )
                      .toList()
                    ..sort((a, b) => a.dataEntrega.compareTo(b.dataEntrega));

              if (pedidos.isEmpty) {
                return const Center(
                  child: Text('Nenhuma entrega pendente para hoje'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                itemCount: pedidos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final pedido = pedidos[index];
                  return FutureBuilder<Cliente?>(
                    future: _buscarCliente(pedido.clienteId),
                    builder: (context, clienteSnapshot) {
                      final cliente = clienteSnapshot.data;
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.local_shipping_outlined),
                          ),
                          title: Text(
                            cliente?.nome ?? 'Carregando...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            pedido.enderecoEntrega,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PedidoDetalheScreen(
                                  pedido: pedido,
                                  cliente: cliente,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecolhasDoDia(DateTime hoje) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.local_bar_outlined, 'Recolhas de hoje'),
        Expanded(
          child: StreamBuilder<List<Recolha>>(
            stream: _recolhaService.listarRecolhas(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar recolhas: ${snapshot.error}'),
                );
              }

              final recolhas =
                  (snapshot.data ?? [])
                      .where((r) => _mesmoDia(r.dataRecolha, hoje))
                      .toList()
                    ..sort((a, b) => a.dataRecolha.compareTo(b.dataRecolha));

              if (recolhas.isEmpty) {
                return const Center(
                  child: Text('Nenhuma recolha agendada para hoje'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                itemCount: recolhas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final recolha = recolhas[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: recolha.recolhida
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        child: Icon(
                          recolha.recolhida
                              ? Icons.check_circle_outline
                              : Icons.local_bar_outlined,
                          color: recolha.recolhida
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      title: Text(
                        recolha.endereco,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        recolha.recolhida
                            ? 'Recolhida'
                            : 'Pendente • '
                                  '${_formatarData(recolha.dataRecolha)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RecolhaDetalheScreen(recolha: recolha),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
