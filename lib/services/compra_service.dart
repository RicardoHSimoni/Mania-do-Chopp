import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/compra.dart';

class CompraService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'compras';
  final String _produtosCollection = 'produtos';

  /// Grava a compra e atualiza o estoque dos produtos comprados.
  ///
  /// Tudo é feito em um único [WriteBatch]: ou a compra é salva e o estoque
  /// de todos os produtos é atualizado, ou nada é alterado (por exemplo, se
  /// algum produto tiver sido excluído no meio do caminho).
  Future<Compra> registrarCompra(Compra compra) async {
    if (compra.itens.isEmpty) {
      throw Exception('A compra precisa ter pelo menos um produto.');
    }

    final compraRef = _firestore.collection(_collection).doc();
    final batch = _firestore.batch();

    batch.set(compraRef, compra.toMap());
    atualizarEstoqueProdutosComprados(batch, compra);

    await batch.commit();

    return Compra(
      id: compraRef.id,
      itens: compra.itens,
      dataCompra: compra.dataCompra,
      observacao: compra.observacao,
    );
  }

  /// Rotina de estoque: soma a quantidade comprada de cada item ao estoque
  /// atual do respectivo produto.
  ///
  /// Usa [FieldValue.increment], que é aplicado no servidor. Assim o valor
  /// não depende de uma leitura anterior e não se perde se outra operação
  /// (ex.: uma venda) alterar o estoque ao mesmo tempo.
  void atualizarEstoqueProdutosComprados(WriteBatch batch, Compra compra) {
    for (final item in compra.itens) {
      final produtoRef = _firestore
          .collection(_produtosCollection)
          .doc(item.produtoId);

      batch.update(produtoRef, {
        'quantidade': FieldValue.increment(item.quantidade),
      });
    }
  }

  // Buscar todas as compras (mais recentes primeiro)
  Stream<List<Compra>> listarCompras() {
    return _firestore
        .collection(_collection)
        .orderBy('dataCompra', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Compra.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Buscar uma compra pelo ID
  Future<Compra?> buscarCompra(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return Compra.fromMap(doc.data()!, doc.id);
  }
}
