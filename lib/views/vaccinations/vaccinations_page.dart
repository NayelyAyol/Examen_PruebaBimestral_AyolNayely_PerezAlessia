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

  const VaccinationsPage({
    super.key,
    this.title = 'Vacunaciones',
    this.canCreate = true,
    this.onlyMine = false,
    this.canEdit = true,
  });

  @override
  State<VaccinationsPage> createState() => _VaccinationsPageState();
}

class _VaccinationsPageState extends State<VaccinationsPage> {
  final VaccinationService _vaccinationService = VaccinationService();

  Widget _buildPhoto(String photoUrl) {
    if (photoUrl.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        photoUrl,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 150,
            alignment: Alignment.center,
            color: Colors.white.withOpacity(0.45),
            child: const CircularProgressIndicator(color: VetTheme.primary),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.broken_image_outlined,
              color: VetTheme.textLight,
              size: 42,
            ),
          );
        },
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
                Chip(
                  label: Text(vaccination.tipoMascota),
                  backgroundColor: VetTheme.primary.withOpacity(0.12),
                ),
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
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(widget.canCreate ? 'Editar' : 'Corregir'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    final stream = widget.onlyMine && user != null
        ? _vaccinationService.getVaccinationsByVaccinator(user.uid)
        : _vaccinationService.getVaccinations();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: widget.canCreate
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VaccinationFormPage(),
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
                child: Text(
                  'Error al cargar vacunaciones:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: VetTheme.accent),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: VetTheme.primary),
              );
            }

            final vaccinations = snapshot.data ?? [];

            if (vaccinations.isEmpty) {
              return const Center(
                child: Text(
                  'No hay vacunaciones registradas',
                  style: TextStyle(color: VetTheme.textLight),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: vaccinations.length,
              itemBuilder: (context, index) {
                return _buildVaccinationCard(vaccinations[index]);
              },
            );
          },
        ),
      ),
    );
  }
}