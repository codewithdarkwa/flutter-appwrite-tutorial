import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appwrite/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Client client = Client().setEndpoint("https://cloud.appwrite.io/v1").setProject(AppConfig.projectId);
  Account account = Account(client);
  Databases databases = Databases(client);
  runApp(MyApp(
    account: account,
    databases: databases,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.account, required this.databases});

  final Account account;
  final Databases databases;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter AppWrite Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(account: account, databases: databases),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.account, required this.databases});

  final Account account;
  final Databases databases;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  models.User? loggedInUser;
  List<Document> tasks = [];

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    tasks = await getTasks();
    setState(() {});
  }

  Future<void> login(String email, String password) async {
    await widget.account.createEmailPasswordSession(email: email, password: password);
    final user = await widget.account.get();
    setState(() {
      loggedInUser = user;
    });
  }

  Future<void> register(String email, String password, String name) async {
    await widget.account.create(userId: ID.unique(), email: email, password: password, name: name);
    await login(email, password);
  }

  Future<void> logout() async {
    await widget.account.deleteSession(sessionId: 'current');
    setState(() {
      loggedInUser = null;
    });
  }

  Future<bool> createTask(String title, String description) async {
    try {
      final newTask = await widget.databases.createDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.databaseCollectionId,
        documentId: ID.unique(),
        data: {
          'title': title,
          'description': description,
          'completed': false,
        },
      );

      setState(() {
        tasks.add(newTask);
      });
      return true;
    } on AppwriteException catch (e) {
      print(e.message);
      return false;
    }
  }

  Future<List<Document>> getTasks() async {
    try {
      final response = await widget.databases.listDocuments(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.databaseCollectionId,
      );
      return response.documents;
    } on AppwriteException catch (e) {
      print(e.message);
      return [];
    }
  }

  Future<bool> updateTask(String taskID, bool completed) async {
    try {
      final updatedTask = await widget.databases.updateDocument(
          databaseId: AppConfig.databaseId,
          collectionId: AppConfig.databaseCollectionId,
          documentId: taskID,
          data: {
            'completed': completed,
          });

      final index = tasks.indexWhere((task) => task.$id == taskID);

      if (index != -1) {
        setState(() {
          tasks[index] = updatedTask;
        });
      }
      return true;
    } on AppwriteException catch (e) {
      print(e.message);
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      await widget.databases.deleteDocument(
        databaseId: AppConfig.databaseId,
        collectionId: AppConfig.databaseCollectionId,
        documentId: taskId,
      );
      return true;
    } on AppwriteException catch (e) {
      print(e.message);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AppWrite Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(loggedInUser != null ? 'Logged in as ${loggedInUser!.name}' : 'Not logged in'),
            const SizedBox(height: 16.0),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    login(emailController.text, passwordController.text);
                  },
                  child: const Text('Login'),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: () {
                    register(emailController.text, passwordController.text, nameController.text);
                  },
                  child: const Text('Register'),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: () {
                    logout();
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            const Center(
              child: Text(
                "Database Operations",
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text("No tasks yet"),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Dismissible(
                          key: Key(task.$id),
                          onDismissed: (_) => deleteTask(task.$id),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: CheckboxListTile(
                            title: Text(task.data['title']),
                            subtitle: Text(task.data['description']),
                            value: task.data['completed'],
                            onChanged: (value) {
                              if (value != null) {
                                updateTask(task.$id, value);
                              }
                            },
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Add Task'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                          createTask(titleController.text, descriptionController.text);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                );
              });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
