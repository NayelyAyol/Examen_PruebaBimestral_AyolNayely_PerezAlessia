import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/coordinator_model.dart';
import '../../models/sector_model.dart';
import '../../models/vaccination_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/vaccination_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';

class CampanaDashboard extends StatelessWidget {
  const CampanaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Campaña'),
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
      drawer: Drawer(
        child: Container(
          decoration: VetTheme.backgroundGradient,
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: VetTheme.primary,
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                accountName: Text(
                  user?.name ?? 'Coordinador de Campaña',
                  style: const TextStyle(
                    color: VetTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? 'campana@vet.com',
                  style: const TextStyle(color: VetTheme.textLight),
                ),
              ),
              const Divider(color: VetTheme.glassBorder),
              ListTile(
                leading: const Icon(
                  Icons.dashboard_outlined,
                  color: VetTheme.primary,
                ),
                title: const Text('Inicio'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.map_outlined,
                  color: VetTheme.primary,
                ),
                title: const Text('Gestionar Sectores'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/sectors');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.people_alt_outlined,
                  color: VetTheme.primary,
                ),
                title: const Text('Gestionar Coordinadores'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/coordinators');
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: VetTheme.accent),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: VetTheme.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: StreamBuilder<List<SectorModel>>(
          stream: firestoreService.getSectorsStream(),
          builder: (context, sectorsSnapshot) {
            return StreamBuilder<List<CoordinatorModel>>(
              stream: firestoreService.getCoordinatorsStream(),
              builder: (context, coordinatorsSnapshot) {
                return StreamBuilder<List<VaccinationModel>>(
                  stream: Provider.of<VaccinationService>(context).getVaccinations(),
                  builder: (context, vaccinationsSnapshot) {
                    final sectors = sectorsSnapshot.data ?? [];
                    final coordinators = coordinatorsSnapshot.data ?? [];
                    final vaccinations = vaccinationsSnapshot.data ?? [];

                    // Sincronización pendientes
                    final pendingSectors = sectors.where((s) => s.isPendingSync).length;
                    final pendingCoordinators = coordinators.where((c) => c.isPendingSync).length;
                    final pendingVaccinations = vaccinations.where((v) => v.isPendingSync).length;
                    final pendingSyncCount = pendingSectors + pendingCoordinators + pendingVaccinations;

                    // Filtrar métricas principales solo para sincronizados
                    final syncedSectors = sectors.where((s) => !s.isPendingSync).toList();
                    final syncedCoordinators = coordinators.where((c) => !c.isPendingSync).toList();

                    final totalSectors = syncedSectors.length;
                    final activeCoordinators =
                        syncedCoordinators.where((c) => c.status == 'Activo').length;
                    final assignedSectors = syncedSectors
                        .where(
                          (s) =>
                              s.assignedCoordinatorId != null &&
                              s.assignedCoordinatorId!.isNotEmpty,
                        )
                        .length;
                    final unassignedSectors = totalSectors - assignedSectors;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        final isTablet = constraints.maxWidth >= 600 &&
                            constraints.maxWidth < 950;

                        final horizontalPadding = isMobile ? 14.0 : 24.0;
                        final maxContentWidth =
                            constraints.maxWidth > 1000 ? 1000.0 : double.infinity;

                        return SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 18,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxContentWidth,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GlassCard(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: isMobile ? 46 : 58,
                                          height: isMobile ? 46 : 58,
                                          decoration: BoxDecoration(
                                            color:
                                                VetTheme.primary.withOpacity(0.08),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: VetTheme.primary
                                                  .withOpacity(0.12),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.waving_hand_outlined,
                                            color: VetTheme.primary,
                                            size: isMobile ? 26 : 32,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '¡Hola, ${user?.name.split(" ").first ?? "Doctor"}!',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: VetTheme.textDark,
                                                  fontSize: isMobile ? 21 : 26,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Resumen general de la campaña de vacunación.',
                                                style: TextStyle(
                                                  color: VetTheme.textLight,
                                                  fontSize: 14,
                                                  height: 1.3,
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

                                  _MetricsGrid(
                                    isMobile: isMobile,
                                    isTablet: isTablet,
                                    children: [
                                      _MetricCard(
                                        title: 'Sectores',
                                        value: totalSectors.toString(),
                                        icon: Icons.map_outlined,
                                        color: VetTheme.primary,
                                      ),
                                      _MetricCard(
                                        title: 'Brigadas',
                                        value: activeCoordinators.toString(),
                                        icon: Icons.groups_2_outlined,
                                        color: Colors.blueAccent,
                                      ),
                                      _MetricCard(
                                        title: 'Asignados',
                                        value: assignedSectors.toString(),
                                        icon: Icons.assignment_ind_outlined,
                                        color: Colors.green,
                                      ),
                                      _MetricCard(
                                        title: 'Sin Coord.',
                                        value: unassignedSectors.toString(),
                                        icon: Icons.person_off_outlined,
                                        color: VetTheme.accent,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 26),

                                  const Text(
                                    'Accesos Rápidos',
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
                                          title: 'CRUD Sectores',
                                          icon: Icons.edit_road,
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            '/sectors',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _QuickAction(
                                          title: 'Coordinadores',
                                          icon: Icons.person_add_alt_1,
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            '/coordinators',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 26),

                                  const Text(
                                    'Monitoreo de Sectores',
                                    style: TextStyle(
                                      color: VetTheme.textDark,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  if (sectors.isEmpty)
                                    const GlassCard(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(24),
                                      child: Center(
                                        child: Text(
                                          'No hay sectores registrados.',
                                          style: TextStyle(color: VetTheme.textLight),
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: sectors.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 14),
                                      itemBuilder: (context, index) {
                                        final sector = sectors[index];
                                        final hasCoord =
                                            sector.assignedCoordinatorId != null &&
                                                sector
                                                    .assignedCoordinatorId!.isNotEmpty;

                                        return GlassCard(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                color: hasCoord
                                                    ? Colors.green
                                                    : VetTheme.accent,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      sector.name,
                                                      style: const TextStyle(
                                                        color: VetTheme.textDark,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      hasCoord
                                                          ? 'Brigadista: ${sector.assignedCoordinatorName}'
                                                          : 'Sin coordinador asignado',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: VetTheme.textLight,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
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
        padding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 10,
        ),
        child: Column(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: VetTheme.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: VetTheme.primary,
                size: 25,
              ),
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