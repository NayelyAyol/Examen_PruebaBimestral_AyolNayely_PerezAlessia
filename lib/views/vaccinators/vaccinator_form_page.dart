import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sector_model.dart';
import '../../models/user_model.dart';
import '../../models/vaccinator_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/vaccinator_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/glass_card.dart';

class VaccinatorFormPage extends StatefulWidget {
  final VaccinatorModel? vaccinatorToEdit;

  const VaccinatorFormPage({
    super.key,
    this.vaccinatorToEdit,
  });

  @override
  State<VaccinatorFormPage> createState() => _VaccinatorFormPageState();
}

class _VaccinatorFormPageState extends State<VaccinatorFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cedulaController;
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;

  final VaccinatorService _vaccinatorService = VaccinatorService();

  List<String> _assignedSectorIds = [];
  bool _isLoading = false;

  bool get isEditing => widget.vaccinatorToEdit != null;

  @override
  void initState() {
    super.initState();

    _cedulaController = TextEditingController(
      text: widget.vaccinatorToEdit?.cedula ?? '',
    );
    _nombresController = TextEditingController(
      text: widget.vaccinatorToEdit?.nombres ?? '',
    );
    _apellidosController = TextEditingController(
      text: widget.vaccinatorToEdit?.apellidos ?? '',
    );
    _telefonoController = TextEditingController(
      text: widget.vaccinatorToEdit?.telefono ?? '',
    );
    _emailController = TextEditingController(
      text: widget.vaccinatorToEdit?.email ?? '',
    );

    if (isEditing) {
      _assignedSectorIds = List<String>.from(
        widget.vaccinatorToEdit!.assignedSectorIds,
      );
    }
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _hasOnlyLetters(String value) {
    return RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value.trim());
  }

  bool _hasOnlyNumbers(String value) {
    return RegExp(r'^[0-9]+$').hasMatch(value.trim());
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_assignedSectorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un sector para el vacunador.'),
          backgroundColor: VetTheme.accent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      String uid;

      if (!isEditing) {
        uid = await authService.createVaccinatorUser(
          email: _emailController.text.trim(),
          cedula: _cedulaController.text.trim(),
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          telefono: _telefonoController.text.trim(),
        );
      } else {
        uid = widget.vaccinatorToEdit!.id;
      }

      final vaccinator = VaccinatorModel(
        id: uid,
        cedula: _cedulaController.text.trim(),
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.trim(),
        status: 'Activo',
        assignedSectorIds: _assignedSectorIds,
      );

      if (isEditing) {
        await _vaccinatorService.updateVaccinator(vaccinator);
      } else {
        await _vaccinatorService.saveVaccinatorProfile(uid, vaccinator);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Vacunador actualizado correctamente'
                : 'Vacunador creado con contraseña Ecuador2026',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar vacunador: $e'),
          backgroundColor: VetTheme.accent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<SectorModel> _filterSectorsByRole(
    List<SectorModel> sectors,
    UserModel? user,
  ) {
    if (user == null) return sectors;

    if (user.rol == 'coordinador_brigada') {
      return sectors.where((sector) {
        return sector.assignedCoordinatorId == user.uid;
      }).toList();
    }

    return sectors;
  }

  Widget _buildSectorsList(
    FirestoreService firestoreService,
    UserModel? currentUser,
  ) {
    return StreamBuilder<List<SectorModel>>(
      stream: firestoreService.getSectorsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(
              child: CircularProgressIndicator(color: VetTheme.primary),
            ),
          );
        }

        final sectors = _filterSectorsByRole(
          snapshot.data ?? [],
          currentUser,
        );

        if (sectors.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No hay sectores disponibles para asignar.',
              style: TextStyle(color: VetTheme.textLight),
            ),
          );
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: VetTheme.primary.withOpacity(0.15),
            ),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sectors.length,
            itemBuilder: (context, index) {
              final sector = sectors[index];
              final isChecked = _assignedSectorIds.contains(sector.id);

              return CheckboxListTile(
                activeColor: VetTheme.primary,
                value: isChecked,
                title: Text(
                  sector.name,
                  style: const TextStyle(
                    color: VetTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Zona: ${sector.zone}',
                  style: const TextStyle(
                    color: VetTheme.textLight,
                    fontSize: 12,
                  ),
                ),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      if (!_assignedSectorIds.contains(sector.id)) {
                        _assignedSectorIds.add(sector.id);
                      }
                    } else {
                      _assignedSectorIds.remove(sector.id);
                    }
                  });
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final currentUser = Provider.of<AuthService>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Vacunador' : 'Nuevo Vacunador'),
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 760;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 760 : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isWide ? 32 : 20),
                  child: GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? 'Modificar datos del vacunador'
                                : 'Crear cuenta de vacunador',
                            style: const TextStyle(
                              color: VetTheme.textDark,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isEditing
                                ? 'Actualiza la información y reasigna sectores.'
                                : 'La contraseña inicial será Ecuador2026.',
                            style: const TextStyle(
                              color: VetTheme.textLight,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),

                          CustomTextField(
                            controller: _cedulaController,
                            labelText: 'Cédula',
                            prefixIcon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'La cédula es obligatoria';
                              }
                              if (!_hasOnlyNumbers(text)) {
                                return 'La cédula solo debe contener números';
                              }
                              if (text.length != 10) {
                                return 'La cédula debe tener 10 dígitos';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _nombresController,
                            labelText: 'Nombres',
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'Los nombres son obligatorios';
                              }
                              if (!_hasOnlyLetters(text)) {
                                return 'Los nombres solo deben contener letras';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _apellidosController,
                            labelText: 'Apellidos',
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'Los apellidos son obligatorios';
                              }
                              if (!_hasOnlyLetters(text)) {
                                return 'Los apellidos solo deben contener letras';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _telefonoController,
                            labelText: 'Teléfono',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'El teléfono es obligatorio';
                              }
                              if (!_hasOnlyNumbers(text)) {
                                return 'El teléfono solo debe contener números';
                              }
                              if (text.length != 10) {
                                return 'El teléfono debe tener 10 dígitos';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _emailController,
                            enabled: !isEditing,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: VetTheme.primary,
                              ),
                              fillColor: isEditing
                                  ? Colors.black.withOpacity(0.05)
                                  : Colors.white.withOpacity(0.6),
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'El correo es obligatorio';
                              }

                              final emailRegExp = RegExp(
                                r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
                              );

                              if (!emailRegExp.hasMatch(text)) {
                                return 'Ingresa un correo electrónico válido';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Asignar / reasignar sectores',
                            style: TextStyle(
                              color: VetTheme.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          _buildSectorsList(
                            firestoreService,
                            currentUser,
                          ),

                          const SizedBox(height: 28),

                          CustomButton(
                            text: isEditing
                                ? 'Guardar Cambios'
                                : 'Registrar Vacunador',
                            isLoading: _isLoading,
                            onPressed: _handleSave,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}