part of 'task_cubit.dart';

@immutable
sealed class TaskState {
  const TaskState();
}

final class AddNewTaskInitial extends TaskState {}

final class TaskLoading extends TaskState {}

final class TaskSuccess extends TaskState {
  final TaskModel taskModel;

  const TaskSuccess(this.taskModel);
}

final class TaskError extends TaskState {
  final String error;

  const TaskError(this.error);
}

final class GetTaskSuccess extends TaskState {
  final List<TaskModel> tasks;

  const GetTaskSuccess(this.tasks);
}

final class TaskDeletedSuccess extends TaskState {
  final String taskId;

  const TaskDeletedSuccess(this.taskId);
}
