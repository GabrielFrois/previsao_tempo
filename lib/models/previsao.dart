import 'cidade.dart';

/// Previsão de um único dia
class PrevisaoDia {
  final DateTime data;
  final double? minima;
  final double? maxima;

  /// Sigla da condição do tempo (ex.: "ps", "pn", "c").
  final String? sigla;

  /// Índice ultravioleta, quando disponível.
  final double? iuv;

  const PrevisaoDia({
    required this.data,
    this.minima,
    this.maxima,
    this.sigla,
    this.iuv,
  });

  Map<String, Object?> toJson() => {
        'data': data.toIso8601String(),
        'minima': minima,
        'maxima': maxima,
        'sigla': sigla,
        'iuv': iuv,
      };

  factory PrevisaoDia.fromJson(Map<String, Object?> json) {
    return PrevisaoDia(
      data: DateTime.parse(json['data'] as String),
      minima: (json['minima'] as num?)?.toDouble(),
      maxima: (json['maxima'] as num?)?.toDouble(),
      sigla: json['sigla'] as String?,
      iuv: (json['iuv'] as num?)?.toDouble(),
    );
  }
}

/// Previsão de quatro dias para uma cidade.
class Previsao {
  final Cidade cidade;

  /// Data de atualização informada pelo serviço, quando presente.
  final DateTime? atualizacao;
  final List<PrevisaoDia> dias;

  const Previsao({
    required this.cidade,
    required this.atualizacao,
    required this.dias,
  });

  bool get estaVazia => dias.isEmpty;

  Map<String, Object?> toJson() => {
        'cidade': cidade.toMap(),
        'atualizacao': atualizacao?.toIso8601String(),
        'dias': dias.map((dia) => dia.toJson()).toList(),
      };

  factory Previsao.fromJson(Map<String, Object?> json) {
    final cidade = Cidade.fromMap(
      (json['cidade'] as Map).cast<String, Object?>(),
    );
    final atualizacao = json['atualizacao'] as String?;
    final dias = (json['dias'] as List)
        .map((item) =>
            PrevisaoDia.fromJson((item as Map).cast<String, Object?>()))
        .toList();

    return Previsao(
      cidade: cidade,
      atualizacao: atualizacao == null ? null : DateTime.tryParse(atualizacao),
      dias: dias,
    );
  }
}