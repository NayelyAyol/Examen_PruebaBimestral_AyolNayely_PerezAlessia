import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../firebase_options.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isFirebaseInitialized = false;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

  // Datos locales para el Modo Demo (cuando Firebase no está configurado)
  final Map<String, Map<String, dynamic>> _demoUsers = {
    'campana@vet.com': {
      'uid': 'demo_admin_uid',
      'name': 'Dr. Carlos Mendoza (Campaña)',
      'role': 'coordinador_campana',
      'isFirstLogin': true,
      'password': 'Ecuador2026'
    },
    'brigada@vet.com': {
      'uid': 'demo_brigada_uid',
      'name': 'Dra. Ana López (Brigada)',
      'role': 'coordinador_brigada',
      'isFirstLogin': false,
      'password': 'Ecuador2026'
    }
  };

  AuthService(bool isFirebaseInitialized) {
    _isFirebaseInitialized = isFirebaseInitialized;
    if (_isFirebaseInitialized) {
      _auth.authStateChanges().listen((User? user) async {
        if (user != null) {
          await refreshCurrentUser(user.uid);
        } else {
          _currentUser = null;
          notifyListeners();
        }
      });
    }
  }

  // Carga los datos del usuario desde Firestore
  Future<void> refreshCurrentUser(String uid) async {
    if (_isFirebaseInitialized) {
      try {
        DocumentSnapshot doc = await _db.collection('usuarios').doc(uid).get();
        if (doc.exists) {
          _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } else {
          _currentUser = null;
        }
        notifyListeners();
      } catch (e) {
        debugPrint("Error al cargar usuario de Firestore: $e");
      }
    }
  }

  // Iniciar Sesión
  Future<void> login(String email, String password) async {
    if (_isFirebaseInitialized) {
      // Firebase Real
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await refreshCurrentUser(cred.user!.uid);
    } else {
      // Modo Demo
      String trimmedEmail = email.trim();
      if (_demoUsers.containsKey(trimmedEmail) && _demoUsers[trimmedEmail]!['password'] == password) {
        var u = _demoUsers[trimmedEmail]!;
        _currentUser = UserModel(
          uid: u['uid'],
          email: trimmedEmail,
          name: u['name'],
          rol: u['role'],
          isFirstLogin: u['isFirstLogin'],
        );
        notifyListeners();
      } else {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Correo o contraseña incorrectos (Modo Demo)',
        );
      }
    }
  }

  // Cerrar Sesión
  Future<void> logout() async {
    if (_isFirebaseInitialized) {
      await _auth.signOut();
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  // Recuperar Contraseña
  Future<void> resetPassword(String email) async {
    if (_isFirebaseInitialized) {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } else {
      // En modo demo, simulamos la llamada
      await Future.delayed(const Duration(seconds: 1));
      if (!_demoUsers.containsKey(email.trim())) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'El usuario no está registrado en el Modo Demo.',
        );
      }
    }
  }

  // Cambiar Contraseña (Obligatorio o Voluntario)
  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_isFirebaseInitialized) {
      User? user = _auth.currentUser;
      if (user != null) {
        // Re-autenticar por seguridad si es necesario, o cambiar directamente
        // Firebase Auth permite actualizar contraseña directamente si la sesión es reciente
        await user.updatePassword(newPassword);
        // Actualizar isFirstLogin a false en Firestore
        await _db.collection('usuarios').doc(user.uid).update({'isFirstLogin': false});
        await refreshCurrentUser(user.uid);
      }
    } else {
      // Modo Demo
      if (_currentUser != null) {
        String email = _currentUser!.email;
        if (_demoUsers.containsKey(email)) {
          _demoUsers[email]!['password'] = newPassword;
          _demoUsers[email]!['isFirstLogin'] = false;
          _currentUser = UserModel(
            uid: _currentUser!.uid,
            email: email,
            name: _currentUser!.name,
            rol: _currentUser!.role,
            isFirstLogin: false,
          );
          notifyListeners();
        }
      }
    }
  }

  // Crear usuario para un Coordinador de Brigada (Exclusivo Administrador)
  // Como Firebase Auth inicia sesión automáticamente al crear usuario, usamos un truco:
  // Guardamos las credenciales del admin actual en memoria, creamos el coordinador, y re-iniciamos sesión como admin.
Future<String> createBrigadeCoordinatorUser({
  required String email,
  required String cedula,
  required String nombres,
  required String apellidos,
  required String telefono,
}) async {
  if (_isFirebaseInitialized) {
    // Segunda instancia temporal para no cerrar sesión del admin
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'tempApp_${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      UserCredential newCred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: 'Ecuador2026',
          );

      String uid = newCred.user!.uid;

      await _db.collection('usuarios').doc(uid).set({
        'cedula': cedula,
        'nombres': nombres,
        'apellidos': apellidos,
        'telefono': telefono,
        'correo': email.trim(),
        'rol': 'coordinador_brigada',
        'isFirstLogin': true,
      });

      return uid;
    } finally {
      await tempApp.delete();
    }
  } else {
    // Modo Demo
    String uid = 'demo_coor_${DateTime.now().millisecondsSinceEpoch}';
    _demoUsers[email.trim()] = {
      'uid': uid,
      'name': '$nombres $apellidos',
      'role': 'coordinador_brigada',
      'isFirstLogin': true,
      'password': 'Ecuador2026'
    };
    return uid;
  }
}
}
