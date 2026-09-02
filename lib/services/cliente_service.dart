import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cliente.dart';

class ClienteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'clientes';

  // Criar cliente
  Future<void> adicionarCliente(Cliente cliente) async {
    await _firestore.collection(_collection).add(cliente.toMap());
  }

  // Buscar todos os clientes
  Stream<List<Cliente>> listarClientes() {
    return _firestore
        .collection(_collection)
        .orderBy('nome')
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Cliente.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Buscar um cliente pelo ID
  Future<Cliente?> buscarCliente(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return Cliente.fromMap(doc.data()!, doc.id);
  }

  // Atualizar cliente
  Future<void> atualizarCliente(Cliente cliente) async {
    if (cliente.id == null) {
      throw Exception('Cliente não possui ID.');
    }

    await _firestore
        .collection(_collection)
        .doc(cliente.id)
        .update(cliente.toMap());
  }

  // Excluir cliente
  Future<void> excluirCliente(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
