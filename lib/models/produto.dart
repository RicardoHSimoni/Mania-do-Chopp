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

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'preco': preco,
      'tipo': tipo.toString().split('.').last,
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
    );
  }
}
