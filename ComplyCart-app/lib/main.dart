import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screen.dart';
import 'theme/app_theme.dart';
import 'services/camera_service.dart';
import 'providers/seller_provider.dart';
import 'providers/compliance_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CameraService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SellerProvider()),
        ChangeNotifierProvider(create: (_) => ComplianceProvider()),
      ],
      child: const ComplyCartApp(),
    ),
  );
}

class ComplyCartApp extends StatelessWidget {
  const ComplyCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ComplyCart AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthScreen(),
    );
  }
}
