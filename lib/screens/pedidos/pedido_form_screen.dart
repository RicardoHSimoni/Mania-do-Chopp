import 'package:flutter/material.dart';

import '../../models/orcamento.dart';
import '../../models/pedido.dart';
import '../../models/chopeira.dart';
import '../../models/cliente.dart';
import '../../services/pedido_service.dart';
import '../../services/produto_service.dart';
import '../chopeiras/chopeira_search_screen.dart';
import '../clientes/cliente_search_screen.dart';

class PedidoFormScreen extends StatefulWidget {
  final Orcamento orcamento;
  final VoidCallback? onEditarOrcamento;
  final Future<String?> Function()? onAdicionarCliente;

  const PedidoFormScreen({
    super.key,
    required this.orcamento,
    this.onEditarOrcamento,
    this.onAdicionarCliente,
  });

  @override
  State<PedidoFormScreen> createState() => _PedidoFormScreenState();
}

class _PedidoFormScreenState extends State<PedidoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _pedidoService = PedidoService();
  final _produtoService = ProdutoService();

  late DateTime _dataEntrega;
  Cliente? _selectedCliente;
  List<int> chopeirasSelecionadas = [];
  bool _entregue = false;
  bool _pago = false;
  bool _salvando = false;
  bool _possuiChopp = false;

  @override
  void initState() {
    super.initState();
    _clienteController.text = widget.orcamento.clienteId ?? '';
    _dataEntrega = DateTime.now().add(const Duration(days: 1));
    _verificarSePossuiChopp();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _enderecoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataEntrega,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (data != null) setState(() => _dataEntrega = data);
  }

  Future<void> _selecionarChopeiras() async {
    final selecionadas = await Navigator.of(context).push<List<Chopeira>>(
      MaterialPageRoute(
        builder: (_) =>
            ChopeiraSearchScreen(selecionadosIniciais: chopeirasSelecionadas),
      ),
    );

    if (selecionadas != null && mounted) {
      setState(() {
        chopeirasSelecionadas = selecionadas
            .map((chopeira) => chopeira.codigo)
            .toList();
      });
    }
  }

  Future<void> _selecionarCliente() async {
    final cliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (context) => const ClienteSearchScreen()),
    );

    if (cliente == null || !mounted) return;

    setState(() {
      _selectedCliente = cliente;
    });
  }

  Future<void> _verificarSePossuiChopp() async {
    for (final item in widget.orcamento.produtos) {
      final tipo = await _produtoService.buscarTipoProduto(item.produtoId);

      if (tipo == 'chopp') {
        setState(() {
          _possuiChopp = true;
        });

        return;
      }
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    print('ID do orçamento: ${widget.orcamento.id}');

    setState(() => _salvando = true);
    try {
      await _pedidoService.adicionarPedido(
        Pedido(
          id: '',
          clienteId: _clienteController.text.trim(),
          orcamentoId: widget.orcamento.id,
          dataEntrega: _dataEntrega,
          enderecoEntrega: _enderecoController.text.trim(),
          observacoes: _observacoesController.text.trim(),
          chopeirasSelecionadas: chopeirasSelecionadas,
          valorTotal: widget.orcamento.valorTotal,
          entregue: _entregue,
          pago: _pago,
        ),
      );
      if (mounted) {
        await _pedidoService.atualizarQuantidadeProdutosVendidos(
          widget.orcamento.id,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido cadastrado com sucesso!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao cadastrar o pedido.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar pedido')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: Text('Orçamento ${widget.orcamento.id}'),
                subtitle: Text(
                  'Total: R\$ ${widget.orcamento.valorTotal.toStringAsFixed(2)}',
                ),
                trailing: TextButton.icon(
                  onPressed: widget.onEditarOrcamento,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar produtos'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clienteController,
              decoration: InputDecoration(
                labelText: 'Cliente',
                hintText: 'ID do cliente',
                suffixIcon: widget.onAdicionarCliente == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.person_add),
                        tooltip: 'Adicionar cliente',
                        onPressed: _selecionarCliente,
                      ),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe ou adicione um cliente'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _enderecoController,
              decoration: const InputDecoration(
                labelText: 'Endereço de entrega',
              ),
              maxLines: 2,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o endereço de entrega'
                  : null,
            ),
            if (_possuiChopp) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Selecionar chopeiras para o pedido'),
                subtitle: OutlinedButton.icon(
                  onPressed: _selecionarChopeiras,
                  icon: const Icon(Icons.local_bar),
                  label: Text(
                    chopeirasSelecionadas.isEmpty
                        ? 'Selecionar chopeiras'
                        : '${chopeirasSelecionadas.length} chopeira(s) selecionada(s)',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data de entrega'),
              subtitle: Text(
                '${_dataEntrega.day.toString().padLeft(2, '0')}/'
                '${_dataEntrega.month.toString().padLeft(2, '0')}/'
                '${_dataEntrega.year}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: _escolherData,
            ),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(labelText: 'Observações'),
              maxLines: 3,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pedido entregue'),
              value: _entregue,
              onChanged: (value) => setState(() => _entregue = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pedido pago'),
              value: _pago,
              onChanged: (value) => setState(() => _pago = value),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Cadastrar pedido'),
            ),
          ],
        ),
      ),
    );
  }
}
