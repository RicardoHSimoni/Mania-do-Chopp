import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../services/cliente_service.dart';

class ClienteSearchScreen extends StatefulWidget {
  const ClienteSearchScreen({super.key});

  @override
  State<ClienteSearchScreen> createState() => _ClienteSearchScreenState();
}

class _ClienteSearchScreenState extends State<ClienteSearchScreen> {
  final ClienteService _clienteService = ClienteService();
  final TextEditingController _pesquisaController = TextEditingController();
  Timer? _debounce;

  List<Cliente> _clientes = [];

  bool _carregando = true;

  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarClientes();
    _pesquisaController.addListener(_onPesquisaAlterada);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pesquisaController.removeListener(_onPesquisaAlterada);
    _pesquisaController.dispose();
    super.dispose();
  }

  // Carrega todos os clientes inicialmente
  Future<void> _carregarClientes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final clientes = await _clienteService.buscarClientes();
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = 'Não foi possível carregar os clientes.';
      });
    }
  }

  // Executado quando o texto da pesquisa muda
  void _onPesquisaAlterada() {
    final termo = _pesquisaController.text.trim();

    // Cancela a pesquisa anterior
    _debounce?.cancel();
    // Aguarda um pequeno intervalo antes de pesquisar. /
    /// // Isso evita fazer uma consulta a cada letra digitada.
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _pesquisar(termo);
    }); // Atualiza o botão de limpar
    setState(() {});
  }

  Future<void> _pesquisar(String termo) async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final clientes = await _clienteService.pesquisarClientes(termo);

      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível realizar a pesquisa.';
      });
    }
  }

  // Seleciona o cliente e devolve para a tela anterior

  void _selecionarCliente(Cliente cliente) {
    Navigator.pop(context, cliente);
  }

  // Limpa a pesquisa
  void _limparPesquisa() {
    _pesquisaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar cliente')),

      body: Column(
        children: [
          // Campo de pesquisa
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _pesquisaController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nome, CPF ou telefone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _pesquisaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _limparPesquisa,
                      )
                    : null,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Conteúdo
          Expanded(child: _buildConteudo()),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    // Carregando
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    // Erro
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _carregarClientes,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    // Nenhum cliente encontrado
    if (_clientes.isEmpty) {
      final pesquisando = _pesquisaController.text.trim().isNotEmpty;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search, size: 56),
              const SizedBox(height: 16),
              Text(
                pesquisando
                    ? 'Nenhum cliente encontrado.'
                    : 'Nenhum cliente cadastrado.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Lista de clientes
    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),

      itemCount: _clientes.length,

      separatorBuilder: (context, index) {
        return const Divider(height: 1);
      },

      itemBuilder: (context, index) {
        final cliente = _clientes[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),

          leading: CircleAvatar(
            child: Text(
              cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?',
            ),
          ),

          title: Text(
            cliente.nome,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cliente.cpf.isNotEmpty) Text('CPF：${cliente.cpf}'),

              if (cliente.telefone.isNotEmpty)
                Text('Telefone：${cliente.telefone}'),
            ],
          ),

          trailing: const Icon(Icons.chevron_right),

          onTap: () {
            _selecionarCliente(cliente);
          },
        );
      },
    );
  }
}
