import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:disaster_assistant/main.dart';
import 'package:disaster_assistant/providers/auth_provider.dart';
import 'package:disaster_assistant/providers/disaster_provider.dart';
import 'package:disaster_assistant/providers/rescue_provider.dart';
import 'package:disaster_assistant/providers/shelter_provider.dart';
import 'package:disaster_assistant/providers/medical_provider.dart';
import 'package:disaster_assistant/providers/resource_provider.dart';
import 'package:disaster_assistant/providers/notification_provider.dart';

void main() {
  testWidgets('DisasterAssistantApp smoke test renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
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

    // Verify that the login screen title is rendered
    expect(find.text('AI-Based Disaster Response Assistant'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
