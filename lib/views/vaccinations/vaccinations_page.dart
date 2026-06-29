import 'dart:convert';
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

  Widget _buildVaccinationCard(VaccinationModel vaccination) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vaccination.fotografia.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  base64Decode(vaccination.fotografia),
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
                    style: const TextStyle(color: VetTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(vaccination.tipoMascota),
                  backgroundColor: VetTheme.primary.withOpacity(0.12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Propietario: ${vaccination.nombrePropietario}', style: const TextStyle(color: VetTheme.textDark)),
            Text('Cédula: ${vaccination.cedulaPropietario}', style: const TextStyle(color: VetTheme.textLight)),
            Text('Teléfono: ${vaccination.telefono}', style: const TextStyle(color: VetTheme.textLight)),
            const SizedBox(height: 8),
            Text('Vacuna: ${vaccination.vacunaAplicada}', style: const TextStyle(color: VetTheme.primary, fontWeight: FontWeight.bold)),
            Text('GPS: ${vaccination.latitud}, ${vaccination.longitud}', style: const TextStyle(color: VetTheme.textLight, fontSize: 12)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VaccinationFormPage(vaccinationToEdit: vaccination),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vacunaciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VaccinationFormPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: StreamBuilder<List<VaccinationModel>>(
          stream: _vaccinationService.getVaccinations(), // Usa tu método en español
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: VetTheme.primary));
            }
            final vaccinations = snapshot.data ?? [];
            if (vaccinations.isEmpty) {
              return const Center(child: Text('No hay vacunaciones registradas'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: vaccinations.length,
              itemBuilder: (context, index) => _buildVaccinationCard(vaccinations[index]),
            );
          },
        ),
      ),
    );
  }
}