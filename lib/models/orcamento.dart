import 'cliente.dart';
import 'produto.dart';

class Orcamento {
  final String id;
  final Cliente cliente; //opcional, pode ser null
  final List<Produto> produtos; // se o orçamento incluir barril de chopp, no pedido precisa ter  chopeira
  final double valorTotal;

  Orcamento({
    required this.id,
    required this.cliente,
    required this.produtos,
    required this.valorTotal,
  });
}
