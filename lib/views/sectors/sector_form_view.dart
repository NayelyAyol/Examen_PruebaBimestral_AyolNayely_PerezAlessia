import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/coordinator_model.dart';
import '../../models/sector_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/glass_card.dart';

class SectorFormView extends StatefulWidget {
  final SectorModel? sectorToEdit;

  const SectorFormView({super.key, this.sectorToEdit});

  @override
  State<SectorFormView> createState() => _SectorFormViewState();
}

class _SectorFormViewState extends State<SectorFormView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;

  String _selectedZone = 'Norte';
  String? _selectedCoordinatorId;
  String? _selectedCoordinatorName;

  final List<String> _zones = ['Norte', 'Sur', 'Centro', 'Valles'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.sectorToEdit?.name ?? '',
    );
    _descController = TextEditingController(
      text: widget.sectorToEdit?.description ?? '',
    );

    if (widget.sectorToEdit != null) {
      _selectedZone = widget.sectorToEdit!.zone;
      _selectedCoordinatorId = widget.sectorToEdit!.assignedCoordinatorId;
      _selectedCoordinatorName = widget.sectorToEdit!.assignedCoordinatorName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      final sector = SectorModel(
        id: widget.sectorToEdit?.id ?? '',
        name: _nameController.text.trim(),
        zone: _selectedZone,
        description: _descController.text.trim(),
        assignedCoordinatorId: _selectedCoordinatorId,
        assignedCoordinatorName: _selectedCoordinatorName,
      );

      if (widget.sectorToEdit == null) {
        await firestoreService.addSector(sector);
      } else {
        await firestoreService.updateSector(sector);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.sectorToEdit == null
                ? 'Sector creado exitosamente'
                : 'Sector actualizado exitosamente',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar sector: $e'),
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
    final isEditing = widget.sectorToEdit != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: VetTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Editar Sector' : 'Nuevo Sector'),
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing
                        ? 'Modificar Información'
                        : 'Registrar Sector Geográfico',
                    style: const TextStyle(
                      color: VetTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Nombre del Sector',
                    prefixIcon: Icons.map,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre del sector es obligatorio';
                      }
                      if (value.trim().length < 3) {
                        return 'Debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedZone,
                    decoration: const InputDecoration(
                      labelText: 'Zona Geográfica',
                      prefixIcon: Icon(
                        Icons.share_location,
                        color: VetTheme.primary,
                      ),
                    ),
                    items: _zones.map((zone) {
                      return DropdownMenuItem(
                        value: zone,
                        child: Text(zone),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedZone = value);
                    },
                  ),

                  const SizedBox(height: 16),

                  StreamBuilder<List<CoordinatorModel>>(
                    stream: firestoreService.getCoordinatorsStream(),
                    builder: (context, snapshot) {
                      final coordinators = snapshot.data ?? [];

                      return DropdownButtonFormField<String?>(
                        value: _selectedCoordinatorId,
                        decoration: const InputDecoration(
                          labelText: 'Asignar Coordinador de Brigada',
                          prefixIcon: Icon(
                            Icons.person,
                            color: VetTheme.primary,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Sin Coordinador (Ninguno)'),
                          ),
                          ...coordinators.map((c) {
                            return DropdownMenuItem<String?>(
                              value: c.id,
                              child: Text('${c.nombreCompleto} (${c.cedula})'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCoordinatorId = value;

                            if (value == null) {
                              _selectedCoordinatorName = null;
                            } else {
                              final selected = coordinators.firstWhere(
                                (c) => c.id == value,
                              );
                              _selectedCoordinatorName =
                                  selected.nombreCompleto;
                            }
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _descController,
                    labelText: 'Descripción / Actividades a Realizar',
                    prefixIcon: Icons.description_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La descripción es obligatoria';
                      }
                      if (value.trim().length < 10) {
                        return 'Describe en al menos 10 caracteres las actividades.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  CustomButton(
                    text: isEditing ? 'Guardar Cambios' : 'Registrar Sector',
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
  }
}