import 'package:flutter/material.dart';

import '../../models/produto.dart';
import '../../models/tipo_produto.dart';
import '../../services/produto_service.dart';

class ProdutoFormScreen extends StatefulWidget {
  final Produto? produto;

  const ProdutoFormScreen({Key? key, this.produto}) : super(key: key);

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _precoController;
  late TextEditingController _quantidadeController;
  TipoProduto? _tipoSelecionado;
  final _formKey = GlobalKey<FormState>();

  final ProdutoService _produtoService = ProdutoService();

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.produto?.nome ?? '');
    _precoController = TextEditingController(
      text: widget.produto?.preco.toString() ?? '',
    );
    _quantidadeController = TextEditingController(
      text: widget.produto?.quantidade.toString() ?? '0',
    );
    _tipoSelecionado = widget.produto?.tipo;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _quantidadeController.dispose();
    super.dispose();
  }

  void _salvarProduto() async {
    if (_formKey.currentState!.validate() && _tipoSelecionado != null) {
      final nome = _nomeController.text;
      final preco = double.parse(_precoController.text);
      final tipo = _tipoSelecionado!;
      final quantidade = int.parse(_quantidadeController.text);

      final novoProduto = Produto(
        id: widget.produto?.id ?? '', // Use o ID existente ou um novo
        nome: nome,
        preco: preco,
        tipo: tipo,
        quantidade: quantidade,
      );

      await _produtoService.adicionarProduto(novoProduto);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto salvo com sucesso!')),
      );

      Navigator.pop(context);
    } else if (_tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um tipo de produto')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.produto == null ? 'Novo Produto' : 'Editar Produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do produto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(
                  labelText: 'Preço',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o preço';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Insira um preço válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TipoProduto>(
                value: _tipoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Produto',
                  border: OutlineInputBorder(),
                ),
                items: TipoProduto.values.map((tipo) {
                  return DropdownMenuItem<TipoProduto>(
                    value: tipo,
                    child: Text(tipo.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoSelecionado = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, selecione um tipo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantidadeController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade em estoque atualmente: ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarProduto,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('Salvar Produto', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
