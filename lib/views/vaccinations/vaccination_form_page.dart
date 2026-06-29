import 'dart:io'; // Fundamental para el manejo de File local

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/vaccination_model.dart';
import '../../services/vaccination_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';

class VaccinationFormPage extends StatefulWidget {
  final VaccinationModel? vaccinationToEdit;

  const VaccinationFormPage({Key? key, this.vaccinationToEdit}) : super(key: key);

  @override
  _VaccinationFormPageState createState() => _VaccinationFormPageState();
}

class _VaccinationFormPageState extends State<VaccinationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final VaccinationService _vaccinationService = VaccinationService();
  final ImagePicker _picker = ImagePicker();

  final _ownerNameCtrl = TextEditingController();
  final _ownerIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _petNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _vaccineCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  String _petType = 'Perro';
  String _petGender = 'Macho';
  String? _localImagePath; // Guarda el path local del dispositivo (ej. '/storage/emulated/0/...')
  double _latitude = 0.0;
  double _longitude = 0.0;
  
  bool _isLoading = false;
  bool _isGettingLocation = false;

  bool get isEditing => widget.vaccinationToEdit != null;

  @override
  void initState() {
    super.initState();
    
    if (isEditing) {
      final vac = widget.vaccinationToEdit!;
      _ownerNameCtrl.text = vac.nombrePropietario;
      _ownerIdCtrl.text = vac.cedulaPropietario;
      _phoneCtrl.text = vac.telefono;
      _petNameCtrl.text = vac.nombreMascota;
      _ageCtrl.text = vac.edadAproximada;
      _vaccineCtrl.text = vac.vacunaAplicada;
      _obsCtrl.text = vac.observaciones;
      _petType = vac.tipoMascota;
      _petGender = vac.sexo;
      _localImagePath = vac.fotografia;
      _latitude = vac.latitud;
      _longitude = vac.longitud;
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _ownerIdCtrl.dispose();
    _phoneCtrl.dispose();
    _petNameCtrl.dispose();
    _ageCtrl.dispose();
    _vaccineCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      debugPrint('Error GPS: $e');
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _openGoogleMaps() async {
    if (_latitude == 0 || _longitude == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero captura la ubicación GPS'), backgroundColor: VetTheme.accent),
      );
      return;
    }
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps'), backgroundColor: VetTheme.accent),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: VetTheme.primary),
                title: const Text('Tomar Foto con Cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: VetTheme.primary),
                title: const Text('Escoger de la Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 75);
      if (image == null) return;
      setState(() {
        _localImagePath = image.path; // Almacenamos la ruta interna local
      });
    } catch (e) {
      debugPrint('Error al capturar imagen: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_localImagePath == null || _localImagePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, agregue la fotografía de evidencia.'), backgroundColor: VetTheme.accent),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final newVaccination = VaccinationModel(
        id: widget.vaccinationToEdit?.id ?? '',
        nombrePropietario: _ownerNameCtrl.text.trim(),
        cedulaPropietario: _ownerIdCtrl.text.trim(),
        telefono: _phoneCtrl.text.trim(),
        tipoMascota: _petType,
        nombreMascota: _petNameCtrl.text.trim(),
        edadAproximada: _ageCtrl.text.trim(),
        sexo: _petGender,
        vacunaAplicada: _vaccineCtrl.text.trim(),
        observaciones: _obsCtrl.text.trim(),
        fotografia: _localImagePath!, // Mandamos la ruta corta de texto a Firestore
        latitud: _latitude,
        longitud: _longitude,
        fechaHora: widget.vaccinationToEdit?.fechaHora ?? DateTime.now(),
      );

      if (isEditing) {
        await _vaccinationService.updateVaccination(newVaccination);
      } else {
        await _vaccinationService.saveVaccination(newVaccination);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e'), backgroundColor: VetTheme.accent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(labelText: labelText, prefixIcon: Icon(prefixIcon, color: VetTheme.primary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _latitude != 0 && _longitude != 0;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Vacunación' : 'Registrar Vacunación')),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Datos del propietario', style: TextStyle(color: VetTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _ownerNameCtrl,
                    labelText: 'Nombre del Propietario',
                    prefixIcon: Icons.person_outline,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'))],
                    validator: (v) => v!.trim().isEmpty ? 'El nombre es obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ownerIdCtrl,
                    labelText: 'Cédula del Propietario',
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    validator: (v) => v!.trim().length != 10 ? 'Cédula inválida (10 dígitos)' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneCtrl,
                    labelText: 'Teléfono',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    validator: (v) => v!.trim().length != 10 ? 'Teléfono inválido (10 dígitos)' : null,
                  ),
                  
                  const SizedBox(height: 26),
                  const Text('Datos de la mascota', style: TextStyle(color: VetTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _petType,
                    decoration: const InputDecoration(labelText: 'Tipo de Mascota', prefixIcon: Icon(Icons.pets, color: VetTheme.primary)),
                    items: const [DropdownMenuItem(value: 'Perro', child: Text('Perro')), DropdownMenuItem(value: 'Gato', child: Text('Gato'))],
                    onChanged: (val) => setState(() => _petType = val!),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _petNameCtrl,
                    labelText: 'Nombre de la Mascota',
                    prefixIcon: Icons.cruelty_free_outlined,
                    validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ageCtrl,
                    labelText: 'Edad Aproximada',
                    prefixIcon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                    validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _petGender,
                    decoration: const InputDecoration(labelText: 'Sexo', prefixIcon: Icon(Icons.transgender, color: VetTheme.primary)),
                    items: const [DropdownMenuItem(value: 'Macho', child: Text('Macho')), DropdownMenuItem(value: 'Hembra', child: Text('Hembra'))],
                    onChanged: (val) => setState(() => _petGender = val!),
                  ),
                  
                  const SizedBox(height: 26),
                  const Text('Datos de vacunación', style: TextStyle(color: VetTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _vaccineCtrl,
                    labelText: 'Vacuna Aplicada',
                    prefixIcon: Icons.vaccines_outlined,
                    validator: (v) => v!.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _obsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Observaciones', prefixIcon: Icon(Icons.notes_outlined, color: VetTheme.primary)),
                  ),
                  
                  const SizedBox(height: 26),
                  const Text('Evidencia y ubicación', style: TextStyle(color: VetTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // Renderizado nativo local directo desde el File Path
                  Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.50), borderRadius: BorderRadius.circular(18), border: Border.all(color: VetTheme.primary.withOpacity(0.18))),
                    child: _localImagePath != null && _localImagePath!.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(File(_localImagePath!), fit: BoxFit.cover))
                        : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_outlined, color: VetTheme.primary, size: 42), SizedBox(height: 8), Text('No hay fotografía registrada', style: TextStyle(color: VetTheme.textLight))]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _showPhotoOptions, icon: const Icon(Icons.add_a_photo_outlined), label: Text(_localImagePath != null ? 'Cambiar fotografía' : 'Agregar fotografía'))),
                  
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(18), border: Border.all(color: hasLocation ? VetTheme.primary.withOpacity(0.30) : VetTheme.primary.withOpacity(0.15))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: VetTheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.location_on_outlined, color: VetTheme.primary, size: 22)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Ubicación GPS', style: TextStyle(color: VetTheme.textDark, fontWeight: FontWeight.bold, fontSize: 15)), Text(hasLocation ? 'Punto capturado correctamente' : 'No se ha capturado el GPS', style: const TextStyle(color: VetTheme.textLight, fontSize: 12))])),
                          ],
                        ),
                        if (hasLocation) ...[
                          const SizedBox(height: 12),
                          Text('Latitud: ${_latitude.toStringAsFixed(6)}\nLongitud: ${_longitude.toStringAsFixed(6)}', style: const TextStyle(color: VetTheme.textLight, fontSize: 13, height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _isGettingLocation ? null : _getCurrentLocation, icon: _isGettingLocation ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, size: 19), label: Text(_isGettingLocation ? 'Obteniendo ubicación...' : 'Recapturar GPS'))),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: hasLocation ? _openGoogleMaps : null, icon: const Icon(Icons.map_outlined, size: 19), label: const Text('Abrir en Google Maps'))),
                  
                  const SizedBox(height: 24),
                  CustomButton(text: isEditing ? 'Guardar Cambios' : 'Registrar Vacunación', isLoading: _isLoading, onPressed: _submitForm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}