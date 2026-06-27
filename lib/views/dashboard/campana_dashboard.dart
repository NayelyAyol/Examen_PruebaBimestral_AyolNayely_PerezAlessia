import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/sector_model.dart';
import '../../models/coordinator_model.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';

class CampanaDashboard extends StatelessWidget {
  const CampanaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Campaña'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: VetTheme.textDark),
            tooltip: 'Cerrar Sesión',
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
              // Encabezado Drawer
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: VetTheme.primary,
                  child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                ),
                accountName: Text(
                  user?.name ?? 'Dr. Campaña',
                  style: const TextStyle(color: VetTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                accountEmail: Text(
                  user?.email ?? 'campana@vet.com',
                  style: const TextStyle(color: VetTheme.textLight, fontSize: 14),
                ),
              ),
              const Divider(color: VetTheme.glassBorder, thickness: 1),
              
              // Opciones
              ListTile(
                leading: const Icon(Icons.dashboard_outlined, color: VetTheme.primary),
                title: const Text('Inicio', style: TextStyle(color: VetTheme.textDark)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.map_outlined, color: VetTheme.primary),
                title: const Text('Gestionar Sectores', style: TextStyle(color: VetTheme.textDark)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/sectors');
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_alt_outlined, color: VetTheme.primary),
                title: const Text('Gestionar Coordinadores', style: TextStyle(color: VetTheme.textDark)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/coordinators');
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset_outlined, color: VetTheme.primary),
                title: const Text('Cambiar Contraseña', style: TextStyle(color: VetTheme.textDark)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/change_password');
                },
              ),
              const Spacer(),
              const Divider(color: VetTheme.glassBorder, thickness: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: VetTheme.accent),
                title: const Text('Cerrar Sesión', style: TextStyle(color: VetTheme.accent, fontWeight: FontWeight.bold)),
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
                // Métricas
                final sectors = sectorsSnapshot.data ?? [];
                final coordinators = coordinatorsSnapshot.data ?? [];
                
                final int totalSectors = sectors.length;
                final int activeCoordinators = coordinators.where((c) => c.status == 'Activo').length;
                final int completedSectors = sectors.where((s) => s.status == 'Completado').length;
                final double completedPercentage = totalSectors > 0 
                    ? (completedSectors / totalSectors) * 100 
                    : 0.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mensaje bienvenida
                      Row(
                        children: [
                          const Icon(Icons.waving_hand_outlined, color: VetTheme.primary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '¡Hola, ${user?.name.split(" ").first ?? "Doctor"}!',
                            style: const TextStyle(
                              color: VetTheme.textDark,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Resumen del estado de la campaña de vacunación.',
                        style: TextStyle(color: VetTheme.textLight, fontSize: 15),
                      ),
                      const SizedBox(height: 24),

                      // Tarjetas de Métricas en Fila / Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double cardWidth = (constraints.maxWidth - 16) / 2;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildMetricCard(
                                title: 'Sectores Totales',
                                value: totalSectors.toString(),
                                icon: Icons.map,
                                color: VetTheme.primary,
                                width: cardWidth,
                              ),
                              _buildMetricCard(
                                title: 'Brigadas Activas',
                                value: activeCoordinators.toString(),
                                icon: Icons.people,
                                color: Colors.blueAccent,
                                width: cardWidth,
                              ),
                              _buildMetricCard(
                                title: 'Completados',
                                value: '$completedSectors / $totalSectors',
                                subtitle: '${completedPercentage.toStringAsFixed(0)}% de avance',
                                icon: Icons.check_circle,
                                color: Colors.green,
                                width: cardWidth,
                              ),
                              _buildMetricCard(
                                title: 'Pendientes',
                                value: sectors.where((s) => s.status == 'Pendiente').length.toString(),
                                icon: Icons.pending_actions,
                                color: VetTheme.accent,
                                width: cardWidth,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // Accesos Directos
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
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, '/sectors'),
                              child: const GlassCard(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  children: [
                                    Icon(Icons.edit_road, color: VetTheme.primary, size: 32),
                                    SizedBox(height: 8),
                                    Text('CRUD Sectores', style: TextStyle(fontWeight: FontWeight.bold, color: VetTheme.textDark)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, '/coordinators'),
                              child: const GlassCard(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  children: [
                                    Icon(Icons.person_add_alt_1, color: VetTheme.primary, size: 32),
                                    SizedBox(height: 8),
                                    Text('Coordinadores', style: TextStyle(fontWeight: FontWeight.bold, color: VetTheme.textDark)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Lista de Sectores Recientes
                      const Text(
                        'Monitoreo de Sectores (Quito)',
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
                          child: Center(
                            child: Text('Cargando sectores...', style: TextStyle(color: VetTheme.textLight)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sectors.length > 5 ? 5 : sectors.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final sector = sectors[index];
                            Color statusColor = VetTheme.textLight;
                            IconData statusIcon = Icons.hourglass_empty;
                            if (sector.status == 'En Proceso') {
                              statusColor = Colors.orange;
                              statusIcon = Icons.cached;
                            } else if (sector.status == 'Completado') {
                              statusColor = Colors.green;
                              statusIcon = Icons.check_circle_outline;
                            }
                            return GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: VetTheme.primary.withOpacity(0.1),
                                    child: const Icon(Icons.pets, color: VetTheme.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sector.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: VetTheme.textDark, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Zona: ${sector.zone} | Asignado a: ${sector.assignedCoordinatorName ?? "Ninguno"}',
                                          style: const TextStyle(color: VetTheme.textLight, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    avatar: Icon(statusIcon, color: Colors.white, size: 16),
                                    label: Text(
                                      sector.status,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                    backgroundColor: statusColor,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return GlassCard(
      width: width,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: VetTheme.textLight, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: VetTheme.textDark, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
