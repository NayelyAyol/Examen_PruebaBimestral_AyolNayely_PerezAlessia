import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

// Importación de Modelos
import 'models/sector_model.dart';
import 'models/coordinator_model.dart';
import 'models/vaccinator_model.dart';
import 'models/vaccination_model.dart';

// Importación de Servicios
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/seed_service.dart';

// Importación de Tema
import 'theme/vet_theme.dart';

// Importación de Vistas Auth
import 'views/auth/login_view.dart';
import 'views/auth/forgot_password_view.dart';
import 'views/auth/change_password_view.dart';

// Importación de Vistas Dashboard
import 'views/dashboard/campana_dashboard.dart';
import 'views/dashboard/brigada_dashboard.dart';

// Importación de Vistas Sectores
import 'views/sectors/sectors_list_view.dart';
import 'views/sectors/sector_form_view.dart';

// Importación de Vistas Coordinadores
import 'views/coordinators/coordinators_list_view.dart';
import 'views/coordinators/coordinator_form_view.dart';

// Importación de Vistas Vacunadores
import 'views/vaccinators/vaccinators_page.dart';
import 'views/vaccinators/vaccinator_form_page.dart';

// Importación de Vistas Vacunaciones
import 'views/vaccinations/vaccinations_page.dart';
import 'views/vaccinations/vaccination_form_page.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseInitialized = false;

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
    print("====== Firebase inicializado correctamente ======");
  } catch (e) {
    print(
      "====== AVISO: Firebase no está configurado. Ejecutando en Modo Demo Local. Error: $e ======",
    );
    isFirebaseInitialized = false;
  }

  // Inicializar servicios principales
  final authService = AuthService(isFirebaseInitialized);
  final firestoreService = FirestoreService(isFirebaseInitialized);

  // Ejecutar el Seed automático al iniciar la app
  await SeedService.checkAndSeed(firestoreService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<FirestoreService>.value(value: firestoreService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VetCampaign App',
      debugShowCheckedModeBanner: false,
      theme: VetTheme.lightTheme,
      initialRoute: '/login',

      // Rutas fijas sencillas
      routes: {
        '/login': (context) => const LoginView(),
        '/forgot_password': (context) => const ForgotPasswordView(),
        '/change_password': (context) => const ChangePasswordView(),
        '/campana_dashboard': (context) => const CampanaDashboard(),
        '/brigada_dashboard': (context) => const BrigadaDashboard(),
        '/sectors': (context) => const SectorsListView(),
        '/coordinators': (context) => const CoordinatorsListView(),
        '/vaccinators': (context) => const VaccinatorsPage(),
        '/vaccinations': (context) => const VaccinationsPage(),
      },

      // OnGenerateRoute para rutas que requieren pasar parámetros dinámicos
      onGenerateRoute: (settings) {
        if (settings.name == '/sector_form') {
          final SectorModel? sector = settings.arguments as SectorModel?;
          return MaterialPageRoute(
            builder: (context) => SectorFormView(sectorToEdit: sector),
          );
        }

        if (settings.name == '/coordinator_form') {
          final CoordinatorModel? coordinator =
              settings.arguments as CoordinatorModel?;
          return MaterialPageRoute(
            builder: (context) =>
                CoordinatorFormView(coordinatorToEdit: coordinator),
          );
        }

        if (settings.name == '/vaccinator_form') {
          final VaccinatorModel? vaccinator =
              settings.arguments as VaccinatorModel?;
          return MaterialPageRoute(
            builder: (context) =>
                VaccinatorFormPage(vaccinatorToEdit: vaccinator),
          );
        }

        if (settings.name == '/vaccination_form') {
          final VaccinationModel? vaccination =
              settings.arguments as VaccinationModel?;
          return MaterialPageRoute(
            builder: (context) =>
                VaccinationFormPage(vaccinationToEdit: vaccination),
          );
        }

        return null;
      },
    );
  }
}