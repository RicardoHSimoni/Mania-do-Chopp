import 'package:flutter/material.dart';

import '../../models/orcamento.dart';
import '../../models/produto.dart';
import '../../services/orcamento_service.dart';

class OrcamentoUpdateScreen extends StatefulWidget {
  final Orcamento orcamento;

  const OrcamentoUpdateScreen({
    super.key,
    required this.orcamento,
  });

  @override
  State<OrcamentoUpdateScreen> createState() => _OrcamentoUpdateScreenState();
}

class _OrcamentoUpdateScreenState extends State<OrcamentoUpdateScreen> {
  late OrcamentoService _orcamentoService;
  late List<Map<String, dynamic>> _produtos;

  @override
  void initState() {
    super.initState();
    _orcamentoService = OrcamentoService();
    _produtos = widget.orcamento.produtos
        .map((p) => {
              'id': p.id,
              'name': p.nome,
              'price': p.preco,
              'quantity': 1,
            })
        .toList();
  }

  double get totalValue {
    return _produtos.fold(
      0,
      (sum, product) => sum + (product['price'] * product['quantity']),
    );
  }

  void removeProduct(int index) {
    setState(() {
      _produtos.removeAt(index);
    });
  }

  void updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity > 0) {
        _produtos[index]['quantity'] = newQuantity;
      } else {
        removeProduct(index);
      }
    });
  }

  Future<void> atualizarOrcamento() async {
    if (_produtos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um produto')),
      );
      return;
    }

    try {
      final produtosAtualizados = _produtos.map((p) {
        return Produto(
          id: p['id'],
          nome: p['name'],
          preco: p['price'],
          tipo: widget.orcamento.produtos
              .firstWhere((prod) => prod.id == p['id'])
              .tipo,
        );
      }).toList();

      final orcamentoAtualizado = Orcamento(
        id: widget.orcamento.id,
        cliente: widget.orcamento.cliente,
        produtos: produtosAtualizados,
        valorTotal: totalValue,
      );

      await _orcamentoService.atualizarOrcamento(orcamentoAtualizado);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orçamento atualizado com sucesso')),
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
      appBar: AppBar(title: const Text('Editar Orçamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.orcamento.cliente != null) ...[
              const Text(
                'Cliente',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.orcamento.cliente!.nome),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'Produtos Selecionados',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _produtos.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade300),
                itemBuilder: (context, index) {
                  final product = _produtos[index];
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'R\$ ${product['price'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => updateQuantity(
                                index,
                                product['quantity'] - 1,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${product['quantity']}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => updateQuantity(
                                index,
                                product['quantity'] + 1,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => removeProduct(index),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'R\$ ${(product['price'] * product['quantity']).toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total do Orçamento',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: atualizarOrcamento,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Salvar Alterações',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
