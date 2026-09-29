import 'package:flutter/material.dart';

import '../../models/produto.dart';
import '../../services/produto_service.dart';

/// Tela de seleção de produto.
///
/// Permite pesquisar por nome ou categoria (tipo) e devolve o [Produto]
/// escolhido via `Navigator.pop(context, produto)`.
class ProdutoSearchScreen extends StatefulWidget {
  const ProdutoSearchScreen({super.key});

  @override
  State<ProdutoSearchScreen> createState() => _ProdutoSearchScreenState();
}

class _ProdutoSearchScreenState extends State<ProdutoSearchScreen> {
  final ProdutoService _produtoService = ProdutoService();
  final TextEditingController _pesquisaController = TextEditingController();

  List<Produto> _produtos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _pesquisaController.addListener(() => setState(() {}));
    _carregarProdutos();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregarProdutos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final produtos = await _produtoService.buscarTodosProdutos();
      if (!mounted) return;
      setState(() {
        _produtos = produtos;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível carregar os produtos.';
      });
    }
  }

  String _nomeCategoria(Produto produto) {
    return produto.tipo.toString().split('.').last;
  }

  // Remove acentos e ignora maiúsculas/minúsculas.
  String _normalizar(String texto) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';

    var resultado = texto.toLowerCase();
    for (var i = 0; i < de.length; i++) {
      resultado = resultado.replaceAll(de[i], para[i]);
    }
    return resultado;
  }

  // Filtra localmente por nome ou categoria.
  List<Produto> get _produtosFiltrados {
    final termo = _normalizar(_pesquisaController.text.trim());
    if (termo.isEmpty) return _produtos;

    return _produtos.where((produto) {
      return _normalizar(produto.nome).contains(termo) ||
          _normalizar(_nomeCategoria(produto)).contains(termo);
    }).toList();
  }

  void _selecionarProduto(Produto produto) {
    Navigator.pop(context, produto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar produto')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _pesquisaController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome ou categoria',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _pesquisaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _pesquisaController.clear,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(child: _buildConteudo()),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

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
                onPressed: _carregarProdutos,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final produtos = _produtosFiltrados;

    if (produtos.isEmpty) {
      final pesquisando = _pesquisaController.text.trim().isNotEmpty;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 56),
              const SizedBox(height: 16),
              Text(
                pesquisando
                    ? 'Nenhum produto encontrado.'
                    : 'Nenhum produto cadastrado.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      itemCount: produtos.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final produto = produtos[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
          title: Text(
            produto.nome,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Categoria: ${_nomeCategoria(produto)}'),
              Text(
                'R\$ ${produto.preco.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                'Quantidade em estoque: ${produto.quantidade}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: produto.quantidade <= 10 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _selecionarProduto(produto),
        );
      },
    );
  }
}
