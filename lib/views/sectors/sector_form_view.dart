import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/sector_model.dart';
import '../../models/coordinator_model.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

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
  String _selectedStatus = 'Pendiente';
  String? _selectedCoordinatorId;
  String? _selectedCoordinatorName;

  final List<String> _zones = ['Norte', 'Sur', 'Centro', 'Valles'];
  final List<String> _statuses = ['Pendiente', 'En Proceso', 'Completado'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.sectorToEdit?.name ?? '');
    _descController = TextEditingController(text: widget.sectorToEdit?.description ?? '');
    
    if (widget.sectorToEdit != null) {
      _selectedZone = widget.sectorToEdit!.zone;
      _selectedStatus = widget.sectorToEdit!.status;
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

    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      final sector = SectorModel(
        id: widget.sectorToEdit?.id ?? '',
        name: _nameController.text.trim(),
        zone: _selectedZone,
        description: _descController.text.trim(),
        status: _selectedStatus,
        assignedCoordinatorId: _selectedCoordinatorId,
        assignedCoordinatorName: _selectedCoordinatorName,
      );

      if (widget.sectorToEdit == null) {
        // Crear sector
        await firestoreService.addSector(sector);
      } else {
        // Editar sector
        await firestoreService.updateSector(sector);
      }

      // Si se le asignó un coordinador, actualizar también los sectores asignados en el coordinador.
      if (_selectedCoordinatorId != null) {
        // Hacemos una sincronización rápida
        await firestoreService.syncSectorAssignments(
          _selectedCoordinatorId!,
          _selectedCoordinatorName ?? '',
          [sector.id], // Asigna a este sector
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.sectorToEdit == null 
                ? 'Sector creado exitosamente' 
                : 'Sector actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar sector: $e'),
          backgroundColor: VetTheme.accent,
        ),
      );
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
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
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
                        isEditing ? 'Modificar Información' : 'Registrar Sector Geográfico',
                        style: const TextStyle(
                          color: VetTheme.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nombre del Sector
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

                      // Dropdown Zona
                      DropdownButtonFormField<String>(
                        value: _selectedZone,
                        decoration: const InputDecoration(
                          labelText: 'Zona Geográfica',
                          prefixIcon: Icon(Icons.share_location, color: VetTheme.primary),
                        ),
                        items: _zones.map((zone) {
                          return DropdownMenuItem(value: zone, child: Text(zone));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedZone = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dropdown Estado
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Estado de la Campaña',
                          prefixIcon: Icon(Icons.checklist, color: VetTheme.primary),
                        ),
                        items: _statuses.map((status) {
                          return DropdownMenuItem(value: status, child: Text(status));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedStatus = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dropdown Asignar Coordinador
                      StreamBuilder<List<CoordinatorModel>>(
                        stream: firestoreService.getCoordinatorsStream(),
                        builder: (context, snapshot) {
                          final coordinators = snapshot.data ?? [];
                          
                          // Asegurar que si el coordinador actual está asignado aparezca en la lista
                          return DropdownButtonFormField<String?>(
                            value: _selectedCoordinatorId,
                            decoration: const InputDecoration(
                              labelText: 'Asignar Coordinador de Brigada',
                              prefixIcon: Icon(Icons.person, color: VetTheme.primary),
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
                              })
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedCoordinatorId = val;
                                if (val == null) {
                                  _selectedCoordinatorName = null;
                                } else {
                                  final selected = coordinators.firstWhere((c) => c.id == val);
                                  _selectedCoordinatorName = selected.nombreCompleto;
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Descripción / Detalles
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

                      // Botón Guardar
                      CustomButton(
                        text: isEditing ? 'Guardar Cambios' : 'Registrar Sector',
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
