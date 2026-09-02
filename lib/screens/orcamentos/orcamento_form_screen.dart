import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../models/produto.dart';
import '../../models/tipo_produto.dart';
import '../../services/cliente_service.dart';
import '../../services/produto_service.dart';
import '../../models/orcamento.dart';
import '../../services/orcamento_service.dart';

class OrcamentoFormScreen extends StatefulWidget {
  const OrcamentoFormScreen({Key? key}) : super(key: key);

  @override
  State<OrcamentoFormScreen> createState() => _OrcamentoFormScreenState();
}

class _OrcamentoFormScreenState extends State<OrcamentoFormScreen> {
  late ClienteService _clienteService;
  late ProdutoService _produtoService;
  late OrcamentoService _orcamentoService;

  Cliente? selectedClient;
  final List<Map<String, dynamic>> products = [];

  double get totalValue {
    return products.fold(
      0,
      (sum, product) => sum + (product['price'] * product['quantity']),
    );
  }

  @override
  void initState() {
    super.initState();
    _clienteService = ClienteService();
    _produtoService = ProdutoService();
    _orcamentoService = OrcamentoService();
  }

  void addProduct(Produto produto) {
    setState(() {
      final existingProduct = products.firstWhere(
        (p) => p['id'] == produto.id,
        orElse: () => {},
      );

      if (existingProduct.isNotEmpty) {
        existingProduct['quantity']++;
      } else {
        products.add({
          'id': produto.id,
          'name': produto.nome,
          'price': produto.preco,
          'quantity': 1,
        });
      }
    });
  }

  void removeProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
  }

  void updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity > 0) {
        products[index]['quantity'] = newQuantity;
      } else {
        removeProduct(index);
      }
    });
  }

  void submitOrder() async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um produto')),
      );
      return;
    }

    try {
      // Criar lista de produtos do orçamento
      final produtosOrcamento = products.map((p) {
        return Produto(
          id: p['id'],
          nome: p['name'],
          preco: p['price'],
          tipo: TipoProduto.cerveja, // Você pode melhorar isso depois
        );
      }).toList();

      // Criar objeto Orcamento
      final orcamento = Orcamento(
        id: '',
        cliente: selectedClient,
        produtos: produtosOrcamento,
        valorTotal: totalValue,
      );

      // Salvar no banco de dados
      await _orcamentoService.adicionarOrcamento(orcamento);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Orçamento cadastrado com sucesso!\nTotal: R\$ ${totalValue.toStringAsFixed(2)}',
            ),
          ),
        );

        // Limpar formulário
        setState(() {
          selectedClient = null;
          products.clear();
        });

        // Voltar para tela anterior
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar orçamento: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Orçamento'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cliente (Opcional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<Cliente>>(
              stream: _clienteService.listarClientes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clientes = snapshot.data ?? [];

                return DropdownButtonFormField<Cliente?>(
                  initialValue: selectedClient,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Selecione um cliente'),
                    ),
                    ...clientes.map(
                      (cliente) => DropdownMenuItem(
                        value: cliente,
                        child: Text(cliente.nome),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedClient = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Adicionar Produtos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Produto>>(
              stream: _produtoService.listarProdutos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                final produtos = snapshot.data ?? [];

                if (produtos.isEmpty) {
                  return const Center(child: Text('Nenhum produto disponível'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: produtos.length,
                  itemBuilder: (context, index) {
                    final produto = produtos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(
                          '${produto.nome} - R\$ ${produto.preco.toStringAsFixed(2)}',
                        ),
                        onPressed: () => addProduct(produto),
                        style: ElevatedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            if (products.isNotEmpty) ...[
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
                  itemCount: products.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    final product = products[index];
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
              const SizedBox(height: 16),
            ],
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
                onPressed: submitOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cadastrar Orçamento',
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
