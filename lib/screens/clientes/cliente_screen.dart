import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../services/cliente_service.dart';

class ClientesScreen extends StatelessWidget {
  ClientesScreen({super.key});

  final ClienteService _clienteService = ClienteService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),

      body: StreamBuilder<List<Cliente>>(
        stream: _clienteService.listarClientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final clientes = snapshot.data ?? [];

          if (clientes.isEmpty) {
            return const Center(child: Text('Nenhum cliente cadastrado.'));
          }

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];

              return ListTile(
                title: Text(cliente.nome),
                subtitle: Text(cliente.telefone),
              );
            },
          );
        },
      ),
    );
  }
}
