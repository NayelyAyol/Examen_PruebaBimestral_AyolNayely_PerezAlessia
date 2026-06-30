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

class VaccinatorDashboard extends StatelessWidget {
  const VaccinatorDashboard({super.key});

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
        title: const Text('Panel de Vacunador'),
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
              stream: user == null
                  ? Stream.value([])
                  : vaccinationService.getVaccinationsByVaccinator(user.uid),
              builder: (context, vaccinationSnapshot) {
                final sectors = sectorSnapshot.data ?? [];
                final vaccinations = vaccinationSnapshot.data ?? [];

                final mySectors = sectors.where((sector) {
                  return sector.assignedVaccinatorIds.contains(user?.uid);
                }).toList();

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

                    return ListView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      children: [
                        GlassCard(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 16 : 20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: isMobile ? 24 : 28,
                                backgroundColor: VetTheme.primary.withOpacity(
                                  0.16,
                                ),
                                child: const Icon(
                                  Icons.pets,
                                  color: VetTheme.primary,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hola, ${user?.name.split(" ").first ?? "Vacunador"}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: VetTheme.textDark,
                                        fontSize: isMobile ? 20 : 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Resumen de tus sectores y vacunaciones.',
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
                                title: 'Sectores',
                                value: syncedSectors.length.toString(),
                                icon: Icons.map_outlined,
                                color: VetTheme.primary,
                              ),
                              _MetricCard(
                                title: 'Vacunaciones',
                                value: syncedVaccinations.length.toString(),
                                icon: Icons.assignment_turned_in_outlined,
                                color: Colors.green,
                              ),
                              _MetricCard(
                                title: 'Perros',
                                value: totalDogs.toString(),
                                icon: Icons.pets,
                                color: Colors.blueAccent,
                              ),
                              _MetricCard(
                                title: 'Gatos',
                                value: totalCats.toString(),
                                icon: Icons.cruelty_free_outlined,
                                color: VetTheme.accent,
                              ),
                            ],
                          ),

                        const SizedBox(height: 26),

                        const Text(
                          'Mis sectores',
                          style: TextStyle(
                            color: VetTheme.textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (mySectors.isEmpty)
                          const GlassCard(
                            width: double.infinity,
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No tienes sectores asignados.',
                                style: TextStyle(color: VetTheme.textLight),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: mySectors.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isMobile ? 2 : 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: isMobile ? 0.86 : 1.05,
                                ),
                            itemBuilder: (context, index) {
                              final sector = mySectors[index];

                              final count = myVaccinations.where((v) {
                                return v.sectorId == sector.id;
                              }).length;

                              return _SectorMiniCard(
                                sector: sector,
                                count: count,
                              );
                            },
                          ),

                        const SizedBox(height: 24),

                        GlassCard(
                          width: double.infinity,
                          child: Text(
                            'Como Vacunador, puedes ingresar únicamente a tus sectores asignados, registrar vacunaciones con fotografía y GPS, y editar solo tus propios registros.',
                            style: TextStyle(
                              color: VetTheme.textLight.withOpacity(0.9),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
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

class _SectorMiniCard extends StatelessWidget {
  final SectorModel sector;
  final int count;

  const _SectorMiniCard({required this.sector, required this.count});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VaccinationsPage(
              title: sector.name,
              canCreate: true,
              canEdit: true,
              onlyMine: true,
              sectorId: sector.id,
              sectorNombre: sector.name,
            ),
          ),
        );
      },
      child: GlassCard(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: VetTheme.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_city_outlined,
                color: VetTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              sector.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: VetTheme.textDark,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              sector.zone,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: VetTheme.textLight, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Text(
              '$count vacunas',
              style: const TextStyle(
                color: VetTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile
          ? 0.92
          : isTablet
          ? 1.08
          : 1.18,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 110,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: VetTheme.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
