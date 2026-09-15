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
  final _pesquisaController = TextEditingController();
  final Map<String, Future<Cliente?>> _clientesEmCarregamento = {};
  String _termoPesquisa = '';

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
          return FutureBuilder<List<Cliente?>>(
            future: Future.wait(
              pedidos.map((pedido) {
                return _buscarCliente(pedido.clienteId);
              }),
            ),
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
                if (_correspondePesquisa(pedidos[index], clientes[index])) {
                  pedidosFiltrados.add(index);
                }
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _pesquisaController,
                      onChanged: (valor) {
                        setState(() => _termoPesquisa = valor);
                      },
                      decoration: InputDecoration(
                        labelText: 'Pesquisar pedidos',
                        hintText: 'Nome, CPF, data ou entregue:true pago:false',
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

class PedidoDetalheScreen extends StatelessWidget {
  final Pedido pedido;
  final Cliente? cliente;

  const PedidoDetalheScreen({
    super.key,
    required this.pedido,
    required this.cliente,
  });

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Widget _campo(String titulo, String valor, IconData icone) {
    return ListTile(
      leading: Icon(icone),
      title: Text(titulo),
      subtitle: Text(valor.isEmpty ? 'Não informado' : valor),
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
                    'Pedido ${pedido.id}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('Orçamento: ${pedido.orcamentoId}'),
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
                  cliente?.nome ?? 'Cliente não encontrado',
                  Icons.person_outline,
                ),
                _campo('CPF', cliente?.cpf ?? '', Icons.badge_outlined),
                _campo(
                  'Telefone',
                  cliente?.telefone ?? '',
                  Icons.phone_outlined,
                ),
                _campo('E-mail', cliente?.email ?? '', Icons.email_outlined),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _campo(
                  'Data de entrega',
                  _formatarData(pedido.dataEntrega),
                  Icons.calendar_month,
                ),
                _campo(
                  'Endereço de entrega',
                  pedido.enderecoEntrega,
                  Icons.location_on_outlined,
                ),
                _campo('Observações', pedido.observacoes, Icons.notes_outlined),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Pedido entregue'),
                  value: pedido.entregue,
                  onChanged: null,
                ),
                SwitchListTile(
                  title: const Text('Pedido pago'),
                  value: pedido.pago,
                  onChanged: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
