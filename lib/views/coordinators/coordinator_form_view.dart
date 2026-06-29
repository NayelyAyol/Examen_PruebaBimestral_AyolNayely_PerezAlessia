import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/coordinator_model.dart';
import '../../models/sector_model.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class CoordinatorFormView extends StatefulWidget {
  final CoordinatorModel? coordinatorToEdit;

  const CoordinatorFormView({super.key, this.coordinatorToEdit});

  @override
  State<CoordinatorFormView> createState() => _CoordinatorFormViewState();
}

class _CoordinatorFormViewState extends State<CoordinatorFormView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cedulaController;
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;

  List<String> _assignedSectorIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _cedulaController =
        TextEditingController(text: widget.coordinatorToEdit?.cedula ?? '');
    _nombresController =
        TextEditingController(text: widget.coordinatorToEdit?.nombres ?? '');
    _apellidosController =
        TextEditingController(text: widget.coordinatorToEdit?.apellidos ?? '');
    _telefonoController =
        TextEditingController(text: widget.coordinatorToEdit?.telefono ?? '');
    _emailController =
        TextEditingController(text: widget.coordinatorToEdit?.email ?? '');

    if (widget.coordinatorToEdit != null) {
      _assignedSectorIds = List<String>.from(
        widget.coordinatorToEdit!.assignedSectorIds,
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      final email = _emailController.text.trim();
      final nombres = _nombresController.text.trim();
      final apellidos = _apellidosController.text.trim();

      String uid;

      if (widget.coordinatorToEdit == null) {
        uid = await authService.createBrigadeCoordinatorUser(
          email: email,
          cedula: _cedulaController.text.trim(),
          nombres: nombres,
          apellidos: apellidos,
          telefono: _telefonoController.text.trim(),
        );
      } else {
        uid = widget.coordinatorToEdit!.id;
      }

      final coordinator = CoordinatorModel(
        id: uid,
        cedula: _cedulaController.text.trim(),
        nombres: nombres,
        apellidos: apellidos,
        telefono: _telefonoController.text.trim(),
        email: email,
        status: 'Activo',
        assignedSectorIds: _assignedSectorIds,
      );

      if (widget.coordinatorToEdit == null) {
        await firestoreService.saveCoordinatorProfile(uid, coordinator);
      } else {
        await firestoreService.updateCoordinator(coordinator);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.coordinatorToEdit == null
                ? 'Coordinador creado con contraseña Ecuador2026'
                : 'Coordinador actualizado correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar coordinador: $e'),
          backgroundColor: VetTheme.accent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final isEditing = widget.coordinatorToEdit != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: VetTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Editar Perfil' : 'Nuevo Coordinador'),
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              GlassCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing
                            ? 'Modificar Coordinador'
                            : 'Crear Cuenta de Brigadista',
                        style: const TextStyle(
                          color: VetTheme.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (!isEditing)
                        const Text(
                          'Se registrará con la contraseña predeterminada Ecuador2026.',
                          style: TextStyle(
                            color: VetTheme.textLight,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _cedulaController,
                        labelText: 'Número de Cédula',
                        prefixIcon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La cédula es obligatoria';
                          }
                          if (value.trim().length != 10) {
                            return 'La cédula debe tener exactamente 10 dígitos';
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return 'Solo se admiten números';
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
                          if (value == null || value.trim().isEmpty) {
                            return 'Los nombres son obligatorios';
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
                          if (value == null || value.trim().isEmpty) {
                            return 'Los apellidos son obligatorios';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _telefonoController,
                        labelText: 'Número de Teléfono',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El teléfono es obligatorio';
                          }
                          if (value.trim().length < 9) {
                            return 'Teléfono inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        enabled: !isEditing,
                        style: TextStyle(
                          color:
                              isEditing ? VetTheme.textLight : VetTheme.textDark,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: VetTheme.primary,
                          ),
                          fillColor: isEditing
                              ? Colors.black.withOpacity(0.05)
                              : Colors.white.withOpacity(0.6),
                        ),
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

                      const SizedBox(height: 24),

                      const Text(
                        'Asignar Sectores de Quito',
                        style: TextStyle(
                          color: VetTheme.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      StreamBuilder<List<SectorModel>>(
                        stream: firestoreService.getSectorsStream(),
                        builder: (context, snapshot) {
                          final sectors = snapshot.data ?? [];

                          if (sectors.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Cargando sectores disponibles...',
                                style: TextStyle(color: VetTheme.textLight),
                              ),
                            );
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: VetTheme.primary.withOpacity(0.15),
                              ),
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: sectors.length,
                              itemBuilder: (context, idx) {
                                final sector = sectors[idx];

                                final isAssignedToOther =
                                    sector.assignedCoordinatorId != null &&
                                        sector.assignedCoordinatorId !=
                                            widget.coordinatorToEdit?.id;

                                final isChecked =
                                    _assignedSectorIds.contains(sector.id);

                                return CheckboxListTile(
                                  activeColor: VetTheme.primary,
                                  title: Text(
                                    sector.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isAssignedToOther
                                        ? 'Asignado a: ${sector.assignedCoordinatorName}'
                                        : 'Zona: ${sector.zone}',
                                    style: TextStyle(
                                      color: isAssignedToOther
                                          ? VetTheme.accent
                                          : VetTheme.textLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                  value: isChecked,
                                  enabled: !isAssignedToOther,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _assignedSectorIds.add(sector.id);
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
                      ),

                      const SizedBox(height: 28),

                      CustomButton(
                        text: isEditing
                            ? 'Guardar Cambios'
                            : 'Registrar Coordinador',
                        isLoading: _isLoading,
                        onPressed: _handleSave,
                      ),
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