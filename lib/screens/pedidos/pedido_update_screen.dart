import 'package:flutter/material.dart';

import '../../models/chopeira.dart';
import '../../models/cliente.dart';
import '../../models/enum_chopeira.dart';
import '../../models/orcamento.dart';
import '../../models/pedido.dart';
import '../../services/chopeira_service.dart';
import '../../services/orcamento_service.dart';
import '../../services/pedido_service.dart';
import '../../services/produto_service.dart';
import '../chopeiras/chopeira_search_screen.dart';
import '../clientes/cliente_search_screen.dart';

/// Tela de edição de um pedido já cadastrado.
///
/// Abre com os dados atuais do pedido e, ao salvar, devolve o [Pedido]
/// atualizado via Navigator.pop (ou null se o usuário cancelar).
class PedidoUpdateScreen extends StatefulWidget {
  final Pedido pedido;
  final Cliente? cliente;

  /// Chamado quando o usuário quer adicionar/alterar produtos do orçamento.
  /// Quem abre esta tela decide para onde navegar; ao terminar, esta tela
  /// recarrega o orçamento e atualiza o valor total.
  final Future<void> Function() onEditarOrcamento;

  const PedidoUpdateScreen({
    super.key,
    required this.pedido,
    required this.cliente,
    required this.onEditarOrcamento,
  });

  @override
  State<PedidoUpdateScreen> createState() => _PedidoUpdateScreenState();
}

class _PedidoUpdateScreenState extends State<PedidoUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _enderecoController = TextEditingController();
  final _observacoesController = TextEditingController();

  final _pedidoService = PedidoService();
  final _chopeiraService = ChopeiraService();
  final _orcamentoService = OrcamentoService();
  final _produtoService = ProdutoService();

  late DateTime _dataEntrega;
  Cliente? _cliente;
  late List<int> _chopeiras;
  late double _valorTotal;

  Orcamento? _orcamento;
  bool _carregandoOrcamento = true;
  bool _possuiChopp = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final pedido = widget.pedido;
    _dataEntrega = pedido.dataEntrega;
    _cliente = widget.cliente;
    _chopeiras = List<int>.from(pedido.chopeirasSelecionadas ?? const <int>[]);
    _valorTotal = pedido.valorTotal;
    _enderecoController.text = pedido.enderecoEntrega;
    _observacoesController.text = pedido.observacoes;
    _carregarOrcamento();
  }

  @override
  void dispose() {
    _enderecoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  String _moeda(double valor) => 'R\$ ${valor.toStringAsFixed(2)}';

  String _formatarData(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatarHora(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  String _rotuloStatus(StatusChopeira status) =>
      status.toString().split('.').last;

  // Carrega o orçamento do pedido (para exibir produtos/valor e saber se
  // existe chopp). Só sobrescreve o valor total quando [atualizarValor]
  // é true, ou seja, depois que o usuário editou os produtos.
  Future<void> _carregarOrcamento({bool atualizarValor = false}) async {
    setState(() => _carregandoOrcamento = true);
    try {
      final orcamento = await _orcamentoService.buscarOrcamento(
        widget.pedido.orcamentoId,
      );

      var possuiChopp = false;
      if (orcamento != null) {
        for (final item in orcamento.produtos) {
          final tipo = await _produtoService.buscarTipoProduto(item.produtoId);
          if (tipo == 'chopp') {
            possuiChopp = true;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _orcamento = orcamento;
        _possuiChopp = possuiChopp;
        if (atualizarValor && orcamento != null) {
          _valorTotal = orcamento.valorTotal;
        }
      });
    } catch (_) {
      // Mantém os dados atuais do pedido se não conseguir carregar.
    } finally {
      if (mounted) setState(() => _carregandoOrcamento = false);
    }
  }

  Future<void> _editarProdutos() async {
    await widget.onEditarOrcamento();
    if (!mounted) return;
    await _carregarOrcamento(atualizarValor: true);
  }

  Future<void> _escolherData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataEntrega,
      // Permite datas passadas para não quebrar pedidos antigos.
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (data == null) return;
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

  Future<void> _escolherHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataEntrega),
    );

    if (hora == null) return;
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

  Future<void> _selecionarCliente() async {
    final cliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const ClienteSearchScreen()),
    );

    if (cliente == null || !mounted) return;
    setState(() => _cliente = cliente);
  }

  Future<void> _selecionarChopeiras() async {
    final selecionadas = await Navigator.of(context).push<List<Chopeira>>(
      MaterialPageRoute(
        builder: (_) => ChopeiraSearchScreen(selecionadosIniciais: _chopeiras),
      ),
    );

    if (selecionadas == null || !mounted) return;
    setState(() {
      _chopeiras = selecionadas.map((c) => c.codigo).toList();
    });
  }

  // Avisa se alguma chopeira recém-adicionada não está disponível
  // (ex.: reservada ou em uso em outro pedido).
  Future<bool> _confirmarChopeirasIndisponiveis(List<int> codigos) async {
    final chopeiras = await _chopeiraService.buscarPorCodigos(codigos);
    final indisponiveis = chopeiras
        .where((c) => c.status != StatusChopeira.disponivel)
        .toList();

    if (indisponiveis.isEmpty || !mounted) return true;

    final lista = indisponiveis
        .map((c) => 'nº ${c.codigo} (${_rotuloStatus(c.status)})')
        .join(', ');

    final continuar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chopeiras indisponíveis'),
        content: Text(
          'As seguintes chopeiras não estão disponíveis: $lista.\n\n'
          'Deseja continuar mesmo assim?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    return continuar == true;
  }

  Future<void> _salvar() async {
    if (_cliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente para o pedido.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final antigas = widget.pedido.chopeirasSelecionadas ?? const <int>[];
    final removidas = antigas.where((c) => !_chopeiras.contains(c)).toList();
    final adicionadas = _chopeiras.where((c) => !antigas.contains(c)).toList();

    setState(() => _salvando = true);
    try {
      if (adicionadas.isNotEmpty) {
        final continuar = await _confirmarChopeirasIndisponiveis(adicionadas);
        if (!continuar) return;
      }

      final pedido = widget.pedido;
      final atualizado = Pedido(
        id: pedido.id,
        codigo: pedido.codigo,
        clienteId: _cliente!.id,
        orcamentoId: pedido.orcamentoId,
        orcamentoCodigo: pedido.orcamentoCodigo,
        dataEntrega: _dataEntrega,
        enderecoEntrega: _enderecoController.text.trim(),
        observacoes: _observacoesController.text.trim(),
        chopeirasSelecionadas: _chopeiras,
        valorTotal: _valorTotal,
        entregue: pedido.entregue,
        pago: pedido.pago,
      );

      await _pedidoService.atualizarPedido(atualizado);

      // Libera as chopeiras removidas e reserva as novas. Se o pedido já foi
      // entregue, as novas ficam "em uso".
      var avisoChopeiras = false;
      try {
        await _chopeiraService.atualizarStatusPorCodigos(
          removidas,
          StatusChopeira.disponivel,
        );
        await _chopeiraService.atualizarStatusPorCodigos(
          adicionadas,
          pedido.entregue ? StatusChopeira.emUso : StatusChopeira.reservada,
        );
      } catch (_) {
        avisoChopeiras = true;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            avisoChopeiras
                ? 'Pedido salvo, mas não foi possível atualizar o status '
                      'das chopeiras.'
                : 'Pedido atualizado com sucesso!',
          ),
        ),
      );
      Navigator.of(context).pop(atualizado);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar o pedido: $erro')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _buildCliente() {
    return OutlinedButton.icon(
      onPressed: _selecionarCliente,
      icon: Icon(_cliente == null ? Icons.person_search : Icons.person),
      label: Text(_cliente?.nome ?? 'Selecionar cliente'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildProdutos() {
    final orcamento = _orcamento;
    final String resumo;
    if (_carregandoOrcamento) {
      resumo = 'Carregando...';
    } else if (orcamento == null) {
      resumo = 'Orçamento não encontrado';
    } else {
      final qtd = orcamento.produtos.length;
      resumo = '$qtd ${qtd == 1 ? 'produto' : 'produtos'}';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Produtos do orçamento',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$resumo • Valor total: ${_moeda(_valorTotal)}'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: (_carregandoOrcamento || _orcamento == null)
                  ? null
                  : _editarProdutos,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar / adicionar produtos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChopeiras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chopeiras', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_chopeiras.isEmpty)
          const Text('Nenhuma chopeira selecionada.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final codigo in _chopeiras)
                InputChip(
                  label: Text('Chopeira nº $codigo'),
                  onDeleted: () => setState(() => _chopeiras.remove(codigo)),
                ),
            ],
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _selecionarChopeiras,
          icon: const Icon(Icons.sports_bar_outlined),
          label: const Text('Selecionar chopeiras'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar pedido ${widget.pedido.codigoFormatado}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCliente(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _escolherData,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_formatarData(_dataEntrega)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _escolherHora,
                    icon: const Icon(Icons.access_time),
                    label: Text(_formatarHora(_dataEntrega)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _enderecoController,
              decoration: const InputDecoration(
                labelText: 'Endereço de entrega',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            _buildProdutos(),
            if (_possuiChopp || _chopeiras.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildChopeiras(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _salvando ? null : _salvar,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _salvando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar alterações'),
          ),
        ),
      ),
    );
  }
}
