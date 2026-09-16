import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chopeira.dart';

class ChopeiraService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'chopeiras';

  // Criar chopeira
  Future<void> adicionarChopeira(Chopeira chopeira) async {
    await _firestore.collection(_collection).add(chopeira.toMap());
  }

  // Buscar todos as chopeiras
  Stream<List<Chopeira>> listarChopeiras() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Chopeira.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Buscar uma chopeira pelo ID
  Future<Chopeira?> buscarChopeira(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return Chopeira.fromMap(doc.data()!, doc.id);
  }

  /* Atualizar chopeira
  Future<void> atualizarChopeira(Chopeira chopeira) async {
    await _firestore
        .collection(_collection)
        .doc(chopeira.id)
        .update(chopeira.toMap());
  }*/

  // Excluir chopeira
  Future<void> excluirChopeira(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
