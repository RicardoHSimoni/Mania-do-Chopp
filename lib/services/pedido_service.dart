import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pedido.dart';
import '../services/recolha_service.dart';

/// Lançada quando se tenta gerar um pedido para um orçamento que já
/// possui um pedido gerado anteriormente.
class PedidoJaGeradoException implements Exception {
  final String message;

  PedidoJaGeradoException([
    this.message = 'Este orçamento já possui um pedido gerado.',
  ]);

  @override
  String toString() => message;
}

class PedidoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'pedidos';
  final String _orcamentosCollection = 'orcamentos';

  final _recolhaService = RecolhaService();

  // Criar pedido
  Future<void> adicionarPedido(Pedido pedido) async {
    await _firestore.collection(_collection).add(pedido.toMap());
  }

  /// Cria um pedido vinculado a um orçamento garantindo, de forma atômica,
  /// que aquele orçamento ainda não gerou nenhum outro pedido.
  ///
  /// Evita a condição de corrida em que dois toques em "Gerar Pedido"
  /// (ou duas abas/dispositivos) criariam dois pedidos para o mesmo
  /// orçamento.
  Future<void> criarPedidoParaOrcamento(Pedido pedido) async {
    final orcamentoRef = _firestore
        .collection(_orcamentosCollection)
        .doc(pedido.orcamentoId);
    final pedidoRef = _firestore.collection(_collection).doc();

    await _firestore.runTransaction((transaction) async {
      final orcamentoSnap = await transaction.get(orcamentoRef);

      if (!orcamentoSnap.exists) {
        throw Exception('Orçamento não encontrado.');
      }

      final dados = orcamentoSnap.data()!;
      final pedidoJaGerado = dados['pedidoGerado'] as bool? ?? false;

      if (pedidoJaGerado) {
        throw PedidoJaGeradoException();
      }

      transaction.set(pedidoRef, pedido.toMap());
      transaction.update(orcamentoRef, {'pedidoGerado': true});
    });
  }

  // Buscar todos os pedidos
  Stream<List<Pedido>> listarPedidos() {
    return _firestore
        .collection(_collection)
        .orderBy('dataEntrega')
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

  Future<void> marcarComoEntregue(Pedido pedido) async {
    await _firestore.collection('pedidos').doc(pedido.id).update({
      'entregue': true,
    });

    if (pedido.chopeirasSelecionadas?.isNotEmpty == true) {
      await _recolhaService.criarRecolha(pedido);
    }
  }
}
