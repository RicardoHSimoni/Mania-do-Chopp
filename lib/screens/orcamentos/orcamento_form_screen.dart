import 'package:flutter/material.dart';
import 'package:flutter_app/screens/clientes/cliente_search_screen.dart';

import '../../models/cliente.dart';
import '../../models/produto.dart';
import '../../models/orcamento.dart';
import '../../models/orcamento_item.dart';
import '../../services/cliente_service.dart';
import '../../services/produto_service.dart';
import '../../services/orcamento_service.dart';
import '../pedidos/pedido_form_screen.dart';

class OrcamentoFormScreen extends StatefulWidget {
  const OrcamentoFormScreen({Key? key}) : super(key: key);

  @override
  State<OrcamentoFormScreen> createState() => _OrcamentoFormScreenState();
}

class _OrcamentoFormScreenState extends State<OrcamentoFormScreen> {
  late ClienteService _clienteService;
  late ProdutoService _produtoService;
  late OrcamentoService _orcamentoService;

  Cliente? _selectedCliente;
  final List<OrcamentoItem> products = [];
  final TextEditingController _descontoController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();

  double get totalValue {
    return products.fold(0, (sum, product) => sum + product.valorTotal);
  }

  double get descontoTotal {
    return double.tryParse(_descontoController.text) ?? 0;
  }

  double get valorFinal {
    return (totalValue - descontoTotal).clamp(0, double.infinity);
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

  Orcamento get currentOrcamento => Orcamento(
    id: '',
    clienteId: _selectedCliente?.id,
    produtos: products,
    valorTotal: valorFinal,
    dataCriacao: DateTime.now(),
    desconto: descontoTotal,
    observacao: _observacaoController.text.isEmpty
        ? null
        : _observacaoController.text,
  );

  @override
  void initState() {
    super.initState();
    _clienteService = ClienteService();
    _produtoService = ProdutoService();
    _orcamentoService = OrcamentoService();
  }

  void addProduct(Produto produto) {
    setState(() {
      final existingProductIndex = products.indexWhere(
        (p) => p.produtoId == produto.id,
      );

      if (existingProductIndex != -1) {
        final item = products[existingProductIndex];
        products[existingProductIndex] = OrcamentoItem(
          id: item.id,
          produtoId: item.produtoId,
          nomeProduto: item.nomeProduto,
          valorUnitario: item.valorUnitario,
          quantidade: item.quantidade + 1,
          desconto: item.desconto,
        );
      } else {
        products.add(
          OrcamentoItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            produtoId: produto.id,
            nomeProduto: produto.nome,
            valorUnitario: produto.preco,
            quantidade: 1,
            desconto: 0,
          ),
        );
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
        final item = products[index];
        products[index] = OrcamentoItem(
          id: item.id,
          produtoId: item.produtoId,
          nomeProduto: item.nomeProduto,
          valorUnitario: item.valorUnitario,
          quantidade: newQuantity,
          desconto: item.desconto,
        );
      } else {
        removeProduct(index);
      }
    });
  }

  void submitOrder(bool vaiVirarPedido) async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um produto')),
      );
      return;
    }

    try {
      // Criar objeto Orcamento
      final orcamento = Orcamento(
        id: '',
        clienteId: _selectedCliente?.id,
        produtos: products,
        valorTotal: valorFinal,
        dataCriacao: DateTime.now(),
        desconto: descontoTotal,
        observacao: _observacaoController.text.isEmpty
            ? null
            : _observacaoController.text,
      );

      // Salvar no banco de dados
      final orcamentoSalvo = await _orcamentoService.adicionarOrcamento(
        orcamento,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Orçamento cadastrado com sucesso!\nTotal: R\$ ${valorFinal.toStringAsFixed(2)}',
            ),
          ),
        );

        // Limpar formulário
        setState(() {
          _selectedCliente = null;
          products.clear();
          _descontoController.clear();
          _observacaoController.clear();
        });

        // Voltar para tela anterior
        if (vaiVirarPedido) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PedidoFormScreen(orcamento: orcamentoSalvo),
            ),
          );
        } else {
          Navigator.pop(context);
        }
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
  void dispose() {
    _descontoController.dispose();
    _observacaoController.dispose();
    super.dispose();
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
            OutlinedButton.icon(
              onPressed: _selecionarCliente,
              icon: const Icon(Icons.person_search),
              label: Text(
                _selectedCliente == null
                    ? 'Selecionar cliente'
                    : _selectedCliente!.nome,
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
                    final item = products[index];
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
                                  item.nomeProduto,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'R\$ ${item.valorUnitario.toStringAsFixed(2)}',
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
                                onPressed: () =>
                                    updateQuantity(index, item.quantidade - 1),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${item.quantidade}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () =>
                                    updateQuantity(index, item.quantidade + 1),
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
                              'R\$ ${item.valorTotal.toStringAsFixed(2)}',
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
            const Text(
              'Desconto (Opcional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descontoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Observação (Opcional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _observacaoController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Digite uma observação...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'R\$ ${totalValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Desconto:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '- R\$ ${descontoTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.blue.shade200),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total do Orçamento',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'R\$ ${valorFinal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => submitOrder(false),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => submitOrder(true),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Gerar Pedido',
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
