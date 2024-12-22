import 'dart:convert';

import 'package:frontend/core/constants/constants.dart';
import 'package:frontend/core/constants/utils.dart';
import 'package:frontend/features/home/repository/task_local_repo.dart';
import 'package:frontend/models/task_model.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class TaskRemoteRepo {
  final taskLocalRepository = TaskLocalRepo();

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required String hexColor,
    required String token,
    required String uid,
    required DateTime dueAt,
  }) async {
    try {
      final res = await http.post(Uri.parse("${Constants.backEndUri}/tasks/"),
          headers: {
            'Content-Type': 'application/json',
            'x-auth-token': token,
          },
          body: jsonEncode(
            {
              'title': title,
              'description': description,
              'hexColor': hexColor,
              'dueAt': dueAt.toIso8601String(),
            },
          ));

      if (res.statusCode != 201) {
        throw jsonDecode(res.body)['msg'];
      }

      return TaskModel.fromJson(res.body);
    } catch (e) {
      try {
        final taskModel = TaskModel(
          id: const Uuid().v6(),
          uid: uid,
          title: title,
          description: description,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          dueAt: dueAt,
          color: hexToRgb(hexColor),
          isSynced: 0,
        );
        await taskLocalRepository.insertTask(taskModel);
        return taskModel;
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<List<TaskModel>> getTasks({required String token}) async {
    try {
      final res = await http.get(
        Uri.parse("${Constants.backEndUri}/tasks/"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['msg'];
      }

      final listOfTasks = jsonDecode(res.body);
      List<TaskModel> tasksList = [];

      for (var elem in listOfTasks) {
        tasksList.add(TaskModel.fromMap(elem));
      }

      await taskLocalRepository.insertTasks(tasksList);

      return tasksList;
    } catch (e) {
      final tasks = await taskLocalRepository.getTasks();
      if (tasks.isNotEmpty) {
        return tasks;
      }
      rethrow;
    }
  }

  Future<bool> syncTasks({
    required String token,
    required List<TaskModel> tasks,
  }) async {
    try {
      final taskListInMap = [];
      for (final task in tasks) {
        taskListInMap.add(task.toMap());
      }
      final res =
          await http.post(Uri.parse("${Constants.backEndUri}/tasks/sync"),
              headers: {
                'Content-Type': 'application/json',
                'x-auth-token': token,
              },
              body: jsonEncode(taskListInMap));

      if (res.statusCode != 201) {
        throw jsonDecode(res.body)['msg'];
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTask({
    required String token,
    required String taskId,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse("${Constants.backEndUri}/tasks/"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'taskId': taskId,
        }),
      );

      if (res.statusCode == 200) {
        await taskLocalRepository.deleteTask(taskId);
        return true;
      } else {
        throw jsonDecode(res.body)['msg'];
      }
    } catch (e) {
      // Handle errors here
      print("Error deleting task: $e");
      return false;
    }
  }
}
