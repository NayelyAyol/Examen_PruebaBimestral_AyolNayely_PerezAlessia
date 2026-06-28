import 'package:flutter/material.dart';

import '../../models/vaccination_model.dart';
import '../../services/vaccination_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';
import 'vaccination_form_page.dart';

class VaccinationsPage extends StatefulWidget {
  const VaccinationsPage({super.key});

  @override
  State<VaccinationsPage> createState() => _VaccinationsPageState();
}

class _VaccinationsPageState extends State<VaccinationsPage> {
  final VaccinationService _vaccinationService = VaccinationService();

  // Abre el formulario para crear o editar vacunación
  void _openForm({VaccinationModel? vaccination}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VaccinationFormPage(
          vaccinationToEdit: vaccination,
        ),
      ),
    );
  }

  // Confirma eliminación del registro
  Future<void> _confirmDelete(VaccinationModel vaccination) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar vacunación'),
          content: Text(
            '¿Deseas eliminar el registro de ${vaccination.petName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: VetTheme.accent,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _vaccinationService.deleteVaccination(vaccination.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vacunación eliminada correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Tarjeta de cada vacunación
  Widget _buildVaccinationCard(VaccinationModel vaccination) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vaccination.photoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  vaccination.photoUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 14),

            Row(
              children: [
                CircleAvatar(
                  backgroundColor: VetTheme.primary.withOpacity(0.14),
                  child: Icon(
                    vaccination.petType == 'Gato'
                        ? Icons.cruelty_free_outlined
                        : Icons.pets,
                    color: VetTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vaccination.petName,
                    style: const TextStyle(
                      color: VetTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(vaccination.petType),
                  backgroundColor: VetTheme.primary.withOpacity(0.12),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Text(
              'Propietario: ${vaccination.ownerName}',
              style: const TextStyle(color: VetTheme.textDark),
            ),
            Text(
              'Cédula: ${vaccination.ownerCedula}',
              style: const TextStyle(color: VetTheme.textLight),
            ),
            Text(
              'Teléfono: ${vaccination.ownerPhone}',
              style: const TextStyle(color: VetTheme.textLight),
            ),
            const SizedBox(height: 8),
            Text(
              'Vacuna: ${vaccination.vaccineName}',
              style: const TextStyle(
                color: VetTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Sector: ${vaccination.sectorName}',
              style: const TextStyle(color: VetTheme.textLight),
            ),
            Text(
              'Vacunador: ${vaccination.vaccinatorName}',
              style: const TextStyle(color: VetTheme.textLight),
            ),
            Text(
              'GPS: ${vaccination.latitude}, ${vaccination.longitude}',
              style: const TextStyle(color: VetTheme.textLight, fontSize: 12),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openForm(vaccination: vaccination),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(vaccination),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VetTheme.accent,
                      side: const BorderSide(color: VetTheme.accent),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Construye la interfaz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacunaciones'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: StreamBuilder<List<VaccinationModel>>(
          stream: _vaccinationService.getVaccinationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: VetTheme.primary),
              );
            }

            final vaccinations = snapshot.data ?? [];

            if (vaccinations.isEmpty) {
              return Center(
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.vaccines_outlined,
                        color: VetTheme.primary,
                        size: 56,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay vacunaciones registradas',
                        style: TextStyle(
                          color: VetTheme.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Registra la primera vacunación con foto y GPS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: VetTheme.textLight),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva Vacunación'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 760;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 900 : double.infinity,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.all(isWide ? 28 : 18),
                      itemCount: vaccinations.length,
                      itemBuilder: (context, index) {
                        return _buildVaccinationCard(vaccinations[index]);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}