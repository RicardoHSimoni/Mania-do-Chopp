import 'package:cloud_firestore/cloud_firestore.dart';

class Pedido {
  final String id;
  final int codigo;
  final String clienteId;
  final String orcamentoId;
  final int orcamentoCodigo;
  final DateTime dataEntrega;
  final String enderecoEntrega;
  final String observacoes;
  final List<int>? chopeirasSelecionadas;
  final double valorTotal;
  final bool entregue;
  final bool pago;

  Pedido({
    required this.id,
    this.codigo = 0,
    required this.clienteId,
    required this.orcamentoId,
    this.orcamentoCodigo = 0,
    required this.dataEntrega,
    required this.enderecoEntrega,
    required this.observacoes,
    required this.chopeirasSelecionadas,
    required this.valorTotal,
    required this.entregue,
    required this.pago,
  });

  String get codigoFormatado =>
      codigo > 0 ? codigo.toString().padLeft(6, '0') : 'Sem código';

  String get codigoOrcamentoFormatado => orcamentoCodigo > 0
      ? orcamentoCodigo.toString().padLeft(6, '0')
      : 'Sem código';

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'clienteId': clienteId,
      'orcamentoId': orcamentoId,
      'orcamentoCodigo': orcamentoCodigo,
      'dataEntrega': dataEntrega,
      'enderecoEntrega': enderecoEntrega,
      'observacoes': observacoes,
      'chopeirasSelecionadas': chopeirasSelecionadas,
      'valorTotal': valorTotal,
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
      codigo: (map['codigo'] as num?)?.toInt() ?? 0,
      clienteId: map['clienteId'] as String? ?? '',
      orcamentoId: map['orcamentoId'] as String? ?? '',
      orcamentoCodigo: (map['orcamentoCodigo'] as num?)?.toInt() ?? 0,
      dataEntrega: dataEntrega,
      enderecoEntrega: map['enderecoEntrega'] as String? ?? '',
      observacoes: map['observacoes'] as String? ?? '',
      chopeirasSelecionadas: (map['chopeirasSelecionadas'] as List<dynamic>?)
          ?.cast<int>(),
      valorTotal: map['valorTotal'] as double? ?? 0.0,
      entregue: map['entregue'] as bool? ?? false,
      pago: map['pago'] as bool? ?? false,
    );
  }
}
