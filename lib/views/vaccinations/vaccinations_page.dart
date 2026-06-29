import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vaccination_model.dart';
import '../../services/auth_service.dart';
import '../../services/vaccination_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';
import 'vaccination_form_page.dart';

class VaccinationsPage extends StatefulWidget {
  final String title;
  final bool canCreate;
  final bool onlyMine;
  final bool canEdit;
  final String? sectorId;
  final String? sectorNombre;
  final List<String>? allowedSectorIds;

  const VaccinationsPage({
    super.key,
    this.title = 'Vacunaciones',
    this.canCreate = true,
    this.onlyMine = false,
    this.canEdit = true,
    this.sectorId,
    this.sectorNombre,
    this.allowedSectorIds,
  });

  @override
  State<VaccinationsPage> createState() => _VaccinationsPageState();
}

class _VaccinationsPageState extends State<VaccinationsPage> {
  final VaccinationService _vaccinationService = VaccinationService();

  String? _selectedSectorName;

  Widget _buildPhoto(String photoPath) {
    if (photoPath.isEmpty) return const SizedBox.shrink();

    final file = File(photoPath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: file.existsSync()
          ? Image.file(
              file,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : Container(
              height: 150,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.broken_image_outlined,
                color: VetTheme.textLight,
                size: 42,
              ),
            ),
    );
  }

  Widget _petChip(String petType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VetTheme.primary, width: 1.4),
      ),
      child: Text(
        petType,
        style: const TextStyle(
          color: VetTheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSectorFilter(List<VaccinationModel> vaccinations) {
    if (widget.allowedSectorIds == null || vaccinations.isEmpty) {
      return const SizedBox.shrink();
    }

    final sectorNames =
        vaccinations
            .map((v) => v.sectorNombre.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (sectorNames.length <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar por sector',
              style: TextStyle(
                color: VetTheme.textDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChipButton(
                  label: 'Todos',
                  selected: _selectedSectorName == null,
                  onTap: () {
                    setState(() => _selectedSectorName = null);
                  },
                ),
                ...sectorNames.map(
                  (sectorName) => _FilterChipButton(
                    label: sectorName,
                    selected: _selectedSectorName == sectorName,
                    onTap: () {
                      setState(() => _selectedSectorName = sectorName);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccinationCard(VaccinationModel vaccination) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhoto(vaccination.fotografia),
            if (vaccination.fotografia.isNotEmpty) const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: VetTheme.primary.withOpacity(0.14),
                  child: Icon(
                    vaccination.tipoMascota.toLowerCase() == 'gato'
                        ? Icons.cruelty_free_outlined
                        : Icons.pets,
                    color: VetTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vaccination.nombreMascota,
                    style: const TextStyle(
                      color: VetTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _petChip(vaccination.tipoMascota),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Propietario: ${vaccination.nombrePropietario}',
              style: const TextStyle(color: VetTheme.textDark),
            ),
            Text(
              'Cédula: ${vaccination.cedulaPropietario}',
              style: const TextStyle(color: VetTheme.textLight),
            ),
            Text(
              'Teléfono: ${vaccination.telefono}',
              style: const TextStyle(color: VetTheme.textLight),
            ),
            Text(
              'Vacunador: ${vaccination.vacunadorNombre.isEmpty ? "Sin asignar" : vaccination.vacunadorNombre}',
              style: const TextStyle(color: VetTheme.textLight),
            ),
            Text(
              'Sector: ${vaccination.sectorNombre.isEmpty ? "Sin sector" : vaccination.sectorNombre}',
              style: const TextStyle(color: VetTheme.textLight),
            ),
            const SizedBox(height: 8),
            Text(
              'Vacuna: ${vaccination.vacunaAplicada}',
              style: const TextStyle(
                color: VetTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'GPS: ${vaccination.latitud.toStringAsFixed(6)}, ${vaccination.longitud.toStringAsFixed(6)}',
              style: const TextStyle(color: VetTheme.textLight, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              'Fecha: ${_formatDate(vaccination.fechaHora)}',
              style: const TextStyle(color: VetTheme.textLight, fontSize: 12),
            ),
            if (widget.canEdit) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VaccinationFormPage(
                          vaccinationToEdit: vaccination,
                          sectorId: vaccination.sectorId,
                          sectorNombre: vaccination.sectorNombre,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Corregir registro'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  Stream<List<VaccinationModel>> _getStream(String? userId) {
    if (widget.sectorId != null && widget.onlyMine && userId != null) {
      return _vaccinationService.getVaccinationsBySectorAndVaccinator(
        widget.sectorId!,
        userId,
      );
    }

    if (widget.sectorId != null) {
      return _vaccinationService.getVaccinationsBySector(widget.sectorId!);
    }

    if (widget.onlyMine && userId != null) {
      return _vaccinationService.getVaccinationsByVaccinator(userId);
    }

    return _vaccinationService.getVaccinations();
  }

  List<VaccinationModel> _applyAllowedSectorFilter(
    List<VaccinationModel> vaccinations,
  ) {
    if (widget.allowedSectorIds == null) return vaccinations;

    return vaccinations.where((vaccination) {
      return widget.allowedSectorIds!.contains(vaccination.sectorId);
    }).toList();
  }

  List<VaccinationModel> _applySelectedSectorNameFilter(
    List<VaccinationModel> vaccinations,
  ) {
    if (_selectedSectorName == null) return vaccinations;

    return vaccinations.where((vaccination) {
      return vaccination.sectorNombre == _selectedSectorName;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final stream = _getStream(user?.uid);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: widget.canCreate
          ? FloatingActionButton.extended(
              onPressed: () {
                if (widget.sectorId == null || widget.sectorNombre == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Para crear una vacunación debes entrar desde un sector.',
                      ),
                      backgroundColor: VetTheme.accent,
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VaccinationFormPage(
                      sectorId: widget.sectorId,
                      sectorNombre: widget.sectorNombre,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva'),
            )
          : null,
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: StreamBuilder<List<VaccinationModel>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error al cargar vacunaciones:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: VetTheme.accent),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: VetTheme.primary),
              );
            }

            final allowedVaccinations = _applyAllowedSectorFilter(
              snapshot.data ?? [],
            );

            final visibleVaccinations = _applySelectedSectorNameFilter(
              allowedVaccinations,
            );

            if (allowedVaccinations.isEmpty) {
              return const Center(
                child: Text(
                  'No hay vacunaciones registradas',
                  style: TextStyle(color: VetTheme.textLight),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: visibleVaccinations.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSectorFilter(allowedVaccinations);
                }

                return _buildVaccinationCard(visibleVaccinations[index - 1]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      showCheckmark: false,
      selectedColor: VetTheme.primary.withOpacity(0.18),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: selected ? VetTheme.primary : VetTheme.primary.withOpacity(0.35),
      ),
      labelStyle: TextStyle(
        color: selected ? VetTheme.primary : VetTheme.textDark,
        fontWeight: selected ? FontWeight.bold : FontWeight.w600,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
