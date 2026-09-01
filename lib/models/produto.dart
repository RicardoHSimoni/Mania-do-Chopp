import 'tipo_produto.dart';

class Produto {
  final String id;
  final String nome;
  final double preco;
  final TipoProduto tipo;

  Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.tipo,
  });
}
