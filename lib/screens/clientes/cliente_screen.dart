import 'package:flutter/material.dart';

class ClienteScreen extends StatefulWidget {
  const ClienteScreen({Key? key}) : super(key: key);

  @override
  State<ClienteScreen> createState() => _ClienteScreenState();
}

class _ClienteScreenState extends State<ClienteScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> clientes = [
    'João Silva',
    'Maria Santos',
    'Pedro Oliveira',
    'Ana Costa',
    'Carlos Ferreira',
  ];
  List<String> clientesFiltrados = [];

  @override
  void initState() {
    super.initState();
    clientesFiltrados = clientes;
  }

  void _filtrarClientes(String query) {
    setState(() {
      if (query.isEmpty) {
        clientesFiltrados = clientes;
      } else {
        clientesFiltrados = clientes
            .where(
              (cliente) => cliente.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _adicionarCliente() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nomeController = TextEditingController();
        return AlertDialog(
          title: const Text('Adicionar Cliente'),
          content: TextField(
            controller: nomeController,
            decoration: const InputDecoration(hintText: 'Nome do cliente'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (nomeController.text.isNotEmpty) {
                  setState(() {
                    clientes.add(nomeController.text);
                    _filtrarClientes(_searchController.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar cliente por nome',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _filtrarClientes,
            ),
          ),
          Expanded(
            child: clientesFiltrados.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Nenhum cliente cadastrado'
                          : 'Nenhum cliente encontrado',
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: clientesFiltrados.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(clientesFiltrados[index]),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // TODO: Navegar para detalhes do cliente
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarCliente,
        tooltip: 'Adicionar cliente',
        child: const Icon(Icons.add),
      ),
    );
  }
}
