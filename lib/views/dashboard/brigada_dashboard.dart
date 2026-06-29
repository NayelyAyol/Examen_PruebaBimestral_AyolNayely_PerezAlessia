import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sector_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';
import '../vaccinations/vaccinations_page.dart';

class BrigadaDashboard extends StatelessWidget {
  const BrigadaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
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
          builder: (context, snapshot) {
            final sectors = snapshot.data ?? [];

            final mySectors = sectors
                .where((s) => s.assignedCoordinatorId == user?.uid)
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: VetTheme.primary.withOpacity(0.2),
                          child: const Icon(
                            Icons.groups_2_outlined,
                            color: VetTheme.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenido, ${user?.name ?? "Coordinador"}',
                                style: const TextStyle(
                                  color: VetTheme.textDark,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Coordinador de Brigada',
                                style: TextStyle(
                                  color: VetTheme.textLight,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.vaccines_outlined,
                        color: VetTheme.primary,
                        size: 32,
                      ),
                      title: const Text(
                        'Gestionar Vacunadores',
                        style: TextStyle(
                          color: VetTheme.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Crear, editar y asignar vacunadores a sectores',
                        style: TextStyle(color: VetTheme.textLight),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: VetTheme.textLight,
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/vaccinators');
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.assignment_turned_in_outlined,
                        color: VetTheme.primary,
                        size: 32,
                      ),
                      title: const Text(
                        'Registros de Vacunación',
                        style: TextStyle(
                          color: VetTheme.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Consultar y corregir registros de tu sector',
                        style: TextStyle(color: VetTheme.textLight),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: VetTheme.textLight,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VaccinationsPage(
                              title: 'Registros de Vacunación',
                              canCreate: false,
                              canEdit: true,
                              onlyMine: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Mis Sectores Asignados',
                    style: TextStyle(
                      color: VetTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: VetTheme.primary,
                        ),
                      ),
                    )
                  else if (mySectors.isEmpty)
                    GlassCard(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_late_outlined,
                              size: 48,
                              color: VetTheme.textLight.withOpacity(0.5),
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
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final sector = mySectors[index];
                        return _buildSectorCard(sector);
                      },
                    ),

                  const SizedBox(height: 24),

                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: VetTheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Información del Rol',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: VetTheme.textDark,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Como Coordinador de Brigada, puedes ver tus sectores asignados, gestionar vacunadores y corregir registros de vacunación correspondientes a tu sector.',
                          style: TextStyle(
                            color: VetTheme.textLight.withOpacity(0.9),
                            fontSize: 13,
                            height: 1.4,
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
      ),
    );
  }

  Widget _buildSectorCard(SectorModel sector) {
    return GlassCard(
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
          const SizedBox(height: 8),
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
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}