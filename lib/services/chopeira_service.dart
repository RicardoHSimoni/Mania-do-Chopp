import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chopeira.dart';
import '../models/enum_chopeira.dart';

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

  // Atualizar chopeira
  Future<void> atualizarChopeira(Chopeira chopeira) async {
    await _firestore
        .collection(_collection)
        .doc(chopeira.id)
        .update(chopeira.toMap());
  }

  // Excluir chopeira
  Future<void> excluirChopeira(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<List<Chopeira>> buscarPorCodigos(List<int> codigos) async {
    final resultado = <Chopeira>[];
    // O Firestore limita o whereIn a 30 valores por consulta.
    for (var i = 0; i < codigos.length; i += 30) {
      final fim = (i + 30 > codigos.length) ? codigos.length : i + 30;
      final snap = await _firestore
          .collection(_collection)
          .where('codigo', whereIn: codigos.sublist(i, fim))
          .get();
      resultado.addAll(snap.docs.map((d) => Chopeira.fromMap(d.data(), d.id)));
    }
    return resultado;
  }

  Future<void> atualizarStatusPorCodigos(
    List<int> codigos,
    StatusChopeira status,
  ) async {
    if (codigos.isEmpty) return;
    final chopeiras = await buscarPorCodigos(codigos);
    final batch = _firestore.batch();
    for (final c in chopeiras) {
      batch.update(_firestore.collection(_collection).doc(c.id), {
        'status': status.toString().split('.').last,
      });
    }
    await batch.commit();
  }
}
