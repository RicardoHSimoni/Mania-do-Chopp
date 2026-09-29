import 'package:flutter/material.dart';

import '../../models/orcamento.dart';
import '../../models/pedido.dart';
import '../../models/chopeira.dart';
import '../../models/cliente.dart';
import '../../services/cliente_service.dart';
import '../../services/pedido_service.dart';
import '../../services/produto_service.dart';
import '../chopeiras/chopeira_search_screen.dart';
import '../clientes/cliente_search_screen.dart';

class PedidoFormScreen extends StatefulWidget {
  final Orcamento orcamento;
  final VoidCallback? onEditarOrcamento;

  const PedidoFormScreen({
    super.key,
    required this.orcamento,
    this.onEditarOrcamento,
  });

  @override
  State<PedidoFormScreen> createState() => _PedidoFormScreenState();
}

class _PedidoFormScreenState extends State<PedidoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _enderecoController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _pedidoService = PedidoService();
  final _produtoService = ProdutoService();
  final _clienteService = ClienteService();

  late DateTime _dataEntrega;
  Cliente? _selectedCliente;
  List<int> chopeirasSelecionadas = [];
  bool _pago = false;
  bool _salvando = false;
  bool _possuiChopp = false;
  bool _carregandoCliente = false;

  // Reflete se este orçamento já gerou um pedido (evita reenvio duplicado
  // mesmo antes de tentar salvar no banco).
  late bool _pedidoJaGerado;

  @override
  void initState() {
    super.initState();
    _dataEntrega = DateTime.now().add(const Duration(days: 1));
    _pedidoJaGerado = widget.orcamento.pedidoGerado;
    _verificarSePossuiChopp();

    final clienteId = widget.orcamento.clienteId;
    if (clienteId != null && clienteId.isNotEmpty) {
      _carregarCliente(clienteId);
    }
  }

  @override
  void dispose() {
    _enderecoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  // Busca o cliente vinculado ao orçamento para exibir o nome.
  // Se não encontrar, o usuário poderá selecioná-lo pelo botão.
  Future<void> _carregarCliente(String clienteId) async {
    setState(() => _carregandoCliente = true);
    try {
      final cliente = await _clienteService.buscarCliente(clienteId);
      if (!mounted) return;
      setState(() => _selectedCliente = cliente);
    } catch (_) {
      // Mantém _selectedCliente nulo e exibe o botão de seleção.
    } finally {
      if (mounted) setState(() => _carregandoCliente = false);
    }
  }

  // Volta para a tela anterior (cadastro do orçamento). Se quem abriu esta
  // tela definiu um comportamento próprio, ele tem prioridade.
  void _editarProdutos() {
    final callback = widget.onEditarOrcamento;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _escolherData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataEntrega,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (data != null) {
      setState(() {
        _dataEntrega = DateTime(
          data.year,
          data.month,
          data.day,
          _dataEntrega.hour,
          _dataEntrega.minute,
        );
      });
    }
  }

  Future<void> _escolherHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataEntrega),
    );

    if (hora != null) {
      setState(() {
        _dataEntrega = DateTime(
          _dataEntrega.year,
          _dataEntrega.month,
          _dataEntrega.day,
          hora.hour,
          hora.minute,
        );
      });
    }
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
        if (!mounted) return;
        setState(() {
          _possuiChopp = true;
        });

        return;
      }
    }
  }

  Future<void> _salvar() async {
    if (_pedidoJaGerado) return;

    if (_selectedCliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente para o pedido.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    try {
      await _pedidoService.criarPedidoParaOrcamento(
        Pedido(
          id: '',
          clienteId: _selectedCliente!.id,
          orcamentoId: widget.orcamento.id,
          dataEntrega: _dataEntrega,
          enderecoEntrega: _enderecoController.text.trim(),
          observacoes: _observacoesController.text.trim(),
          chopeirasSelecionadas: chopeirasSelecionadas,
          valorTotal: widget.orcamento.valorTotal,
          entregue: false,
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
    } on PedidoJaGeradoException catch (e) {
      if (mounted) {
        setState(() => _pedidoJaGerado = true);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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

  // Campo de cliente: texto com o nome (somente leitura) quando existe;
  // caso contrário, um botão que abre a busca de clientes.
  Widget _buildCliente() {
    if (_carregandoCliente) {
      return const InputDecorator(
        decoration: InputDecoration(labelText: 'Cliente'),
        child: Text('Carregando...'),
      );
    }

    final cliente = _selectedCliente;
    if (cliente != null) {
      return OutlinedButton.icon(
        onPressed: null, // Desabilita o clique e o efeito visual de toque
        icon: const Icon(Icons.person),
        label: Text(cliente.nome),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _selecionarCliente,
      icon: const Icon(Icons.person_search),
      label: const Text('Selecionar cliente'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
            if (_pedidoJaGerado)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este orçamento já gerou um pedido. Não é possível '
                          'gerar outro.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Card(
              child: ListTile(
                title: Text('Orçamento ${widget.orcamento.id}'),
                subtitle: Text(
                  'Total: R\$ ${widget.orcamento.valorTotal.toStringAsFixed(2)}',
                ),
                trailing: TextButton.icon(
                  onPressed: _editarProdutos,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar produtos'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCliente(),
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

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hora de entrega'),
              subtitle: Text(
                '${_dataEntrega.hour.toString().padLeft(2, '0')}:'
                '${_dataEntrega.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: _escolherHora,
            ),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(labelText: 'Observações'),
              maxLines: 3,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pedido pago'),
              value: _pago,
              onChanged: (value) => setState(() => _pago = value),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_salvando || _pedidoJaGerado) ? null : _salvar,
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _pedidoJaGerado ? 'Pedido já gerado' : 'Cadastrar pedido',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
