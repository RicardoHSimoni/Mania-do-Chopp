import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/compra.dart';
import '../../models/compra_item.dart';
import '../../models/produto.dart';
import '../../services/compra_service.dart';
import '../produtos/produto_search_screen.dart';

/// Tela de compra de produtos.
///
/// Permite escolher produtos (via [ProdutoSearchScreen]), informar a
/// quantidade de cada um e registrar a [Compra], o que também atualiza o
/// estoque dos produtos.
class CompraFormScreen extends StatefulWidget {
  const CompraFormScreen({super.key});

  @override
  State<CompraFormScreen> createState() => _CompraFormScreenState();
}

class _CompraFormScreenState extends State<CompraFormScreen> {
  final CompraService _compraService = CompraService();
  final TextEditingController _observacaoController = TextEditingController();
  final List<CompraItem> _itens = [];

  bool _salvando = false;

  int get _quantidadeTotal =>
      _itens.fold(0, (total, item) => total + item.quantidade);

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  Future<int?> _pedirQuantidade(String titulo, int inicial) {
    return showDialog<int>(
      context: context,
      builder: (_) => _QuantidadeDialog(titulo: titulo, inicial: inicial),
    );
  }

  // Abre a busca de produtos e pergunta a quantidade do produto escolhido.
  // Se o produto já estiver na lista, a quantidade é substituída.
  Future<void> _adicionarProduto() async {
    final produto = await Navigator.push<Produto>(
      context,
      MaterialPageRoute(builder: (_) => const ProdutoSearchScreen()),
    );

    if (produto == null || !mounted) return;

    final indice = _itens.indexWhere((item) => item.produtoId == produto.id);
    final quantidadeInicial = indice == -1 ? 1 : _itens[indice].quantidade;

    final quantidade = await _pedirQuantidade(produto.nome, quantidadeInicial);

    if (quantidade == null || !mounted) return;

    setState(() {
      if (indice == -1) {
        _itens.add(
          CompraItem(
            produtoId: produto.id,
            nomeProduto: produto.nome,
            quantidade: quantidade,
          ),
        );
      } else {
        _itens[indice] = _itens[indice].copyWith(quantidade: quantidade);
      }
    });
  }

  Future<void> _editarQuantidade(int indice) async {
    final item = _itens[indice];
    final quantidade = await _pedirQuantidade(
      item.nomeProduto,
      item.quantidade,
    );

    if (quantidade == null || !mounted) return;

    setState(() {
      _itens[indice] = item.copyWith(quantidade: quantidade);
    });
  }

  void _alterarQuantidade(int indice, int delta) {
    final novaQuantidade = _itens[indice].quantidade + delta;
    if (novaQuantidade < 1) return;

    setState(() {
      _itens[indice] = _itens[indice].copyWith(quantidade: novaQuantidade);
    });
  }

  void _removerItem(int indice) {
    setState(() => _itens.removeAt(indice));
  }

  Future<void> _registrarCompra() async {
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um produto')),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final observacao = _observacaoController.text.trim();

      await _compraService.registrarCompra(
        Compra(
          id: '',
          // Cópia, para que alterações na tela não afetem a compra salva.
          itens: List<CompraItem>.from(_itens),
          dataCompra: DateTime.now(),
          observacao: observacao.isEmpty ? null : observacao,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compra registrada e estoque atualizado!'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao registrar a compra: $e')));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _construirItem(int indice) {
    final item = _itens[indice];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.shopping_bag)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.nomeProduto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'Diminuir',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: item.quantidade > 1
                  ? () => _alterarQuantidade(indice, -1)
                  : null,
            ),
            InkWell(
              onTap: () => _editarQuantidade(indice),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  item.quantidade.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Aumentar',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _alterarQuantidade(indice, 1),
            ),
            IconButton(
              tooltip: 'Remover',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removerItem(indice),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compra de produtos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _salvando ? null : _adicionarProduto,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Adicionar produto'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_itens.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Nenhum produto adicionado.')),
            )
          else
            for (var i = 0; i < _itens.length; i++) _construirItem(i),
          const SizedBox(height: 16),
          TextField(
            controller: _observacaoController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_itens.length} produto(s)'),
                  Text(
                    'Total de unidades: $_quantidadeTotal',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _salvando ? null : _registrarCompra,
                  icon: _salvando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_salvando ? 'Salvando...' : 'Registrar compra'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo para digitar a quantidade. Tem o próprio [State] para que o
/// controller seja descartado com segurança após o fechamento do diálogo.
class _QuantidadeDialog extends StatefulWidget {
  final String titulo;
  final int inicial;

  const _QuantidadeDialog({required this.titulo, required this.inicial});

  @override
  State<_QuantidadeDialog> createState() => _QuantidadeDialogState();
}

class _QuantidadeDialogState extends State<_QuantidadeDialog> {
  late final TextEditingController _controller;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.inicial.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final quantidade = int.tryParse(_controller.text);

    if (quantidade == null || quantidade <= 0) {
      setState(() => _erro = 'Informe uma quantidade maior que zero');
      return;
    }

    Navigator.pop(context, quantidade);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmitted: (_) => _confirmar(),
        decoration: InputDecoration(
          labelText: 'Quantidade comprada',
          border: const OutlineInputBorder(),
          errorText: _erro,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _confirmar, child: const Text('Confirmar')),
      ],
    );
  }
}
