import 'package:flutter/material.dart';
import '../models/cidade.dart';
import '../models/previsao.dart';
import '../services/banco_local.dart';
import '../services/cptec_service.dart';
import '../utils/condicoes_tempo.dart';
import '../utils/formatar.dart';
import '../widgets/grafico_temperaturas.dart';

class TelaPrevisao extends StatefulWidget {
  final Cidade cidade;

  const TelaPrevisao({super.key, required this.cidade});

  @override
  State<TelaPrevisao> createState() => _TelaPrevisaoState();
}

class _TelaPrevisaoState extends State<TelaPrevisao> {
  final _servico = CptecService();
  final _banco = BancoLocal.instancia;

  Previsao? _previsao;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _servico.close();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    // Exibe imediatamente os últimos dados salvos
    if (_previsao == null) {
      try {
        final salva = await _banco.lerPrevisao(widget.cidade.id);
        if (!mounted) return;
        if (salva != null) {
          setState(() => _previsao = salva);
        }
      } catch (_) {
        // Cache indisponível: segue apenas com a consulta ao serviço.
      }
    }

    try {
      final nova = await _servico.buscarPrevisao(widget.cidade);
      if (!mounted) return;
      setState(() => _previsao = nova);

      if (!nova.estaVazia) {
        try {
          await _banco.salvarPrevisao(nova);
        } catch (_) {
          // Falha ao salvar o cache não afeta a exibição.
        }
      }
    } on CptecException catch (erro) {
      if (!mounted) return;
      setState(() => _erro = erro.mensagem);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível obter a previsão.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget _construirCorpo() {
    final previsao = _previsao;

    if (previsao == null) {
      if (_carregando) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _erro ?? 'Nenhuma previsão disponível.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_carregando) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
        ],
        if (_erro != null) ...[
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Não foi possível atualizar: $_erro\n'
                'Exibindo os últimos dados salvos.',
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          previsao.atualizacao == null
              ? 'Data de atualização não informada'
              : 'Atualizado em ${formatarData(previsao.atualizacao!)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (previsao.estaVazia)
          const Text('Nenhuma previsão disponível para esta cidade no momento.')
        else ...[
          GraficoTemperaturas(dias: previsao.dias),
          const SizedBox(height: 12),
          for (final dia in previsao.dias) _CartaoDia(dia: dia),
        ],
        const SizedBox(height: 16),
        const Text(
          'Fonte dos dados: CPTEC/INPE',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cidade.rotulo),
        actions: [
          IconButton(
            tooltip: 'Atualizar previsão',
            icon: const Icon(Icons.refresh),
            onPressed: _carregando ? null : _carregar,
          ),
        ],
      ),
      body: SafeArea(child: _construirCorpo()),
    );
  }
}

class _CartaoDia extends StatelessWidget {
  final PrevisaoDia dia;

  const _CartaoDia({required this.dia});

  @override
  Widget build(BuildContext context) {
    final condicao = condicaoDaSigla(dia.sigla);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(iconeDaCondicao(condicao), size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${diaDaSemana(dia.data)} - ${formatarData(dia.data)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(condicao.descricao),
                  const SizedBox(height: 4),
                  Text(
                    'Mín: ${formatarTemperatura(dia.minima)}   '
                    'Máx: ${formatarTemperatura(dia.maxima)}',
                  ),
                  Text('Índice UV: ${formatarIuv(dia.iuv)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}