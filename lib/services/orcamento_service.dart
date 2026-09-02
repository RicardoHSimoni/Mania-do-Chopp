import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/orcamento_item.dart';

import '../models/orcamento.dart';

class OrcamentoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'orcamentos';

  // Criar orçamento
  Future<void> adicionarOrcamento(Orcamento orcamento) async {
    await _firestore.collection(_collection).add(orcamento.toMap());
  }

  // Buscar todos os orçamentos
  Stream<List<Orcamento>> listarOrcamentos() {
    return _firestore
        .collection(_collection)
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Orcamento.fromMap(doc.data(), doc.id);
          }).toList();
        })
        .handleError((error) {
          print('Erro ao listar orçamentos: $error');
          return <Orcamento>[];
        });
  }

  // Buscar um orçamento pelo ID
  Future<Orcamento?> buscarOrcamento(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return Orcamento.fromMap(doc.data()!, doc.id);
  }

  // Atualizar orçamento
  Future<void> atualizarOrcamento(Orcamento orcamento) async {
    await _firestore
        .collection(_collection)
        .doc(orcamento.id)
        .update(orcamento.toMap());
  }

  // Excluir orçamento
  Future<void> excluirOrcamento(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  int getQuantidadeTotal(List<OrcamentoItem> itens) {
    return itens.fold(0, (total, item) => total + item.quantidade);
  }
}
