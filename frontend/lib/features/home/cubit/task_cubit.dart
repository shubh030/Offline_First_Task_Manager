import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/constants/utils.dart';
import 'package:frontend/features/home/repository/task_local_repo.dart';
import 'package:frontend/features/home/repository/task_remote_repo.dart';
import 'package:frontend/models/task_model.dart';

part 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  TaskCubit() : super(AddNewTaskInitial());

  final taskRemoteRepo = TaskRemoteRepo();
  final taskLocalRepo = TaskLocalRepo();

  Future<void> createNewTask({
    required String title,
    required String description,
    required Color color,
    required String token,
    required String uid,
    required DateTime dueAt,
  }) async {
    try {
      emit(TaskLoading());
      final taskModel = await taskRemoteRepo.createTask(
        uid: uid,
        title: title,
        description: description,
        hexColor: rgbToHex(color),
        token: token,
        dueAt: dueAt,
      );
      await taskLocalRepo.insertTask(taskModel);

      emit(TaskSuccess(taskModel));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> getAllTasks({required String token}) async {
    try {
      emit(TaskLoading());
      final tasks = await taskRemoteRepo.getTasks(token: token);
      emit(GetTaskSuccess(tasks));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> syncTasks(String token) async {
    // get all unsynced tasks from our sqlite databse
    final unsyncedTasks = await taskLocalRepo.getUnsyncedTasks();
    if (unsyncedTasks.isEmpty) {
      return;
    }
    //task to postgress to sync
    final isSynced =
        await taskRemoteRepo.syncTasks(token: token, tasks: unsyncedTasks);
    //chnage task status syced

    if (isSynced) {
      print('synce done');
      for (final task in unsyncedTasks) {
        taskLocalRepo.updateRowValue(task.id, 1);
      }
    }
  }

// TaskCubit.dart

  Future<void> deleteTask({
    required String token,
    required String taskId,
  }) async {
    try {
      emit(TaskLoading());
      final success =
          await taskRemoteRepo.deleteTask(token: token, taskId: taskId);

      if (success) {
        await taskLocalRepo.deleteTask(taskId);

        final tasks = await taskRemoteRepo.getTasks(token: token);
        emit(GetTaskSuccess(tasks));
      } else {
        emit(const TaskError("Failed to delete task"));
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }
}
