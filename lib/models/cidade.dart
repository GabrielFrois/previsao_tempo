class Cidade {
  final int id;
  final String nome;
  final String uf;

  const Cidade({required this.id, required this.nome, required this.uf});

  /// Texto exibido nas listas, por exemplo "Jacareí - SP".
  String get rotulo => uf.isEmpty ? nome : '$nome - $uf';

  Map<String, Object?> toMap() => {'id': id, 'nome': nome, 'uf': uf};

  factory Cidade.fromMap(Map<String, Object?> map) {
    return Cidade(
      id: map['id'] as int,
      nome: map['nome'] as String,
      uf: (map['uf'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) => other is Cidade && other.id == id;

  @override
  int get hashCode => id.hashCode;
}