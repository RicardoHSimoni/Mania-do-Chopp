import 'tipo_produto.dart';

class Produto {
  final String id;
  final String nome;
  final double preco;
  final TipoProduto tipo;
  final int quantidade;

  Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.tipo,
    this.quantidade = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'preco': preco,
      'tipo': tipo.toString().split('.').last,
      'quantidade': quantidade,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map, String id) {
    return Produto(
      id: id,
      nome: map['nome'] as String,
      preco: map['preco'] as double,
      tipo: TipoProduto.values.firstWhere(
        (e) => e.toString().split('.').last == map['tipo'],
      ),
      quantidade: map['quantidade'] as int,
    );
  }
}
