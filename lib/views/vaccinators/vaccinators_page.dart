import 'package:flutter/material.dart';

import '../../models/vaccinator_model.dart';
import '../../services/vaccinator_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';
import 'vaccinator_form_page.dart';

class VaccinatorsPage extends StatefulWidget {
  const VaccinatorsPage({super.key});

  @override
  State<VaccinatorsPage> createState() => _VaccinatorsPageState();
}

class _VaccinatorsPageState extends State<VaccinatorsPage> {
  final VaccinatorService _vaccinatorService = VaccinatorService();
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtra vacunadores por nombre, cédula o correo
  List<VaccinatorModel> _filterVaccinators(List<VaccinatorModel> vaccinators) {
    if (_searchText.trim().isEmpty) return vaccinators;

    final query = _searchText.toLowerCase();

    return vaccinators.where((vaccinator) {
      return vaccinator.nombreCompleto.toLowerCase().contains(query) ||
          vaccinator.cedula.toLowerCase().contains(query) ||
          vaccinator.email.toLowerCase().contains(query);
    }).toList();
  }

  // Abre el formulario para crear o editar vacunador
  void _openForm({VaccinatorModel? vaccinator}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VaccinatorFormPage(
          vaccinatorToEdit: vaccinator,
        ),
      ),
    );
  }

  // Confirma la eliminación del vacunador
  Future<void> _confirmDelete(VaccinatorModel vaccinator) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar vacunador'),
          content: Text(
            '¿Deseas eliminar a ${vaccinator.nombreCompleto}?',
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

    try {
      await _vaccinatorService.deleteVaccinator(vaccinator.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vacunador eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar vacunador: $e'),
          backgroundColor: VetTheme.accent,
        ),
      );
    }
  }

  // Construye la tarjeta de cada vacunador
  Widget _buildVaccinatorCard(VaccinatorModel vaccinator, bool isWide) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        child: isWide
            ? Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInfo(vaccinator)),
                  _buildActions(vaccinator),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 14),
                      Expanded(child: _buildInfo(vaccinator)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildActions(vaccinator),
                ],
              ),
      ),
    );
  }

  // Avatar visual del vacunador
  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: VetTheme.primary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.vaccines_outlined,
        color: VetTheme.primary,
        size: 26,
      ),
    );
  }

  // Información principal del vacunador
  Widget _buildInfo(VaccinatorModel vaccinator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          vaccinator.nombreCompleto,
          style: const TextStyle(
            color: VetTheme.textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          vaccinator.email,
          style: const TextStyle(
            color: VetTheme.textLight,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildChip(Icons.badge_outlined, vaccinator.cedula),
            _buildChip(Icons.phone_outlined, vaccinator.telefono),
            _buildChip(
              Icons.map_outlined,
              '${vaccinator.assignedSectorIds.length} sectores',
            ),
            _buildStatusChip(vaccinator.status),
          ],
        ),
      ],
    );
  }

  // Chip informativo
  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: VetTheme.primary.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: VetTheme.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: VetTheme.textDark,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Chip de estado
  Widget _buildStatusChip(String status) {
    final isActive = status == 'Activo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.12)
            : VetTheme.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : VetTheme.accent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Botones de editar y eliminar
  Widget _buildActions(VaccinatorModel vaccinator) {
    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _openForm(vaccinator: vaccinator),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Editar'),
        ),
        OutlinedButton.icon(
          onPressed: () => _confirmDelete(vaccinator),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Eliminar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: VetTheme.accent,
            side: const BorderSide(color: VetTheme.accent),
          ),
        ),
      ],
    );
  }

  // Vista cuando no existen vacunadores
  Widget _buildEmptyState() {
    return GlassCard(
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.vaccines_outlined,
              color: VetTheme.primary,
              size: 54,
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay vacunadores registrados',
              style: TextStyle(
                color: VetTheme.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crea el primer vacunador para asignarlo a sectores.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: VetTheme.textLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Vacunador'),
            ),
          ],
        ),
      ),
    );
  }

  // Construye la interfaz principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Vacunadores'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 760;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 1000 : double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 28 : 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vacunadores',
                          style: TextStyle(
                            color: VetTheme.textDark,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Crea, edita y asigna vacunadores a sectores.',
                          style: TextStyle(
                            color: VetTheme.textLight,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchText = value);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Buscar vacunador',
                            prefixIcon: Icon(
                              Icons.search,
                              color: VetTheme.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Expanded(
                          child: StreamBuilder<List<VaccinatorModel>>(
                            stream: _vaccinatorService.getVaccinatorsStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: VetTheme.primary,
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error al cargar vacunadores: ${snapshot.error}',
                                    style: const TextStyle(
                                      color: VetTheme.accent,
                                    ),
                                  ),
                                );
                              }

                              final vaccinators = _filterVaccinators(
                                snapshot.data ?? [],
                              );

                              if (vaccinators.isEmpty) {
                                return _buildEmptyState();
                              }

                              return ListView.builder(
                                itemCount: vaccinators.length,
                                itemBuilder: (context, index) {
                                  return _buildVaccinatorCard(
                                    vaccinators[index],
                                    isWide,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}