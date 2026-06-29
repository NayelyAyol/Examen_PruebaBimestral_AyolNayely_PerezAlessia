import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      final user = authService.currentUser;

      if (user == null) {
        setState(() {
          _errorMessage = 'El correo no está registrado.';
        });
        return;
      }

      if (user.isFirstLogin) {
        Navigator.pushReplacementNamed(context, '/change_password');
        return;
      }

      if (user.role == 'coordinador_campana') {
        Navigator.pushReplacementNamed(context, '/campana_dashboard');
      } else if (user.role == 'coordinador_brigada') {
        Navigator.pushReplacementNamed(context, '/brigada_dashboard');
      } else if (user.role == 'vacunador') {
        Navigator.pushReplacementNamed(context, '/vaccinator_dashboard');
      } else {
        setState(() {
          _errorMessage = 'Usuario deshabilitado.';
        });
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Correo o contraseña incorrectos.';

      switch (e.code) {
        case 'invalid-email':
          mensaje = 'Correo electrónico inválido.';
          break;
        case 'user-not-found':
          mensaje = 'El correo no está registrado.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          mensaje = 'Correo o contraseña incorrectos.';
          break;
        case 'user-disabled':
          mensaje = 'Usuario deshabilitado.';
          break;
      }

      setState(() {
        _errorMessage = mensaje;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Correo o contraseña incorrectos.';
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
    return Scaffold(
      body: Container(
        decoration: VetTheme.backgroundGradient,
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.pets,
                size: 80,
                color: VetTheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'VetCampaign',
                style: TextStyle(
                  color: VetTheme.textDark,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                'Gestión de Campañas Veterinarias',
                style: TextStyle(
                  color: VetTheme.textLight,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              GlassCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          color: VetTheme.textDark,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: VetTheme.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: VetTheme.accent.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: VetTheme.accent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: VetTheme.accent,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El correo es obligatorio';
                          }

                          final emailRegExp = RegExp(
                            r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
                          );

                          if (!emailRegExp.hasMatch(value.trim())) {
                            return 'Ingresa un correo electrónico válido';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Contraseña',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La contraseña es obligatoria';
                          }

                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgot_password');
                          },
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: VetTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      CustomButton(
                        text: 'Ingresar',
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Modo Demo Credenciales:\nAdmin: campana@vet.com | Brigada: brigada@vet.com\nContraseña inicial: Ecuador2026',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: VetTheme.textLight.withOpacity(0.8),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}