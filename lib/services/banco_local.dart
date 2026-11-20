import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/cidade.dart';
import '../models/previsao.dart';

/// Persistência local em SQLite
class BancoLocal {
  BancoLocal._();

  static final BancoLocal instancia = BancoLocal._();

  Future<Database>? _abertura;

  Future<Database> get _banco => _abertura ??= _abrir();

  Future<Database> _abrir() async {
    final pasta = await getDatabasesPath();

    return openDatabase(
      p.join(pasta, 'previsao_tempo.db'),
      version: 1,
      onCreate: (db, versao) async {
        await db.execute('''
          CREATE TABLE cidades_recentes (
            id INTEGER PRIMARY KEY,
            nome TEXT NOT NULL,
            uf TEXT NOT NULL,
            ultima_consulta TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE previsoes_cache (
            cidade_id INTEGER PRIMARY KEY,
            conteudo TEXT NOT NULL,
            salvo_em TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Registra/atualiza a cidade como a mais recentemente consultada.
  Future<void> salvarCidadeRecente(Cidade cidade) async {
    final db = await _banco;
    await db.insert(
      'cidades_recentes',
      {
        ...cidade.toMap(),
        'ultima_consulta': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Cidade>> listarCidadesRecentes({int limite = 10}) async {
    final db = await _banco;
    final linhas = await db.query(
      'cidades_recentes',
      orderBy: 'ultima_consulta DESC',
      limit: limite,
    );
    return linhas.map(Cidade.fromMap).toList();
  }

  Future<void> removerCidadeRecente(int id) async {
    final db = await _banco;
    await db.delete('cidades_recentes', where: 'id = ?', whereArgs: [id]);
  }

  /// Guarda a previsão serializada em JSON, substituindo a anterior.
  Future<void> salvarPrevisao(Previsao previsao) async {
    final db = await _banco;
    await db.insert(
      'previsoes_cache',
      {
        'cidade_id': previsao.cidade.id,
        'conteudo': jsonEncode(previsao.toJson()),
        'salvo_em': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retorna a última previsão salva ou null se não houver
  Future<Previsao?> lerPrevisao(int cidadeId) async {
    final db = await _banco;
    final linhas = await db.query(
      'previsoes_cache',
      where: 'cidade_id = ?',
      whereArgs: [cidadeId],
      limit: 1,
    );

    if (linhas.isEmpty) return null;

    try {
      final decodificado = jsonDecode(linhas.first['conteudo'] as String);
      return Previsao.fromJson(
        (decodificado as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return null;
    }
  }
}