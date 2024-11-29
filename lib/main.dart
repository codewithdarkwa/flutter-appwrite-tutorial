import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Client client = Client().setEndpoint("https://cloud.appwrite.io/v1").setProject("6749cd960018cabf5eb9");
  Account account = Account(client);
  runApp(MyApp(account: account));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter AppWrite Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(account: account),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.account});

  final Account account;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  models.User? loggedInUser;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

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
          ],
        ),
      ),
    );
  }
}
