import 'dart:io';

import 'package:ai_workbench/features/metadata/data/json_favorites_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('favorites survive repository reconstruction per Vault', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-fav-');
    addTearDown(() => root.delete(recursive: true));

    final first = JsonFavoritesRepository(
      vaultRoot: root,
      writer: AtomicFileWriter(),
    );
    await first.saveFavoriteIds({'workflow-1', 'prompt-1'});

    final snapshot = await JsonFavoritesRepository(
      vaultRoot: root,
      writer: AtomicFileWriter(),
    ).loadFavoriteIds();

    expect(snapshot, {'workflow-1', 'prompt-1'});
    expect(
      File(p.join(root.path, '.ai-workbench', 'favorites.json')).existsSync(),
      isTrue,
    );
  });

  test('different Vault roots keep independent favorites', () async {
    final firstRoot = await Directory.systemTemp.createTemp('nightelf-fav-a-');
    final secondRoot = await Directory.systemTemp.createTemp('nightelf-fav-b-');
    addTearDown(() => firstRoot.delete(recursive: true));
    addTearDown(() => secondRoot.delete(recursive: true));

    await JsonFavoritesRepository(
      vaultRoot: firstRoot,
    ).saveFavoriteIds({'only-a'});
    await JsonFavoritesRepository(
      vaultRoot: secondRoot,
    ).saveFavoriteIds({'only-b'});

    expect(
      await JsonFavoritesRepository(vaultRoot: firstRoot).loadFavoriteIds(),
      {'only-a'},
    );
    expect(
      await JsonFavoritesRepository(vaultRoot: secondRoot).loadFavoriteIds(),
      {'only-b'},
    );
  });
}
