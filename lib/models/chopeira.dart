import 'enum_chopeira.dart';

class Chopeira {
  final String id;
  final int codigo;
  final VoltagemChopeira voltagem;
  final ModeloChopeira modelo;
  final StatusChopeira status;

  Chopeira({
    required this.id,
    required this.codigo,
    required this.voltagem,
    required this.modelo,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'voltagem': voltagem.toString().split('.').last,
      'modelo': modelo.toString().split('.').last,
      'status': status.toString().split('.').last,
    };
  }

  factory Chopeira.fromMap(Map<String, dynamic> map, String id) {
    return Chopeira(
      id: id,
      codigo: int.parse(map['codigo'].toString()),
      voltagem: VoltagemChopeira.values.firstWhere(
        (e) => e.toString().split('.').last == map['voltagem'],
      ),
      modelo: ModeloChopeira.values.firstWhere(
        (e) => e.toString().split('.').last == map['modelo'],
      ),
      status: StatusChopeira.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
      ),
    );
  }

  // Necessário para comparações e para o Set<Chopeira> usado na tela
  // de seleção funcionar corretamente mesmo quando o Stream do
  // Firestore reemite novas instâncias com o mesmo id.
  @override
  bool operator ==(Object other) => other is Chopeira && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
