import 'package:cloud_firestore/cloud_firestore.dart';

import 'compra_item.dart';

/// Compra de produtos para reposição de estoque.
class Compra {
  final String id;
  final List<CompraItem> itens;
  final DateTime dataCompra;
  final String? observacao; // opcional

  Compra({
    required this.id,
    required this.itens,
    required this.dataCompra,
    this.observacao,
  });

  /// Soma das quantidades de todos os itens.
  int get quantidadeTotal =>
      itens.fold(0, (total, item) => total + item.quantidade);

  Map<String, dynamic> toMap() {
    return {
      'itens': itens.map((item) => item.toMap()).toList(),
      'dataCompra': Timestamp.fromDate(dataCompra),
      'observacao': observacao,
    };
  }

  factory Compra.fromMap(Map<String, dynamic> map, String id) {
    DateTime dataCompra;

    if (map['dataCompra'] is Timestamp) {
      dataCompra = (map['dataCompra'] as Timestamp).toDate();
    } else if (map['dataCompra'] is DateTime) {
      dataCompra = map['dataCompra'] as DateTime;
    } else {
      dataCompra = DateTime.now();
    }

    return Compra(
      id: id,
      itens: (map['itens'] as List<dynamic>? ?? [])
          .map((item) => CompraItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      dataCompra: dataCompra,
      observacao: map['observacao'] as String?,
    );
  }
}
