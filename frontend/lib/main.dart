import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/disaster_provider.dart';
import 'providers/rescue_provider.dart';
import 'providers/shelter_provider.dart';
import 'providers/medical_provider.dart';
import 'providers/resource_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DisasterProvider()),
        ChangeNotifierProvider(create: (_) => RescueProvider()),
        ChangeNotifierProvider(create: (_) => ShelterProvider()),
        ChangeNotifierProvider(create: (_) => MedicalProvider()),
        ChangeNotifierProvider(create: (_) => ResourceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const DisasterAssistantApp(),
    ),
  );
}

class DisasterAssistantApp extends StatelessWidget {
  const DisasterAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Disaster Response Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
