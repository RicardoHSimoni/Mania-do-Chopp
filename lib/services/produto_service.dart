import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/produto.dart';

class ProdutoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'produtos';

  // Criar produto
  Future<void> adicionarProduto(Produto produto) async {
    await _firestore.collection(_collection).add(produto.toMap());
  }

  // Buscar todos os produtos
  Stream<List<Produto>> listarProdutos() {
    return _firestore
        .collection(_collection)
        .orderBy('nome')
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Produto.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Buscar um produto pelo ID
  Future<Produto?> buscarProduto(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return Produto.fromMap(doc.data()!, doc.id);
  }

  // Atualizar produto
  Future<void> atualizarProduto(Produto produto) async {
    await _firestore
        .collection(_collection)
        .doc(produto.id)
        .update(produto.toMap());
  }

  // Excluir produto
  Future<void> excluirProduto(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
