class TaskStatus {
  final String taskId;
  final String status;
  final int progress;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? result;

  TaskStatus({
    required this.taskId,
    required this.status,
    required this.progress,
    required this.message,
    required this.timestamp,
    this.result,
  });

  factory TaskStatus.fromJson(Map<String, dynamic> json) {
    return TaskStatus(
      taskId: json['task_id'],
      status: json['status'],
      progress: json['progress'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      result: json['result'],
    );
  }
}