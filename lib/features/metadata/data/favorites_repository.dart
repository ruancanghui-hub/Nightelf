abstract interface class FavoritesRepository {
  Future<Set<String>> loadFavoriteIds();

  Future<void> saveFavoriteIds(Set<String> ids);
}
