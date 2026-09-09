import 'package:flutter/material.dart';

import '../../models/produto.dart';
import '../../services/produto_service.dart';

class ProdutoScreen extends StatefulWidget {
  const ProdutoScreen({Key? key}) : super(key: key);

  @override
  State<ProdutoScreen> createState() => _ProdutoScreenState();
}

class _ProdutoScreenState extends State<ProdutoScreen> {
  late ProdutoService _produtoService;
  final TextEditingController _searchController = TextEditingController();
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _produtoService = ProdutoService();
    _searchController.addListener(() {
      setState(() {
        _filtro = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _excluirProduto(BuildContext context, Produto produto) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text('Deseja realmente excluir o produto ${produto.nome}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmacao == true && mounted) {
      try {
        await _produtoService.excluirProduto(produto.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto excluído com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
        }
      }
    }
  }

  void _exibirDetalhes(BuildContext context, Produto produto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Detalhes do Produto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _construirDetalhe('Nome', produto.nome),
                    _construirDetalhe(
                      'Tipo',
                      produto.tipo.toString().split('.').last,
                    ),
                    _construirDetalhe(
                      'Preço',
                      'R\$ ${produto.preco.toStringAsFixed(2)}',
                    ),
                    _construirDetalhe(
                      'Quantidade em estoque',
                      produto.quantidade.toString(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/produtos/produto_update_screen',
                              arguments: produto,
                            ),
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _excluirProduto(context, produto),
                            icon: const Icon(Icons.delete),
                            label: const Text('Excluir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _construirDetalhe(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome ou categoria',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Produto>>(
              stream: _produtoService.listarProdutos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar produtos: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final produtos = snapshot.data ?? [];

                if (produtos.isEmpty) {
                  return const Center(child: Text('Nenhum produto cadastrado'));
                }

                // Filtrar produtos por nome ou tipo
                final produtosFiltrados = _filtro.isEmpty
                    ? produtos
                    : produtos
                          .where(
                            (produto) =>
                                produto.nome.toLowerCase().contains(_filtro) ||
                                produto.tipo
                                    .toString()
                                    .split('.')
                                    .last
                                    .toLowerCase()
                                    .contains(_filtro),
                          )
                          .toList();

                if (produtosFiltrados.isEmpty) {
                  return const Center(child: Text('Nenhum produto encontrado'));
                }

                return ListView.builder(
                  itemCount: produtosFiltrados.length,
                  itemBuilder: (context, index) {
                    final produto = produtosFiltrados[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_bag),
                        title: Text(produto.nome),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipo: ${produto.tipo.toString().split('.').last}',
                            ),
                            Text(
                              'Preço: R\$ ${produto.preco.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Quantidade em estoque: ${produto.quantidade}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: produto.quantidade < 5
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () => _exibirDetalhes(context, produto),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Detalhes'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, '/produtos/produto_form_screen'),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
