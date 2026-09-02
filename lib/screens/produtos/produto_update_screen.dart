import 'package:flutter/material.dart';

import '../../models/produto.dart';
import '../../models/tipo_produto.dart';
import '../../services/produto_service.dart';

class ProdutoUpdateScreen extends StatefulWidget {
  final Produto produto;

  const ProdutoUpdateScreen({
    super.key,
    required this.produto,
  });

  @override
  State<ProdutoUpdateScreen> createState() => _ProdutoUpdateScreenState();
}

class _ProdutoUpdateScreenState extends State<ProdutoUpdateScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _precoController;
  late TipoProduto _tipoSelecionado;

  final ProdutoService _produtoService = ProdutoService();

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.produto.nome);
    _precoController = TextEditingController(
      text: widget.produto.preco.toStringAsFixed(2),
    );
    _tipoSelecionado = widget.produto.tipo;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  Future<void> atualizarProduto() async {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome é obrigatório')),
      );
      return;
    }

    final preco = double.tryParse(_precoController.text);
    if (preco == null || preco <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preço inválido')),
      );
      return;
    }

    final produtoAtualizado = Produto(
      id: widget.produto.id,
      nome: _nomeController.text,
      preco: preco,
      tipo: _tipoSelecionado,
    );

    try {
      await _produtoService.atualizarProduto(produtoAtualizado);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Produto')),
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
                controller: _precoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preço'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TipoProduto>(
                value: _tipoSelecionado,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: TipoProduto.values
                    .map(
                      (tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo.toString().split('.').last),
                      ),
                    )
                    .toList(),
                onChanged: (tipo) {
                  if (tipo != null) {
                    setState(() {
                      _tipoSelecionado = tipo;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: atualizarProduto,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
