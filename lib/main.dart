import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class Task {
  String title;
  String description;
  bool completed;

  Task({required this.title, required this.description, this.completed = false});

  Task.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        description = json['description'],
        completed = json['completed'];

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'completed': completed,
      };
}

class TodoList {
  List<Task> tasks = [];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color.fromARGB(255, 255, 0, 0),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'ToDo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TodoList todoList;
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    todoList = TodoList();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    loadTasks();
  }

  Future<void> loadTasks() async {
    prefs = await SharedPreferences.getInstance();
    String data = prefs.getString('tasks') ?? '[]';
    List<dynamic> tasksJson = jsonDecode(data);
    setState(() {
      todoList.tasks = tasksJson.map((taskJson) => Task.fromJson(taskJson)).toList();
    });
  }

  Future<void> saveTasks() async {
    String data = jsonEncode(todoList.tasks);
    await prefs.setString('tasks', data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ToDo'),
      ),
      body: todoList.tasks.isEmpty
          ? const Center(child: Text('Нет запланированных задач'))
          : ListView.builder(
              itemCount: todoList.tasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(todoList.tasks[index].title),
                  subtitle: Text(todoList.tasks[index].description),
                  trailing: Checkbox(
                    value: todoList.tasks[index].completed,
                    onChanged: (value) {
                      setState(() {
                        todoList.tasks[index].completed = value!;
                      });
                      saveTasks();
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTaskScreen(
                          task: todoList.tasks[index],
                          onTaskUpdated: (updatedTask) {
                            setState(() {
                              todoList.tasks[index] = updatedTask;
                            });
                            saveTasks();
                          },
                          onTaskDeleted: () {
                            setState(() {
                              todoList.tasks.removeAt(index);
                            });
                            saveTasks();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(
                onTaskAdded: (newTask) {
                  setState(() {
                    todoList.tasks.add(newTask);
                  });
                  saveTasks();
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
class AddTaskScreen extends StatefulWidget {
  final Function(Task) onTaskAdded;

  const AddTaskScreen({super.key, required this.onTaskAdded});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить задачу'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Наименование'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  Task newTask = Task(
                    title: titleController.text,
                    description: descriptionController.text,
                  );
                  widget.onTaskAdded(newTask);
                  Navigator.pop(context);
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatefulWidget {
  final Task task;
  final Function(Task) onTaskUpdated;
  final VoidCallback onTaskDeleted;

  const EditTaskScreen({super.key, 
    required this.task,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    descriptionController = TextEditingController(text: widget.task.description);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать задачу'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              widget.onTaskDeleted();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Наименование'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  Task updatedTask = Task(
                    title: titleController.text,
                    description: descriptionController.text,
                    completed: widget.task.completed,
                  );
                  widget.onTaskUpdated(updatedTask);
                  Navigator.pop(context);
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}