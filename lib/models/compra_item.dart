/// Item de uma [Compra]: produto comprado e a quantidade adquirida.
class CompraItem {
  final String produtoId;
  final String nomeProduto;
  final int quantidade;

  const CompraItem({
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidade,
  });

  CompraItem copyWith({int? quantidade}) {
    return CompraItem(
      produtoId: produtoId,
      nomeProduto: nomeProduto,
      quantidade: quantidade ?? this.quantidade,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtoId': produtoId,
      'nomeProduto': nomeProduto,
      'quantidade': quantidade,
    };
  }

  factory CompraItem.fromMap(Map<String, dynamic> map) {
    return CompraItem(
      produtoId: map['produtoId'] as String? ?? '',
      nomeProduto: map['nomeProduto'] as String? ?? '',
      quantidade: (map['quantidade'] as num?)?.toInt() ?? 0,
    );
  }
}
