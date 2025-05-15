import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'services/transaction_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize the transaction service
  await TransactionService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Manager',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.deepPurple,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurpleAccent,
        ),
        // We'll use the standard page transitions instead of custom ones here
        // Remove the custom page transitions theme that was causing errors
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data != null) {
            // User is logged in
            return const MainNavigation();
          } else {
            // User is not logged in
            return const LoginScreen();
          }
        },
      ),
    );
  }
}