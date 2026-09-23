import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mania_do_chopp/models/recolha.dart';

import '../models/pedido.dart';

class RecolhaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'recolhas';

  // Criar recolha
  Future<void> adicionarRecolha(Recolha recolha) async {
    await _firestore.collection(_collection).add(recolha.toMap());
  }

  // Buscar todas as recolhas
  Stream<List<Recolha>> listarRecolhas() {
    return _firestore
        .collection(_collection)
        .orderBy('dataRecolha', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Recolha.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Atualizar recolha (marcar como recolhida, reagendar, editar observação)
  Future<void> atualizarRecolha(Recolha recolha) async {
    await _firestore
        .collection(_collection)
        .doc(recolha.id)
        .update(recolha.toMap());
  }

  Future<void> criarRecolha(Pedido pedido) async {
    final recolhaExistente = await _firestore
        .collection(_collection)
        .where('pedidoId', isEqualTo: pedido.id)
        .limit(1)
        .get();

    if (recolhaExistente.docs.isNotEmpty) {
      return;
    }

    final recolha = Recolha(
      id: '',
      pedidoId: pedido.id,
      endereco: pedido.enderecoEntrega,
      dataRecolha: pedido.dataEntrega.add(Duration(days: 7)),
      recolhida: false,
      observacao: '',
    );

    await adicionarRecolha(recolha);
  }
}
