import 'package:mobile/core/share/domain/repo.dart';

class StorageService {
  final StorageRepo _storageRepo;
  
  static const String _lastTaskIdKey = 'last_task_id';
  static const String _lastQueryKey = 'last_query';
  static const String _taskStatusKey = 'task_status';
  
  StorageService(this._storageRepo);
  
  Future<void> saveLastTask(String taskId, String query) async {
    _storageRepo.save(key: _lastTaskIdKey, val: taskId);
    _storageRepo.save(key: _lastQueryKey, val: query);
  }
  
  Future<Map<String, String?>?> getLastTask() async {
    final taskId = _storageRepo.get<String>(key: _lastTaskIdKey);
    final query = _storageRepo.get<String>(key: _lastQueryKey);
    
    if (taskId != null && query != null) {
      return {'taskId': taskId, 'query': query};
    }
    return null;
  }
  
  Future<void> clearLastTask() async {
    await _storageRepo.delete(key: _lastTaskIdKey);
    await _storageRepo.delete(key: _lastQueryKey);
    await _storageRepo.delete(key: _taskStatusKey);
  }
  
  Future<void> saveTaskStatus(String taskId, String status) async {
    _storageRepo.save(key: '${_taskStatusKey}_$taskId', val: status);
  }
  
  Future<String?> getTaskStatus(String taskId) async {
    return _storageRepo.get<String>(key: '${_taskStatusKey}_$taskId');
  }
}