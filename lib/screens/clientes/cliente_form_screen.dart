import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../services/cliente_service.dart';

class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({super.key});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _observacaoController = TextEditingController();

  final ClienteService _clienteService = ClienteService();

  Future<void> salvarCliente() async {
    final cliente = Cliente(
      nome: _nomeController.text,
      telefone: _telefoneController.text,
      endereco: _enderecoController.text,
      numero: _numeroController.text,
      bairro: _bairroController.text,
      observacao: _observacaoController.text,
    );

    await _clienteService.adicionarCliente(cliente);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),

            TextField(
              controller: _telefoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),

            TextField(
              controller: _enderecoController,
              decoration: const InputDecoration(labelText: 'Endereço'),
            ),

            TextField(
              controller: _numeroController,
              decoration: const InputDecoration(labelText: 'Número'),
            ),

            TextField(
              controller: _bairroController,
              decoration: const InputDecoration(labelText: 'Bairro'),
            ),

            TextField(
              controller: _observacaoController,
              decoration: const InputDecoration(labelText: 'Observação'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: salvarCliente,
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
