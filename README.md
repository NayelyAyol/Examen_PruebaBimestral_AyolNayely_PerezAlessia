<h1 align="center">
🐶🐱 VetCampaign App
</h1>

<h3 align="center">
Sistema móvil para la gestión de campañas municipales de vacunación canina y felina
</h3>

---

# 📖 Descripción

**VetCampaign App** es una aplicación móvil desarrollada en **Flutter** que permite administrar campañas municipales de vacunación para **perros** y **gatos**.

El sistema implementa un esquema de acceso basado en **roles jerárquicos**, permitiendo administrar sectores, brigadas, vacunadores y registros de vacunación con soporte **offline**, almacenamiento local y sincronización mediante **Firebase**.

---

# 👩‍💻 Autoras

| Integrantes |
|------------|
| 👩 Nayely Ayol |
| 👩 Alessia Pérez |

---

# 🚀 Tecnologías utilizadas

| Tecnología | Uso |
|------------|-----|
| Flutter & Dart | Desarrollo de la aplicación móvil |
| Firebase Authentication | Autenticación y control de accesos |
| Cloud Firestore | Base de datos NoSQL con persistencia offline |
| Firebase Storage | Almacenamiento de fotografías |
| Geolocator | Obtención automática de coordenadas GPS |
| Image Picker | Captura de fotografías |
| Provider | Gestión del estado |
| Shared Preferences | Persistencia local de configuraciones |

---

# 👥 Roles del sistema

| Rol | Funciones |
|------|-----------|
| 👨‍💼 Coordinador de Campaña | Gestiona sectores, barrios, coordinadores de brigada y visualiza estadísticas globales. |
| 👷 Coordinador de Brigada | Administra vacunadores de su zona, revisa registros y consulta indicadores de su brigada. |
| 💉 Vacunador | Registra vacunaciones, captura fotografía y ubicación GPS, y edita únicamente sus propios registros. |

---

# ✨ Funcionalidades principales

✅ Inicio de sesión con autenticación por roles.

✅ Cambio obligatorio de contraseña en el primer ingreso.

✅ Recuperación de contraseña mediante correo electrónico.

✅ CRUD completo según permisos del usuario.

✅ Captura automática de:

- 📷 Fotografía de la mascota
- 📍 Coordenadas GPS

✅ Dashboard dinámico con estadísticas por:

- Sectores
- Especies
- Vacunadores

✅ Funcionamiento Offline.

✅ Persistencia local en Firestore.

✅ Splash Screen personalizado.

✅ Ícono nativo para Android.

---

# ⚙️ Instalación

## 1️⃣ Clonar el repositorio

```bash
git clone https://github.com/nayelyayol/examen_pruebabimestral_ayolnayely_perezalessia.git
```

---

## 2️⃣ Instalar dependencias

```bash
flutter pub get
```

---

## 3️⃣ Inicializar Firebase

En `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

  } catch (e) {
    print(e);
  }

  runApp(const MyApp());
}
```

---

## 4️⃣ Dependencias principales

```yaml
dependencies:
  flutter:
    sdk: flutter

  firebase_core: ^4.11.0
  firebase_auth: ^6.5.4
  cloud_firestore: ^6.6.0
  firebase_storage: ^13.0.0

  image_picker: ^1.1.2
  geolocator: ^14.0.2

  provider: ^6.1.5+1
  shared_preferences: ^2.5.5
```

---

# 🎨 Personalización de la aplicación

## 📱 Ícono

Configurado mediante **flutter_launcher_icons**.

```bash
flutter pub run flutter_launcher_icons
```

---

## 🚀 Splash Screen

Generado utilizando **flutter_native_splash**.

```bash
flutter pub run flutter_native_splash:create
```

---

# ▶️ Ejecución

## Ejecutar la aplicación

```bash
flutter run
```

---

## Generar APK

```bash
flutter build apk --release
```

---

# 📦 Descargar APK

📥 **Enlace de descarga de APK**

> https://drive.google.com/drive/folders/1KuWEBt3HM_LgJdgVyyUGuGIKcxKlRYVz?usp=sharing

---

# 🔐 Credenciales de prueba

| Rol | Usuario | Contraseña |
|------|----------|------------|
| 👨‍💼 Coordinador de Campaña | `campana@vet.com` | `Ecuador2026` |
| 👷 Coordinador de Brigada | `nayelyayol3@gmail.com ` | `Ecuador2026..` |
| 💉 Vacunador | `liam@gmail.com ` | `Ecuador2026.` |

> **Nota:** En el primer inicio de sesión el sistema solicitará cambiar la contraseña por motivos de seguridad.

---

# 📷 Capturas del sistema

| Splash Screen | Ícono |
|---------------|-------|
|<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/a774782d-e7a6-462f-bd05-442e1428c834" />|<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/9721aac5-fb49-4988-929c-011b271a2661" />|

| Login | Dashboard |
|-------|-----------|
|<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/1425e55d-a81c-45a1-99ae-141df8541323" />|<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/fb472975-d863-45ec-a538-3b25336c55c9" />|

| Gestión de sectores | Formulario para creación de sectores |
|------------|-------|
|<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/bdd1dd79-12e2-4e27-802d-7004bf80cba0" />|<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/9bc1a8d3-f1e7-4e4b-93d1-da1e4acf1288" />|

|Coordinadores de birgada | Formulario para coordinador de brigada |
|------------|-------|
|<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/2f63916a-9615-4e35-b05e-17acc96645d9" />| <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/029fed5a-1e0e-4883-9bcd-32c2ecd54ea5" />|

| Formulario de vacunación | Fotografía y GPS |
|-----------------|--------------|
| <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/ee551016-5112-4b8e-9175-9f36c8f7438d" />|<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/3a24561e-68de-4bb4-a633-ba7217ed310c" />|

---

# ✅ Resultados obtenidos

- 🔐 Control de accesos seguro mediante Firebase Authentication.
- 📷 Captura de fotografías almacenadas en Firebase Storage.
- 📍 Registro automático de ubicación GPS.
- 📊 Dashboards dinámicos con indicadores de campaña.
- 🌐 Funcionamiento Offline gracias a la persistencia local de Firestore.
- 📱 Interfaz adaptada para dispositivos Android.
- ⚡ Sincronización automática con Firebase cuando existe conexión.
