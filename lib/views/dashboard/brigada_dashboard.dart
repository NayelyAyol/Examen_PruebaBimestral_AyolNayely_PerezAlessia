import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sector_model.dart';
import '../../models/vaccination_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/vaccination_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';
import '../vaccinations/vaccinations_page.dart';

class BrigadaDashboard extends StatelessWidget {
  const BrigadaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    final vaccinationService = Provider.of<VaccinationService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Brigada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: VetTheme.textDark),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: StreamBuilder<List<SectorModel>>(
          stream: firestoreService.getSectorsStream(),
          builder: (context, sectorSnapshot) {
            return StreamBuilder<List<VaccinationModel>>(
              stream: vaccinationService.getVaccinations(),
              builder: (context, vaccinationSnapshot) {
                final sectors = sectorSnapshot.data ?? [];
                final vaccinations = vaccinationSnapshot.data ?? [];

                final mySectors = sectors
                    .where((s) => s.assignedCoordinatorId == user?.uid)
                    .toList();

                final mySectorIds = mySectors.map((s) => s.id).toList();

                final myVaccinations = vaccinations.where((v) {
                  return mySectorIds.contains(v.sectorId);
                }).toList();

                // Sincronización pendientes
                final pendingSectors = mySectors.where((s) => s.isPendingSync).length;
                final pendingVaccinations = myVaccinations.where((v) => v.isPendingSync).length;
                final pendingSyncCount = pendingSectors + pendingVaccinations;

                // Filtrar métricas principales solo para sincronizados
                final syncedSectors = mySectors.where((s) => !s.isPendingSync).toList();
                final syncedVaccinations = myVaccinations.where((v) => !v.isPendingSync).toList();

                final totalDogs = syncedVaccinations
                    .where((v) => v.tipoMascota.toLowerCase() == 'perro')
                    .length;

                final totalCats = syncedVaccinations
                    .where((v) => v.tipoMascota.toLowerCase() == 'gato')
                    .length;

                final assignedVaccinators = <String>{};
                for (final sector in syncedSectors) {
                  assignedVaccinators.addAll(sector.assignedVaccinatorIds);
                }

                final isLoading =
                    sectorSnapshot.connectionState == ConnectionState.waiting ||
                    vaccinationSnapshot.connectionState ==
                        ConnectionState.waiting;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final isTablet =
                        constraints.maxWidth >= 600 &&
                        constraints.maxWidth < 950;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 24,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GlassCard(
                            width: double.infinity,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: isMobile ? 24 : 28,
                                  backgroundColor: VetTheme.primary.withOpacity(
                                    0.18,
                                  ),
                                  child: const Icon(
                                    Icons.groups_2_outlined,
                                    color: VetTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '¡Hola, ${user?.name.split(" ").first ?? "Coordinador"}!',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: VetTheme.textDark,
                                          fontSize: isMobile ? 20 : 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Resumen de tus sectores, vacunadores y registros.',
                                        style: TextStyle(
                                          color: VetTheme.textLight,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          _buildSyncStatusBanner(pendingSyncCount, isMobile),

                          const SizedBox(height: 18),

                          if (isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(
                                  color: VetTheme.primary,
                                ),
                              ),
                            )
                          else
                            _MetricsGrid(
                              isMobile: isMobile,
                              isTablet: isTablet,
                              children: [
                                _MetricCard(
                                  title: 'Mis Sectores',
                                  value: syncedSectors.length.toString(),
                                  icon: Icons.map_outlined,
                                  color: VetTheme.primary,
                                ),
                                _MetricCard(
                                  title: 'Vacunadores',
                                  value: assignedVaccinators.length.toString(),
                                  icon: Icons.vaccines_outlined,
                                  color: Colors.blueAccent,
                                ),
                                _MetricCard(
                                  title: 'Vacunaciones',
                                  value: syncedVaccinations.length.toString(),
                                  icon: Icons.assignment_turned_in_outlined,
                                  color: Colors.green,
                                ),
                                _MetricCard(
                                  title: 'Perros / Gatos',
                                  value: '$totalDogs / $totalCats',
                                  icon: Icons.pets,
                                  color: VetTheme.accent,
                                ),
                              ],
                            ),

                          const SizedBox(height: 26),

                          const Text(
                            'Accesos rápidos',
                            style: TextStyle(
                              color: VetTheme.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _QuickAction(
                                  title: 'Vacunadores',
                                  icon: Icons.person_add_alt_1,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/vaccinators',
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _QuickAction(
                                  title: 'Registros',
                                  icon: Icons.fact_check_outlined,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VaccinationsPage(
                                          title: 'Registros de mis sectores',
                                          canCreate: false,
                                          canEdit: true,
                                          onlyMine: false,
                                          allowedSectorIds: mySectorIds,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 26),

                          const Text(
                            'Mis sectores asignados',
                            style: TextStyle(
                              color: VetTheme.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (mySectors.isEmpty)
                            GlassCard(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.assignment_late_outlined,
                                      size: 48,
                                      color: VetTheme.textLight.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No tienes sectores asignados en este momento.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: VetTheme.textLight,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: mySectors.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final sector = mySectors[index];

                                final sectorVaccinations = myVaccinations.where(
                                  (v) {
                                    return v.sectorId == sector.id;
                                  },
                                ).toList();

                                return _SectorDashboardCard(
                                  sector: sector,
                                  vaccinations: sectorVaccinations,
                                );
                              },
                            ),

                          const SizedBox(height: 24),

                          GlassCard(
                            width: double.infinity,
                            child: Text(
                              'Como Coordinador de Brigada, puedes gestionar vacunadores, asignarlos a tus sectores y corregir registros desde el módulo general de Registros.',
                              style: TextStyle(
                                color: VetTheme.textLight.withOpacity(0.9),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSyncStatusBanner(int pendingCount, bool isMobile) {
    final bool hasPending = pendingCount > 0;
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (hasPending ? Colors.orange : Colors.green).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPending ? Icons.sync_problem_outlined : Icons.cloud_done_outlined,
              color: hasPending ? Colors.orange : Colors.green,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPending ? 'Sincronización Pendiente' : 'Sincronizado con la nube',
                  style: const TextStyle(
                    color: VetTheme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPending
                      ? 'Tienes $pendingCount registro(s) guardado(s) en local que se sincronizarán al detectar internet.'
                      : 'Todos tus registros locales están sincronizados con la base de datos.',
                  style: const TextStyle(
                    color: VetTheme.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (hasPending) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                '$pendingCount pnd.',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectorDashboardCard extends StatelessWidget {
  final SectorModel sector;
  final List<VaccinationModel> vaccinations;

  const _SectorDashboardCard({
    required this.sector,
    required this.vaccinations,
  });

  @override
  Widget build(BuildContext context) {
    final dogs = vaccinations
        .where((v) => v.tipoMascota.toLowerCase() == 'perro')
        .length;

    final cats = vaccinations
        .where((v) => v.tipoMascota.toLowerCase() == 'gato')
        .length;

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sector.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: VetTheme.textDark,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Zona: ${sector.zone}',
            style: const TextStyle(
              color: VetTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sector.description,
            style: const TextStyle(
              color: VetTheme.textLight,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniChip(
                icon: Icons.assignment_turned_in_outlined,
                label: '${vaccinations.length} vacunaciones',
              ),
              _MiniChip(icon: Icons.pets, label: '$dogs perros'),
              _MiniChip(
                icon: Icons.cruelty_free_outlined,
                label: '$cats gatos',
              ),
              _MiniChip(
                icon: Icons.people_alt_outlined,
                label: '${sector.assignedVaccinatorIds.length} vacunadores',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  final List<Widget> children;

  const _MetricsGrid({
    required this.isMobile,
    required this.isTablet,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isMobile ? 12 : 16,
      mainAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: isMobile
          ? 0.95
          : isTablet
          ? 1.15
          : 1.2,
      children: children,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: VetTheme.textLight,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: GlassCard(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        child: Column(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: VetTheme.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: VetTheme.primary, size: 25),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: VetTheme.textDark,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: VetTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: VetTheme.primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: VetTheme.primary, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: VetTheme.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
