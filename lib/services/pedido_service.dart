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
}
