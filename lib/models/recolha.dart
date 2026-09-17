//classe para controlar a data de recolha das chopeiras entregues em um pedido
class Recolha {
  final String id;
  final String pedidoId;
  final String endereco; //endereço de recolha da chopeira
  final DateTime dataRecolha;
  final bool recolhida; //indica se a chopeira foi recolhida ou não
  final String? observacao;

  Recolha({
    required this.id,
    required this.pedidoId,
    required this.endereco,
    required this.dataRecolha,
    required this.recolhida,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'pedidoId': pedidoId,
      'endereco': endereco,
      'dataRecolha': dataRecolha.toIso8601String(),
      'recolhida': recolhida,
    };
  }

  factory Recolha.fromMap(Map<String, dynamic> map, String id) {
    return Recolha(
      id: id,
      pedidoId: map['pedidoId'],
      endereco: map['endereco'],
      dataRecolha: DateTime.parse(map['dataRecolha']),
      recolhida: map['recolhida'] ?? false,
      observacao: map['observacao'],
    );
  }
}
