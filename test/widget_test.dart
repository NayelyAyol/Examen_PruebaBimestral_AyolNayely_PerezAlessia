import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_prueba/main.dart';
import 'package:flutter_prueba/services/auth_service.dart';
import 'package:flutter_prueba/services/firestore_service.dart';

void main() {
  testWidgets('Smoke test - La pantalla de login renderiza correctamente', (WidgetTester tester) async {
    // Inicializar servicios en modo demo para la prueba
    final authService = AuthService();
    final firestoreService = FirestoreService(false);

    // Construir la aplicación
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider<FirestoreService>.value(value: firestoreService),
        ],
        child: const MyApp(),
      ),
    );

    // Verificar que los títulos principales de la aplicación se muestren en la UI
    expect(find.text('VetCampaign'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Correo Electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
}
