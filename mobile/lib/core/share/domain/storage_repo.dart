abstract class StorageRepo {
  void save<T>({required String key, T? val});
  T? get<T>({required String key});

  Future<bool> delete({required String key});

  void clear();
}
