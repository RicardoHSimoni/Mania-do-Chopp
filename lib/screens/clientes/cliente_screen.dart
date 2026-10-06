import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../services/cliente_service.dart';
import 'cliente_pedidos_screen.dart';

class ClienteScreen extends StatefulWidget {
  const ClienteScreen({Key? key}) : super(key: key);

  @override
  State<ClienteScreen> createState() => _ClienteScreenState();
}

class _ClienteScreenState extends State<ClienteScreen> {
  late ClienteService _clienteService;
  late final _clientesStream = _clienteService.listarClientes();
  final TextEditingController _searchController = TextEditingController();
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _clienteService = ClienteService();
    _searchController.addListener(() {
      setState(() {
        _filtro = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Cliente> _filtrarClientes(List<Cliente> clientes) {
    if (_filtro.isEmpty) return clientes;

    return clientes.where((cliente) {
      return cliente.nome.toLowerCase().contains(_filtro) ||
          cliente.cpf.toLowerCase().contains(_filtro) ||
          cliente.telefone.toLowerCase().contains(_filtro) ||
          cliente.email.toLowerCase().contains(_filtro);
    }).toList();
  }

  Future<void> _excluirCliente(BuildContext context, Cliente cliente) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text('Deseja realmente excluir o cliente ${cliente.nome}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmacao == true && mounted) {
      try {
        await _clienteService.excluirCliente(cliente.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente excluído com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
        }
      }
    }
  }

  void _exibirDetalhes(
    BuildContext context,
    Cliente cliente,
    int indiceAtual,
    int totalClientes,
    Function(int) onNavegar,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: indiceAtual > 0
                              ? () {
                                  Navigator.pop(context);
                                  onNavegar(indiceAtual - 1);
                                }
                              : null,
                        ),
                        const Text(
                          'Detalhes do Cliente',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: indiceAtual < totalClientes - 1
                              ? () {
                                  Navigator.pop(context);
                                  onNavegar(indiceAtual + 1);
                                }
                              : null,
                        ),
                      ],
                    ),
                    Text(
                      '${indiceAtual + 1} de $totalClientes',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    _construirDetalhe('Nome', cliente.nome),
                    _construirDetalhe('CPF', cliente.cpf),
                    _construirDetalhe('Email', cliente.email),
                    _construirDetalhe('Telefone', cliente.telefone),
                    _construirDetalhe('Endereço', cliente.endereco),
                    if (cliente.observacao != null &&
                        cliente.observacao!.isNotEmpty)
                      _construirDetalhe('Observação', cliente.observacao!),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/clientes/cliente_update_screen',
                                  arguments: cliente,
                                ),
                                icon: const Icon(Icons.edit),
                                label: const Text('Editar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _excluirCliente(context, cliente),
                                icon: const Icon(Icons.delete),
                                label: const Text('Excluir'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ClientePedidosScreen(cliente: cliente),
                            ),
                          ),
                          icon: const Icon(Icons.history),
                          label: const Text('Histórico de pedidos'),
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
  }

  Widget _construirDetalhe(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome, CPF, telefone ou email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchController.clear,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Cliente>>(
              stream: _clientesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar clientes: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final clientes = snapshot.data ?? [];
                if (clientes.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum cliente cadastrado',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final clientesFiltrados = _filtrarClientes(clientes);
                if (clientesFiltrados.isEmpty) {
                  return const Center(
                    child: Text('Nenhum cliente encontrado'),
                  );
                }

                return ListView.builder(
                  itemCount: clientesFiltrados.length,
                  itemBuilder: (context, index) {
                    final cliente = clientesFiltrados[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(cliente.nome),
                        subtitle: Text(
                          'CPF: ${cliente.cpf}\nTelefone: ${cliente.telefone}',
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () => _exibirDetalhes(
                            context,
                            cliente,
                            index,
                            clientesFiltrados.length,
                            (novoIndice) {
                              _exibirDetalhes(
                                context,
                                clientesFiltrados[novoIndice],
                                novoIndice,
                                clientesFiltrados.length,
                                (indice) {},
                              );
                            },
                          ),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Detalhes'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, '/clientes/cliente_form_screen'),
        tooltip: 'Adicionar cliente',
        child: const Icon(Icons.add),
      ),
    );
  }
}
