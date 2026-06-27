import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Llamar al cambio de contraseña en Auth
      await authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;

      // Mostrar diálogo de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset, color: VetTheme.primary, size: 28),
                SizedBox(width: 10),
                Text('Contraseña Actualizada', style: TextStyle(color: VetTheme.textDark, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Tu contraseña se ha cambiado exitosamente. Ahora accederás al panel principal.',
              style: TextStyle(color: VetTheme.textLight, fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  
                  // Redirigir según el rol del usuario actual
                  final user = authService.currentUser;
                  if (user != null) {
                    if (user.role == 'coordinador_campana') {
                      Navigator.pushReplacementNamed(context, '/campana_dashboard');
                    } else {
                      Navigator.pushReplacementNamed(context, '/brigada_dashboard');
                    }
                  } else {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: const Text(
                  'Continuar',
                  style: TextStyle(color: VetTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('FirebaseAuthException: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    // Si isFirstLogin es true, se muestra un mensaje informativo especial de cambio obligatorio
    final bool isForced = user?.isFirstLogin ?? false;

    return Scaffold(
      appBar: AppBar(
        // Si es cambio forzado, no permitimos regresar atrás para que no evadan el cambio de contraseña
        leading: isForced
            ? const SizedBox() 
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: VetTheme.textDark),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(isForced ? 'Primer Inicio de Sesión' : 'Cambiar Contraseña'),
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isForced ? Icons.security : Icons.vpn_key_outlined,
                size: 80,
                color: VetTheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                isForced ? 'Actualización Obligatoria' : 'Cambia tu contraseña',
                style: const TextStyle(
                  color: VetTheme.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isForced
                    ? 'Por seguridad, debes cambiar tu contraseña inicial asignada (Ecuador2026) antes de ingresar al sistema.'
                    : 'Ingresa tu contraseña actual y la nueva contraseña para actualizar tu cuenta.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: VetTheme.textLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              GlassCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: VetTheme.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: VetTheme.accent.withOpacity(0.3)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: VetTheme.accent, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Contraseña Actual
                      CustomTextField(
                        controller: _currentPasswordController,
                        labelText: 'Contraseña Actual',
                        prefixIcon: Icons.lock_open,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña actual';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nueva Contraseña
                      CustomTextField(
                        controller: _newPasswordController,
                        labelText: 'Nueva Contraseña',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La nueva contraseña es obligatoria';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          if (value == _currentPasswordController.text) {
                            return 'La nueva contraseña debe ser diferente a la actual';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirmar Nueva Contraseña
                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirmar Nueva Contraseña',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirma la nueva contraseña';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      CustomButton(
                        text: 'Guardar Contraseña',
                        isLoading: _isLoading,
                        onPressed: _handleChangePassword,
                      ),
                      
                      if (isForced) ...[
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Salir / Cancelar',
                          isSecondary: true,
                          onPressed: () {
                            Provider.of<AuthService>(context, listen: false).logout();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
