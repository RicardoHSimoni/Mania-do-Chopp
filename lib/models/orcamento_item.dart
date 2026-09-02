class OrcamentoItem {
  final String id;
  final String produtoId;
  final String nomeProduto;
  final double valorUnitario;
  final int quantidade;
  final double desconto;

  OrcamentoItem({
    required this.id,
    required this.produtoId,
    required this.nomeProduto,
    required this.valorUnitario,
    required this.quantidade,
    this.desconto = 0,
  });

  double get valorTotal {
    return (valorUnitario * quantidade) - desconto;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produtoId': produtoId,
      'nomeProduto': nomeProduto,
      'valorUnitario': valorUnitario,
      'quantidade': quantidade,
      'desconto': desconto,
      'valorTotal': valorTotal,
    };
  }

  factory OrcamentoItem.fromMap(Map<String, dynamic> map) {
    return OrcamentoItem(
      id: map['id'] as String? ?? '',
      produtoId: map['produtoId'] as String? ?? '',
      nomeProduto: map['nomeProduto'] as String? ?? '',
      valorUnitario: (map['valorUnitario'] as num?)?.toDouble() ?? 0.0,
      quantidade: (map['quantidade'] as num?)?.toInt() ?? 1,
      desconto: (map['desconto'] as num?)?.toDouble() ?? 0,
    );
  }
}
