import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/services/pocketbase_service.dart';
import 'admin/core/admin_dependencies.dart';
import 'admin/data/services/admin_auth_service.dart';
import 'admin/presentation/screens/admin_login_screen.dart';
import 'admin/presentation/screens/admin_shell.dart';
import 'admin/theme/admin_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PocketBaseService.instance.initialize();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AdminAuthService.instance.isAdmin;

    return Provider<AdminDependencies>.value(
      value: AdminDependencies(),
      child: MaterialApp(
        title: '우물 관리자',
        debugShowCheckedModeBanner: false,
        theme: AdminTheme.lightTheme,
        home: isLoggedIn ? const AdminShell() : const AdminLoginScreen(),
        routes: {
          '/admin/login': (context) => const AdminLoginScreen(),
          '/admin/dashboard': (context) => const AdminShell(),
        },
      ),
    );
  }
}
