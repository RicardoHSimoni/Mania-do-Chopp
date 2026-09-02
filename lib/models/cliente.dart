class Cliente {
  final String? id;
  final String nome;
  final String cpf;
  final String email;
  final String telefone;
  final String endereco;
  final String numero;
  final String bairro;
  final String? observacao;

  Cliente({
    this.id,
    required this.nome,
    required this.cpf,
    required this.email,
    required this.telefone,
    required this.endereco,
    required this.numero,
    required this.bairro,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cpf': cpf,
      'email': email,
      'telefone': telefone,
      'endereco': endereco,
      'numero': numero,
      'bairro': bairro,
      'observacao': observacao,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map, String id) {
    return Cliente(
      id: id,
      nome: map['nome'] ?? '',
      cpf: map['cpf'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',
      endereco: map['endereco'] ?? '',
      numero: map['numero'] ?? '',
      bairro: map['bairro'] ?? '',
      observacao: map['observacao'],
    );
  }
}
