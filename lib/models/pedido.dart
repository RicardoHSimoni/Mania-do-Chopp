import 'cliente.dart';
import 'orcamento.dart';

class Pedido {
  final String id;
  final Cliente cliente;
  final Orcamento orcamento;
  final DateTime dataEntrega;
  final String enderecoEntrega;
  final String observacoes;
  final bool entregue;
  final bool pago;

  Pedido({
    required this.id,
    required this.cliente,
    required this.orcamento,
    required this.dataEntrega,
    required this.enderecoEntrega,
    required this.observacoes,
    required this.entregue,
    required this.pago,
  });
}
