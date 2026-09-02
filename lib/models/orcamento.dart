import 'package:cloud_firestore/cloud_firestore.dart';

import 'orcamento_item.dart';

class Orcamento {
  final String id;
  final String? clienteId; //opcional, pode ser null
  final List<OrcamentoItem> produtos; // se o orçamento incluir barril de chopp, no pedido precisa ter  chopeira
  final double valorTotal;
  final DateTime dataCriacao; //opcional, pode ser null
  final double desconto; //opcional, pode ser null
  final String? observacao; //opcional, pode ser null

  Orcamento({
    required this.id,
    this.clienteId,
    required this.produtos,
    required this.valorTotal,
    required this.dataCriacao,
    this.desconto = 0,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'produtos': produtos.map((produto) => produto.toMap()).toList(),
      'valorTotal': valorTotal,
      'dataCriacao': dataCriacao,
      'desconto': desconto,
      'observacao': observacao,
    };
  }

  factory Orcamento.fromMap(Map<String, dynamic> map, String id) {
    DateTime dataCriacao;

    if (map['dataCriacao'] is Timestamp) {
      dataCriacao = (map['dataCriacao'] as Timestamp).toDate();
    } else if (map['dataCriacao'] is DateTime) {
      dataCriacao = map['dataCriacao'] as DateTime;
    } else {
      dataCriacao = DateTime.now();
    }

    return Orcamento(
      id: id,
      clienteId: map['clienteId'],
      produtos: (map['produtos'] as List<dynamic>? ?? [])
          .map((produtoMap) => OrcamentoItem.fromMap(produtoMap))
          .toList(),
      valorTotal: (map['valorTotal'] as num?)?.toDouble() ?? 0.0,
      dataCriacao: dataCriacao,
      desconto: (map['desconto'] as num?)?.toDouble() ?? 0,
      observacao: map['observacao'] as String?,
    );
  }
}
