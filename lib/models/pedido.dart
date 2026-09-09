import 'package:cloud_firestore/cloud_firestore.dart';

class Pedido {
  final String id;
  final String clienteId;
  final String orcamentoId;
  final DateTime dataEntrega;
  final String enderecoEntrega;
  final String observacoes;
  final bool entregue;
  final bool pago;

  Pedido({
    required this.id,
    required this.clienteId,
    required this.orcamentoId,
    required this.dataEntrega,
    required this.enderecoEntrega,
    required this.observacoes,
    required this.entregue,
    required this.pago,
  });

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'orcamentoId': orcamentoId,
      'dataEntrega': dataEntrega,
      'enderecoEntrega': enderecoEntrega,
      'observacoes': observacoes,
      'entregue': entregue,
      'pago': pago,
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map, String id) {
    DateTime dataEntrega;

    if (map['dataEntrega'] is Timestamp) {
      dataEntrega = (map['dataEntrega'] as Timestamp).toDate();
    } else if (map['dataEntrega'] is DateTime) {
      dataEntrega = map['dataEntrega'] as DateTime;
    } else {
      dataEntrega = DateTime.now();
    }

    return Pedido(
      id: id,
      clienteId: map['clienteId'] as String? ?? '',
      orcamentoId: map['orcamentoId'] as String? ?? '',
      dataEntrega: dataEntrega,
      enderecoEntrega: map['enderecoEntrega'] as String? ?? '',
      observacoes: map['observacoes'] as String? ?? '',
      entregue: map['entregue'] as bool? ?? false,
      pago: map['pago'] as bool? ?? false,
    );
  }
}
