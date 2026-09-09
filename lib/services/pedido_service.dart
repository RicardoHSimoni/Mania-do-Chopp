import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pedido.dart';

class PedidoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'pedidos';

  // Criar pedido
  Future<void> adicionarPedido(Pedido pedido) async {
    await _firestore.collection(_collection).add(pedido.toMap());
  }

  // Buscar todos os pedidos
  Stream<List<Pedido>> listarPedidos() {
    return _firestore
        .collection(_collection)
        .orderBy('dataEntrega')
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Pedido.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Buscar um pedido pelo ID
  Future<Pedido?> buscarPedido(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return Pedido.fromMap(doc.data()!, doc.id);
  }

  // Atualizar pedido
  Future<void> atualizarPedido(Pedido pedido) async {
    await _firestore
        .collection(_collection)
        .doc(pedido.id)
        .update(pedido.toMap());
  }

  // Excluir pedido
  Future<void> excluirPedido(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<void> atualizarQuantidadeProdutosVendidos(String orcamentoId) async {
    final orcamentoDoc = await _firestore
        .collection('orcamentos')
        .doc(orcamentoId)
        .get();

    if (!orcamentoDoc.exists) {
      throw Exception('Orçamento não encontrado.');
    }

    final dados = orcamentoDoc.data()!;

    final produtos = dados['produtos'] as List<dynamic>;

    for (final item in produtos) {
      final produtoId = item['produtoId'] as String;
      final quantidadeVendida = item['quantidade'] as int;

      final produtoDoc = await _firestore
          .collection('produtos')
          .doc(produtoId)
          .get();

      if (!produtoDoc.exists) {
        throw Exception('Produto $produtoId não encontrado.');
      }

      final produtoData = produtoDoc.data()!;

      final estoqueAtual = (produtoData['quantidade'] ?? 0) as int;

      if (quantidadeVendida > estoqueAtual) {
        throw Exception('Estoque insuficiente para o produto $produtoId.');
      }

      await _firestore.collection('produtos').doc(produtoId).update({
        'quantidade': estoqueAtual - quantidadeVendida,
      });
    }
  }
}
