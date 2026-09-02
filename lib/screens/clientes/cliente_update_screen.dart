import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../services/cliente_service.dart';

class ClienteUpdateScreen extends StatefulWidget {
  final Cliente cliente;

  const ClienteUpdateScreen({super.key, required this.cliente});

  @override
  State<ClienteUpdateScreen> createState() => _ClienteUpdateScreenState();
}

class _ClienteUpdateScreenState extends State<ClienteUpdateScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
  late TextEditingController _enderecoController;
  late TextEditingController _numeroController;
  late TextEditingController _bairroController;
  late TextEditingController _observacaoController;
  late TextEditingController _cpfController;
  late TextEditingController _emailController;

  final ClienteService _clienteService = ClienteService();

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.cliente.nome);
    _cpfController = TextEditingController(text: widget.cliente.cpf);
    _emailController = TextEditingController(text: widget.cliente.email);
    _telefoneController = TextEditingController(text: widget.cliente.telefone);
    _enderecoController = TextEditingController(text: widget.cliente.endereco);
    _observacaoController = TextEditingController(
      text: widget.cliente.observacao ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _observacaoController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> atualizarCliente() async {
    final clienteAtualizado = Cliente(
      id: widget.cliente.id,
      nome: _nomeController.text,
      cpf: _cpfController.text,
      email: _emailController.text,
      telefone: _telefoneController.text,
      endereco: _enderecoController.text,
      observacao: _observacaoController.text,
    );

    try {
      await _clienteService.atualizarCliente(clienteAtualizado);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente atualizado com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cpfController,
                decoration: const InputDecoration(labelText: 'CPF'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _enderecoController,
                decoration: const InputDecoration(labelText: 'Endereço'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _observacaoController,
                decoration: const InputDecoration(labelText: 'Observação'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: atualizarCliente,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
