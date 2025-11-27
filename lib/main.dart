import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Imports dos Providers
import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
import 'providers/theme_provider.dart';

// Imports das Telas
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/monitoramento_service.dart'; // <--- Importe sua nova tela aqui
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('userId');
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(isDarkMode)),
      ],
      child: MyApp(isLoggedIn: userId != null),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Monitor de Serviços',
          debugShowCheckedModeBanner: false,
          
          // Temas
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          
          // Rota inicial baseada no login
          home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),

          // 🚀 ROTAS DO SISTEMA
          // Aqui registramos a tela nova para facilitar a navegação
          routes: {
            '/dashboard': (context) => const DashboardScreen(),
            '/login': (context) => const LoginScreen(),
            '/monitoramento': (context) => MonitoramentoScreen(), // <--- Rota nova
          },
        );
      },
    );
  }
}