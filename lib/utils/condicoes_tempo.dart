import 'package:flutter/material.dart';

/// Agrupa as condições do tempo para escolher o ícone.
enum CategoriaTempo {
  sol,
  parcialmenteNublado,
  nublado,
  chuva,
  pancadas,
  tempestade,
  neve,
  nevoeiro,
  indefinido,
}

class CondicaoTempo {
  final String descricao;
  final CategoriaTempo categoria;

  const CondicaoTempo(this.descricao, this.categoria);
}

/// Tabela de siglas do CPTEC/INPE.
const Map<String, CondicaoTempo> _condicoes = {
  'ec': CondicaoTempo('Encoberto com chuvas isoladas', CategoriaTempo.chuva),
  'ci': CondicaoTempo('Chuvas isoladas', CategoriaTempo.chuva),
  'c': CondicaoTempo('Chuva', CategoriaTempo.chuva),
  'in': CondicaoTempo('Instável', CategoriaTempo.pancadas),
  'pp': CondicaoTempo('Possibilidade de pancadas de chuva', CategoriaTempo.pancadas),
  'cm': CondicaoTempo('Chuva pela manhã', CategoriaTempo.chuva),
  'cn': CondicaoTempo('Chuva à noite', CategoriaTempo.chuva),
  'pt': CondicaoTempo('Pancadas de chuva à tarde', CategoriaTempo.pancadas),
  'pm': CondicaoTempo('Pancadas de chuva pela manhã', CategoriaTempo.pancadas),
  'np': CondicaoTempo('Nublado e pancadas de chuva', CategoriaTempo.pancadas),
  'pc': CondicaoTempo('Pancadas de chuva', CategoriaTempo.pancadas),
  'pn': CondicaoTempo('Parcialmente nublado', CategoriaTempo.parcialmenteNublado),
  'cv': CondicaoTempo('Chuvisco', CategoriaTempo.chuva),
  'ch': CondicaoTempo('Chuvoso', CategoriaTempo.chuva),
  't': CondicaoTempo('Tempestade', CategoriaTempo.tempestade),
  'ps': CondicaoTempo('Predomínio de sol', CategoriaTempo.sol),
  'e': CondicaoTempo('Encoberto', CategoriaTempo.nublado),
  'n': CondicaoTempo('Nublado', CategoriaTempo.nublado),
  'cl': CondicaoTempo('Céu claro', CategoriaTempo.sol),
  'nv': CondicaoTempo('Nevoeiro', CategoriaTempo.nevoeiro),
  'g': CondicaoTempo('Geada', CategoriaTempo.neve),
  'ne': CondicaoTempo('Neve', CategoriaTempo.neve),
  'nd': CondicaoTempo('Não definido', CategoriaTempo.indefinido),
  'pnt': CondicaoTempo('Pancadas de chuva à noite', CategoriaTempo.pancadas),
  'psc': CondicaoTempo('Possibilidade de chuva', CategoriaTempo.chuva),
  'pcm': CondicaoTempo('Possibilidade de chuva pela manhã', CategoriaTempo.chuva),
  'pct': CondicaoTempo('Possibilidade de chuva à tarde', CategoriaTempo.chuva),
  'pcn': CondicaoTempo('Possibilidade de chuva à noite', CategoriaTempo.chuva),
  'npt': CondicaoTempo('Nublado com pancadas à tarde', CategoriaTempo.pancadas),
  'npn': CondicaoTempo('Nublado com pancadas à noite', CategoriaTempo.pancadas),
  'ncn': CondicaoTempo('Nublado com possibilidade de chuva à noite', CategoriaTempo.chuva),
  'nct': CondicaoTempo('Nublado com possibilidade de chuva à tarde', CategoriaTempo.chuva),
  'ncm': CondicaoTempo('Nublado com possibilidade de chuva pela manhã', CategoriaTempo.chuva),
  'npm': CondicaoTempo('Nublado com pancadas de chuva pela manhã', CategoriaTempo.pancadas),
  'npp': CondicaoTempo('Nublado com possibilidade de chuva', CategoriaTempo.chuva),
  'vn': CondicaoTempo('Variação de nebulosidade', CategoriaTempo.parcialmenteNublado),
  'ct': CondicaoTempo('Chuva à tarde', CategoriaTempo.chuva),
  'ppn': CondicaoTempo('Possibilidade de pancadas de chuva à noite', CategoriaTempo.pancadas),
  'ppt': CondicaoTempo('Possibilidade de pancadas de chuva à tarde', CategoriaTempo.pancadas),
  'ppm': CondicaoTempo('Possibilidade de pancadas de chuva pela manhã', CategoriaTempo.pancadas),
};

/// Converte a sigla do serviço em descrição e categoria.
CondicaoTempo condicaoDaSigla(String? sigla) {
  final chave = sigla?.trim().toLowerCase();

  if (chave == null || chave.isEmpty) {
    return const CondicaoTempo(
      'Condição não informada',
      CategoriaTempo.indefinido,
    );
  }

  return _condicoes[chave] ??
      CondicaoTempo(
        'Condição não reconhecida ($chave)',
        CategoriaTempo.indefinido,
      );
}

/// Ícone local para a categoria da condição.
IconData iconeDaCondicao(CondicaoTempo condicao) {
  switch (condicao.categoria) {
    case CategoriaTempo.sol:
      return Icons.wb_sunny;
    case CategoriaTempo.parcialmenteNublado:
      return Icons.wb_cloudy;
    case CategoriaTempo.nublado:
      return Icons.cloud;
    case CategoriaTempo.chuva:
      return Icons.water_drop;
    case CategoriaTempo.pancadas:
      return Icons.grain;
    case CategoriaTempo.tempestade:
      return Icons.thunderstorm;
    case CategoriaTempo.neve:
      return Icons.ac_unit;
    case CategoriaTempo.nevoeiro:
      return Icons.foggy;
    case CategoriaTempo.indefinido:
      return Icons.help_outline;
  }
}