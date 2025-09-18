import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'admin/pages/admin_dashboard.dart';
import 'admin/pages/admin_login_page.dart';
import 'admin/services/admin_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(AdminApp());
}

class AdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookCycle Administration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AdminAuthWrapper(),
    );
  }
}

class AdminAuthWrapper extends StatelessWidget {
  final AdminAuthService _authService = AdminAuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return AdminDashboard();
          } else {
            return AdminLoginPage();
          }
        }
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}