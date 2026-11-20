import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/cidade.dart';
import '../models/previsao.dart';

enum TipoErroCptec {
  semConexao,
  tempoEsgotado,
  servicoIndisponivel,
  respostaInvalida,
}

/// Erro de rede, de serviço ou de formato
class CptecException implements Exception {
  final TipoErroCptec tipo;
  final String mensagem;

  const CptecException(this.tipo, this.mensagem);

  @override
  String toString() => 'CptecException($tipo): $mensagem';
}

/// Acesso ao serviço XML do CPTEC/INPE
class CptecService {
  CptecService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Tenta HTTPS primeiro e usa HTTP como alternativa
  static const List<String> _bases = [
    'https://servicos.cptec.inpe.br',
    'http://servicos.cptec.inpe.br',
  ];

  static const Duration _limiteDeEspera = Duration(seconds: 15);

  /// Consulta localidades pelo nome (parâmetro `city`).
  /// Retorna lista vazia quando nenhuma cidade é encontrada.
  Future<List<Cidade>> buscarCidades(String nome) async {
    final termo = _semAcentos(nome.trim());
    final documento = await _obterXml('/XML/listaCidades', {'city': termo});

    final cidades = <Cidade>[];
    for (final elemento in documento.findAllElements('cidade')) {
      final id = int.tryParse(_texto(elemento, 'id') ?? '');
      final nomeCidade = _texto(elemento, 'nome');

      // Ignora registros incompletos ou inválidos
      if (id == null || nomeCidade == null || nomeCidade.isEmpty) continue;

      cidades.add(
        Cidade(id: id, nome: nomeCidade, uf: _texto(elemento, 'uf') ?? ''),
      );
    }
    return cidades;
  }

  /// Consulta a previsão de quatro dias da [cidade], usando o código retornado pelo próprio serviço.
  Future<Previsao> buscarPrevisao(Cidade cidade) async {
    final documento = await _obterXml('/XML/cidade/${cidade.id}/previsao.xml');
    final raiz = documento.rootElement;

    final dias = <PrevisaoDia>[];
    for (final elementoDia in raiz.findAllElements('dia')) {
      final data = DateTime.tryParse(elementoDia.innerText.trim());
      final bloco = elementoDia.parentElement;

      // Sem data ou sem o bloco que contém os demais campos o dia é inútil
      if (data == null || bloco == null) continue;

      dias.add(
        PrevisaoDia(
          data: data,
          minima: _numero(bloco, 'minima'),
          maxima: _numero(bloco, 'maxima'),
          sigla: _texto(bloco, 'tempo'),
          iuv: _numero(bloco, 'iuv'),
        ),
      );
    }
    dias.sort((a, b) => a.data.compareTo(b.data));

    return Previsao(
      cidade: cidade,
      atualizacao: DateTime.tryParse(_texto(raiz, 'atualizacao') ?? ''),
      dias: dias,
    );
  }

  void close() => _client.close();

  Future<XmlDocument> _obterXml(
    String caminho, [
    Map<String, String>? parametros,
  ]) async {
    CptecException? ultimoErro;

    for (final base in _bases) {
      try {
        final uri = Uri.parse(base).replace(
          path: caminho,
          queryParameters: parametros,
        );
        final resposta = await _client.get(uri).timeout(_limiteDeEspera);

        if (resposta.statusCode != 200) {
          ultimoErro = CptecException(
            TipoErroCptec.servicoIndisponivel,
            'O serviço do CPTEC/INPE está indisponível '
            '(HTTP ${resposta.statusCode}).',
          );
          continue;
        }

        return _interpretar(resposta.bodyBytes);
      } on TimeoutException {
        ultimoErro = const CptecException(
          TipoErroCptec.tempoEsgotado,
          'O serviço demorou demais para responder. Tente novamente.',
        );
      } on SocketException {
        ultimoErro = const CptecException(
          TipoErroCptec.semConexao,
          'Sem conexão com a internet. Verifique sua rede.',
        );
      } on HandshakeException {
        ultimoErro = const CptecException(
          TipoErroCptec.servicoIndisponivel,
          'Não foi possível estabelecer uma conexão segura com o serviço.',
        );
      } on http.ClientException {
        ultimoErro = const CptecException(
          TipoErroCptec.semConexao,
          'Falha de conexão com o serviço do CPTEC/INPE.',
        );
      } on CptecException catch (erro) {
        ultimoErro = erro;
      }
    }

    throw ultimoErro ??
        const CptecException(
          TipoErroCptec.servicoIndisponivel,
          'O serviço do CPTEC/INPE está indisponível.',
        );
  }

  XmlDocument _interpretar(List<int> bytes) {
    String texto;
    try {
      texto = utf8.decode(bytes);
    } on FormatException {
      texto = latin1.decode(bytes);
    }

    try {
      return XmlDocument.parse(texto);
    } on XmlException {
      throw const CptecException(
        TipoErroCptec.respostaInvalida,
        'O serviço retornou uma resposta inválida.',
      );
    }
  }

  String? _texto(XmlElement pai, String nome) {
    final valor = pai.getElement(nome)?.innerText.trim();
    return (valor == null || valor.isEmpty) ? null : valor;
  }

  double? _numero(XmlElement pai, String nome) {
    final texto = _texto(pai, nome);
    if (texto == null) return null;
    return double.tryParse(texto.replaceAll(',', '.'));
  }

  String _semAcentos(String texto) {
    const origem = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
    const destino = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';

    final saida = StringBuffer();
    for (final codigo in texto.runes) {
      final caractere = String.fromCharCode(codigo);
      final indice = origem.indexOf(caractere);
      saida.write(indice >= 0 ? destino[indice] : caractere);
    }
    return saida.toString();
  }
}