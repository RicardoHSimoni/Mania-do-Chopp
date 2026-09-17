import 'package:cloud_firestore/cloud_firestore.dart';

class RecolhaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'recolhas';

  // Criar recolha
  Future<void> adicionarRecolha(Map<String, dynamic> recolha) async {
    await _firestore.collection(_collection).add(recolha);
  }

  // Buscar todas as recolhas
  Stream<List<Map<String, dynamic>>> listarRecolhas() {
    return _firestore
        .collection(_collection)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }
}
