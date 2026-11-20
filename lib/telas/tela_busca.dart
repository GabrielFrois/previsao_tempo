import 'package:flutter/material.dart';
import '../models/cidade.dart';
import '../services/banco_local.dart';
import '../services/cptec_service.dart';
import 'tela_previsao.dart';

class TelaBusca extends StatefulWidget {
  const TelaBusca({super.key});

  @override
  State<TelaBusca> createState() => _TelaBuscaState();
}

class _TelaBuscaState extends State<TelaBusca> {
  final _formKey = GlobalKey<FormState>();
  final _controlador = TextEditingController();
  final _servico = CptecService();
  final _banco = BancoLocal.instancia;

  /// null = nenhuma busca realizada ainda.
  List<Cidade>? _resultados;
  List<Cidade> _recentes = [];
  bool _carregando = false;
  String? _erro;
  String _termoBuscado = '';

  @override
  void initState() {
    super.initState();
    _carregarRecentes();
  }

  @override
  void dispose() {
    _controlador.dispose();
    _servico.close();
    super.dispose();
  }

  String? _validarNome(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Informe o nome da cidade.';
    }
    if (texto.length < 2) {
      return 'Digite pelo menos 2 caracteres.';
    }
    return null;
  }

  Future<void> _carregarRecentes() async {
    try {
      final recentes = await _banco.listarCidadesRecentes();
      if (!mounted) return;
      setState(() => _recentes = recentes);
    } catch (_) {
      // Falha no banco local não impede o uso do aplicativo.
    }
  }

  Future<void> _buscar() async {
    if (_carregando) return;
    if (!_formKey.currentState!.validate()) return;

    final termo = _controlador.text.trim();
    FocusScope.of(context).unfocus();

    setState(() {
      _carregando = true;
      _erro = null;
      _resultados = null;
    });

    try {
      final cidades = await _servico.buscarCidades(termo);
      if (!mounted) return;
      setState(() {
        _resultados = cidades;
        _termoBuscado = termo;
      });
    } on CptecException catch (erro) {
      if (!mounted) return;
      setState(() => _erro = erro.mensagem);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível buscar as cidades.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirPrevisao(Cidade cidade) async {
    try {
      await _banco.salvarCidadeRecente(cidade);
    } catch (_) {
      // Falha ao registrar o histórico não impede a consulta.
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TelaPrevisao(cidade: cidade),
      ),
    );

    if (!mounted) return;
    _carregarRecentes();
  }

  Future<void> _removerRecente(Cidade cidade) async {
    try {
      await _banco.removerCidadeRecente(cidade.id);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    _carregarRecentes();
  }

  Widget _construirListaDeCidades(
    List<Cidade> cidades, {
    bool comRemocao = false,
  }) {
    return ListView.builder(
      itemCount: cidades.length,
      itemBuilder: (context, indice) {
        final cidade = cidades[indice];
        return ListTile(
          leading: const Icon(Icons.location_city),
          title: Text(cidade.nome),
          subtitle: Text(cidade.uf.isEmpty ? 'UF não informada' : cidade.uf),
          trailing: comRemocao
              ? IconButton(
                  tooltip: 'Remover do histórico',
                  icon: const Icon(Icons.close),
                  onPressed: () => _removerRecente(cidade),
                )
              : const Icon(Icons.chevron_right),
          onTap: () => _abrirPrevisao(cidade),
        );
      },
    );
  }

  Widget _construirConteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_erro!, textAlign: TextAlign.center),
            TextButton(
              onPressed: _buscar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final resultados = _resultados;
    if (resultados != null) {
      if (resultados.isEmpty) {
        return Center(
          child: Text(
            'Nenhuma cidade encontrada para "$_termoBuscado".',
            textAlign: TextAlign.center,
          ),
        );
      }
      return _construirListaDeCidades(resultados);
    }

    if (_recentes.isEmpty) {
      return const Center(
        child: Text('Digite o nome de uma cidade para consultar a previsão.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cidades recentes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Expanded(child: _construirListaDeCidades(_recentes, comRemocao: true)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Previsão do tempo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _controlador,
                  decoration: const InputDecoration(
                    labelText: 'Cidade',
                    hintText: 'Ex.: Jacareí',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.search,
                  validator: _validarNome,
                  onFieldSubmitted: (_) => _buscar(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _carregando ? null : _buscar,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
              const SizedBox(height: 16),
              Expanded(child: _construirConteudo()),
              const SizedBox(height: 8),
              const Text(
                'Fonte dos dados: CPTEC/INPE',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}