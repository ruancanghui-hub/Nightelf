import 'package:ai_workbench/features/search/data/search_index.dart';
import 'package:ai_workbench/features/search/domain/search_hit.dart';
import 'package:ai_workbench/features/search/domain/search_query.dart';
import 'package:ai_workbench/features/vault/domain/resource_record.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:sqlite3/sqlite3.dart';

class SqliteSearchIndex implements SearchIndex {
  SqliteSearchIndex._(this._db) {
    _createSchema();
  }

  factory SqliteSearchIndex.inMemory() =>
      SqliteSearchIndex._(sqlite3.openInMemory());

  factory SqliteSearchIndex.open(String path) =>
      SqliteSearchIndex._(sqlite3.open(path));

  final Database _db;

  void _createSchema() {
    _db.execute('''
CREATE TABLE IF NOT EXISTS resources (
  id TEXT PRIMARY KEY NOT NULL,
  type TEXT NOT NULL,
  relative_path TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  tags TEXT NOT NULL,
  modified_at TEXT NOT NULL,
  searchable_text TEXT NOT NULL
);
''');
    _db.execute('''
CREATE VIRTUAL TABLE IF NOT EXISTS resource_fts USING fts5(
  id UNINDEXED,
  title,
  description,
  tags,
  content,
  tokenize='unicode61'
);
''');
  }

  @override
  Future<void> rebuild(Iterable<ResourceRecord> records) async {
    _db.execute('BEGIN IMMEDIATE');
    try {
      _db.execute('DELETE FROM resource_fts');
      _db.execute('DELETE FROM resources');
      for (final record in records) {
        _insertRecord(record);
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<void> upsert(ResourceRecord record) async {
    _db.execute('BEGIN IMMEDIATE');
    try {
      _deleteById(record.id);
      _insertRecord(record);
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<void> remove(String id) async {
    _db.execute('BEGIN IMMEDIATE');
    try {
      _deleteById(id);
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<List<SearchHit>> query(SearchQuery query) async {
    final trimmed = query.text.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final ftsQuery = _buildFtsQuery(trimmed);
    final args = <Object?>[ftsQuery];
    final filters = <String>[];

    if (query.types.isNotEmpty) {
      final placeholders = List.filled(query.types.length, '?').join(', ');
      filters.add('r.type IN ($placeholders)');
      args.addAll(query.types.map((type) => type.name));
    }

    if (query.tags.isNotEmpty) {
      final tagClauses = <String>[];
      for (final tag in query.tags) {
        tagClauses.add("(',' || r.tags || ',') LIKE ?");
        args.add('%,$tag,%');
      }
      filters.add('(${tagClauses.join(' AND ')})');
    }

    args.add(query.limit);

    final where = filters.isEmpty ? '' : 'AND ${filters.join(' AND ')}';
    final sql =
        '''
SELECT
  r.id,
  r.type,
  r.relative_path,
  r.title,
  r.description,
  r.tags,
  r.modified_at,
  r.searchable_text,
  bm25(resource_fts) AS rank
FROM resource_fts
JOIN resources r ON r.id = resource_fts.id
WHERE resource_fts MATCH ?
$where
ORDER BY rank
LIMIT ?
''';

    final rows = _db.select(sql, args);
    return rows
        .map((row) => _rowToHit(row, needle: trimmed))
        .toList(growable: false);
  }

  @override
  Future<void> close() async {
    _db.dispose();
  }

  void _insertRecord(ResourceRecord record) {
    final tagsJoined = record.tags.join(',');
    _db.execute(
      '''
INSERT INTO resources (
  id, type, relative_path, title, description, tags, modified_at, searchable_text
) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        record.id,
        record.type.name,
        record.relativePath,
        record.title,
        record.description,
        tagsJoined,
        record.modifiedAt.toUtc().toIso8601String(),
        record.searchableText,
      ],
    );
    _db.execute(
      '''
INSERT INTO resource_fts (id, title, description, tags, content)
VALUES (?, ?, ?, ?, ?)
''',
      [
        record.id,
        _expandForFts(record.title),
        _expandForFts(record.description),
        _expandForFts(tagsJoined.replaceAll(',', ' ')),
        _expandForFts(record.searchableText),
      ],
    );
  }

  void _deleteById(String id) {
    _db.execute('DELETE FROM resource_fts WHERE id = ?', [id]);
    _db.execute('DELETE FROM resources WHERE id = ?', [id]);
  }

  SearchHit _rowToHit(Row row, {required String needle}) {
    final tagsRaw = row['tags'] as String? ?? '';
    final tags = tagsRaw.isEmpty
        ? const <String>[]
        : tagsRaw.split(',').where((tag) => tag.isNotEmpty).toList();
    final record = ResourceRecord(
      id: row['id'] as String,
      type: ResourceType.values.byName(row['type'] as String),
      relativePath: row['relative_path'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      tags: tags,
      modifiedAt: DateTime.parse(row['modified_at'] as String),
      searchableText: row['searchable_text'] as String,
    );

    return SearchHit(
      record: record,
      snippet: _snippetFor(record, needle),
      rank: (row['rank'] as num).toDouble(),
    );
  }

  String _snippetFor(ResourceRecord record, String needle) {
    final candidates = <String>[
      record.title,
      record.tags.join(' '),
      record.description,
      record.searchableText,
    ];
    for (final candidate in candidates) {
      if (candidate.contains(needle)) {
        return candidate;
      }
    }
    for (final term in needle.split(RegExp(r'\s+'))) {
      if (term.isEmpty) {
        continue;
      }
      for (final candidate in candidates) {
        if (candidate.contains(term)) {
          return candidate;
        }
      }
    }
    return record.title;
  }

  /// Escapes user text into quoted FTS terms so operators like OR / * cannot
  /// alter the MATCH expression.
  String _buildFtsQuery(String text) {
    final terms = text
        .split(RegExp(r'\s+'))
        .map((term) => term.trim())
        .where((term) => term.isNotEmpty)
        .map(_quoteTerm)
        .toList(growable: false);
    return terms.join(' ');
  }

  String _quoteTerm(String term) {
    final expanded = _expandForFts(term);
    final tokens = expanded
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .map((token) => token.replaceAll('"', '""'));
    return '"${tokens.join(' ')}"';
  }

  /// Inserts spaces between adjacent CJK characters so unicode61 can match
  /// Chinese substrings as consecutive single-character tokens.
  String _expandForFts(String input) {
    if (input.isEmpty) {
      return input;
    }
    final buffer = StringBuffer();
    int? previous;
    for (final code in input.runes) {
      if (previous != null && _needsFtsBoundary(previous, code)) {
        buffer.write(' ');
      }
      buffer.writeCharCode(code);
      previous = code;
    }
    return buffer.toString();
  }

  bool _needsFtsBoundary(int left, int right) {
    final leftCjk = _isCjk(left);
    final rightCjk = _isCjk(right);
    if (leftCjk && rightCjk) {
      return true;
    }
    if (leftCjk && _isAsciiWordChar(right)) {
      return true;
    }
    if (_isAsciiWordChar(left) && rightCjk) {
      return true;
    }
    return false;
  }

  bool _isCjk(int code) =>
      (code >= 0x3400 && code <= 0x4DBF) ||
      (code >= 0x4E00 && code <= 0x9FFF) ||
      (code >= 0xF900 && code <= 0xFAFF) ||
      (code >= 0x20000 && code <= 0x2A6DF);

  bool _isAsciiWordChar(int code) =>
      (code >= 48 && code <= 57) ||
      (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      code == 95;
}
