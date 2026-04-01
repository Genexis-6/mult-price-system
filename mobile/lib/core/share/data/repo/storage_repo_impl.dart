import 'package:mobile/core/share/domain/repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageRepoImpl extends StorageRepo {
  final SharedPreferences _preferences;
  
  StorageRepoImpl(this._preferences);

  @override
  void clear() {
    _preferences.clear();
  }

  @override
  Future<bool> delete({required String key})async {
    return await _preferences.remove(key) ;
  }

  @override
  T? get<T>({required String key}) {
    final value = _preferences.get(key);
    
    if (value == null) return null;
    
    // Type casting based on T
    switch (T) {
      case const (String):
        return _preferences.getString(key) as T?;
      case const (int):
        return _preferences.getInt(key) as T?;
      case const (double):
        return _preferences.getDouble(key) as T?;
      case const (bool):
        return _preferences.getBool(key) as T?;
      case const (List<String>):
        return _preferences.getStringList(key) as T?;
      default:
        final stringValue = _preferences.getString(key);
        if (stringValue != null) {
  
          return null;
        }
        return null;
    }
  }
  
  @override
  void save<T>({required String key, T? val}) {
    if (val == null) {
      _preferences.remove(key);
      return;
    }
    
    // Type-based saving
    switch (T) {
      case const (String):
        _preferences.setString(key, val as String);
        break;
      case const (int):
        _preferences.setInt(key, val as int);
        break;
      case const (double):
        _preferences.setDouble(key, val as double);
        break;
      case const (bool):
        _preferences.setBool(key, val as bool);
        break;
      case const (List<String>):
        _preferences.setStringList(key, val as List<String>);
        break;
      default:
        throw UnsupportedError('Type $T is not supported by SharedPreferences');
    }
  }
  

  String? getString({required String key}) {
    return _preferences.getString(key);
  }

  int? getInt({required String key}) {
    return _preferences.getInt(key);
  }
  

  double? getDouble({required String key}) {
    return _preferences.getDouble(key);
  }
  

  bool? getBool({required String key}) {
    return _preferences.getBool(key);
  }
  

  List<String>? getStringList({required String key}) {
    return _preferences.getStringList(key);
  }
  
 
  bool containsKey({required String key}) {
    return _preferences.containsKey(key);
  }
  

  Set<String> getKeys() {
    return _preferences.getKeys();
  }
}