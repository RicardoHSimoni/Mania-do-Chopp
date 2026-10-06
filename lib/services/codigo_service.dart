import 'package:cloud_firestore/cloud_firestore.dart';

Future<int> proximoCodigo(Transaction transaction, String entidade) async {
  final referencia = FirebaseFirestore.instance
      .collection('contadores')
      .doc(entidade);
  final snapshot = await transaction.get(referencia);
  final codigo = ((snapshot.data()?['ultimoCodigo'] as num?)?.toInt() ?? 0) + 1;

  transaction.set(referencia, {
    'ultimoCodigo': codigo,
  }, SetOptions(merge: true));
  return codigo;
}
