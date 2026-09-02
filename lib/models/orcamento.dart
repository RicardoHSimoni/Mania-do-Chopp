import 'cliente.dart';
import 'produto.dart';

class Orcamento {
  final String? id;
  final Cliente? cliente; //opcional, pode ser null
  final List<Produto> produtos; // se o orçamento incluir barril de chopp, no pedido precisa ter  chopeira
  final double valorTotal;

  Orcamento({
    this.id,
    this.cliente,
    required this.produtos,
    required this.valorTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'cliente': cliente?.toMap(),
      'produtos': produtos.map((produto) => produto.toMap()).toList(),
      'valorTotal': valorTotal,
    };
  }

  factory Orcamento.fromMap(Map<String, dynamic> map, String id) {
    return Orcamento(
      id: id,
      cliente: map['cliente'] != null
          ? Cliente.fromMap(map['cliente'], '')
          : null,
      produtos: (map['produtos'] as List<dynamic>)
          .map((produtoMap) => Produto.fromMap(produtoMap, ''))
          .toList(),
      valorTotal: map['valorTotal'] as double,
    );
  }
}
