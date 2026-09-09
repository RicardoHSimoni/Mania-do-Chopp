import 'enum_chopeira.dart';

class Chopeira {
  final int id;
  final VoltagemChopeira voltagem;
  final ModeloChopeira modelo;
  final StatusChopeira status;

  Chopeira({
    required this.id,
    required this.voltagem,
    required this.modelo,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'voltagem': voltagem.toString().split('.').last,
      'modelo': modelo.toString().split('.').last,
      'status': status.toString().split('.').last,
    };
  }

  factory Chopeira.fromMap(Map<String, dynamic> map, String id) {
    return Chopeira(
      id: int.parse(id),
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
}
