import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:frontend/core/constants/utils.dart';
import 'package:frontend/features/auth/cubit/auth_cubit.dart';
import 'package:frontend/features/home/cubit/task_cubit.dart';
import 'package:frontend/features/home/pages/add_new_task.dart';
import 'package:frontend/features/home/widgets/date_selector.dart';
import 'package:frontend/features/home/widgets/task_card.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(
        builder: (context) => const HomePage(),
      );
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();

  void deleleTask(BuildContext context) {}

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state as AuthUserLogedIn;
    context.read<TaskCubit>().getAllTasks(token: user.user.token);
    Connectivity().onConnectivityChanged.listen((data) async {
      if (data.contains(ConnectivityResult.wifi)) {
        // ignore: use_build_context_synchronously
        await context.read<TaskCubit>().syncTasks(user.user.token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("My Tasks"),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(context, AddNewTask.route());
              },
              icon: const Icon(
                CupertinoIcons.add,
              ),
            )
          ],
        ),
        body: BlocBuilder<TaskCubit, TaskState>(
          builder: (context, state) {
            if (state is TaskLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is TaskError) {
              return Center(
                child: Text(state.error),
              );
            }

            if (state is GetTaskSuccess) {
              final tasks = state.tasks
                  .where(
                    (elem) =>
                        DateFormat('d').format(elem.dueAt) ==
                            DateFormat('d').format(selectedDate) &&
                        selectedDate.month == elem.dueAt.month &&
                        selectedDate.year == elem.dueAt.year,
                  )
                  .toList();

              return Column(
                children: [
                  DateSelector(
                    selectedDate: selectedDate,
                    onTap: (date) {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                  ),
                  Expanded(
                    child: ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Slidable(
                            endActionPane: ActionPane(
                              motion: const StretchMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    final taskId = task.id;
                                    final user = context.read<AuthCubit>().state
                                        as AuthUserLogedIn;
                                    final token = user.user.token;

                                    context.read<TaskCubit>().deleteTask(
                                          token: token,
                                          taskId: taskId,
                                        );
                                  },
                                  backgroundColor: Colors.red,
                                  label: "Delete",
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Taskcard(
                                    color: task.color,
                                    headerText: task.title,
                                    descriptionText: task.description,
                                  ),
                                ),
                                Container(
                                  height: 10,
                                  width: 10,
                                  decoration: BoxDecoration(
                                    color: strenthenColor(task.color, 0.69),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    DateFormat.jm().format(task.dueAt),
                                    style: const TextStyle(
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                  )
                ],
              );
            }

            return const SizedBox();
          },
        ));
  }
}
