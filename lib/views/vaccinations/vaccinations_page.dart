import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vaccination_model.dart';
import '../../services/auth_service.dart';
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

  // Según el rol, cargamos las vacunaciones que puede ver
  Stream<List<VaccinationModel>> _getVaccinationsByRole() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return Stream.value([]);

    // Campaña ve todo
    if (user.role == 'coordinador_campana') {
      return _vaccinationService.getVaccinationsStream();
    }

    // Vacunador solo ve sus propios registros
    if (user.role == 'vacunador') {
      return _vaccinationService.getVaccinationsByVaccinator(user.uid);
    }

    // Brigada por ahora ve registros para corregir
    // Si luego agregamos sectores al UserModel, aquí filtramos por sector.
    if (user.role == 'coordinador_brigada') {
      return _vaccinationService.getVaccinationsStream();
    }

    return Stream.value([]);
  }

  void _openForm({VaccinationModel? vaccination}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VaccinationFormPage(vaccinationToEdit: vaccination),
      ),
    );
  }

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

  Widget _buildVaccinationCard(VaccinationModel vaccination) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    // Permisos sencillos por rol
    final canEdit = user?.role == 'coordinador_campana' ||
        user?.role == 'coordinador_brigada' ||
        vaccination.vaccinatorId == user?.uid;

    final canDelete = user?.role == 'coordinador_campana' ||
        user?.role == 'coordinador_brigada';

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
              style: const TextStyle(
                color: VetTheme.textLight,
                fontSize: 12,
              ),
            ),

            if (canEdit || canDelete) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (canEdit)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openForm(vaccination: vaccination),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                    ),

                  if (canEdit && canDelete) const SizedBox(width: 12),

                  if (canDelete)
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

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
          stream: _getVaccinationsByRole(),
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
                      Text(
                        user?.role == 'vacunador'
                            ? 'Registra tu primera vacunación con foto y GPS.'
                            : 'Todavía no existen registros para mostrar.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: VetTheme.textLight),
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