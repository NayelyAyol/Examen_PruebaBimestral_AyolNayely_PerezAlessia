import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/vaccination_model.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/vaccination_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';

class VaccinationFormPage extends StatefulWidget {
  final VaccinationModel? vaccinationToEdit;
  final String? sectorId;
  final String? sectorNombre;

  const VaccinationFormPage({
    super.key,
    this.vaccinationToEdit,
    this.sectorId,
    this.sectorNombre,
  });

  @override
  State<VaccinationFormPage> createState() => _VaccinationFormPageState();
}

class _VaccinationFormPageState extends State<VaccinationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final VaccinationService _vaccinationService = VaccinationService();
  final StorageService _storageService = StorageService();
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

  String? _photoUrl;
  Uint8List? _selectedImageBytes;

  double _latitude = 0.0;
  double _longitude = 0.0;

  bool _isLoading = false;
  bool _isGettingLocation = false;

  bool get isEditing => widget.vaccinationToEdit != null;

  String get _currentSectorId {
    return widget.vaccinationToEdit?.sectorId ?? widget.sectorId ?? '';
  }

  String get _currentSectorNombre {
    return widget.vaccinationToEdit?.sectorNombre ?? widget.sectorNombre ?? '';
  }

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

      _photoUrl = vac.fotografia;
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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showSnack('Activa el GPS del dispositivo.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showSnack('Permiso de ubicación denegado.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack('El permiso de ubicación fue denegado permanentemente.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      _showSnack('Error al obtener GPS: $e');
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _openGoogleMaps() async {
    if (_latitude == 0 || _longitude == 0) {
      _showSnack('Primero captura la ubicación GPS.');
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude',
    );

    final opened = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      _showSnack('No se pudo abrir Google Maps.');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: VetTheme.primary,
                  ),
                  title: const Text('Tomar foto con cámara'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: VetTheme.primary,
                  ),
                  title: const Text('Escoger de galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 65,
        maxWidth: 900,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _selectedImageBytes = bytes;
      });
    } catch (e) {
      _showSnack('Error al seleccionar imagen: $e');
    }
  }

  Future<String> _savePhotoLocally() async {
    if (_selectedImageBytes == null) {
      return _photoUrl ?? '';
    }

    final cedula = _ownerIdCtrl.text.trim().isEmpty
        ? 'sin_cedula'
        : _ownerIdCtrl.text.trim();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeFileName = 'foto_$timestamp.jpg';

    final appDirectory = await getApplicationDocumentsDirectory();

    final vaccinationDirectory = Directory(
      '${appDirectory.path}/vacunaciones/${_currentSectorId.isEmpty ? "sin_sector" : _currentSectorId}/$cedula',
    );

    if (!await vaccinationDirectory.exists()) {
      await vaccinationDirectory.create(recursive: true);
    }

    final file = File('${vaccinationDirectory.path}/$safeFileName');

    await file.writeAsBytes(_selectedImageBytes!);

    return file.path;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentSectorId.isEmpty || _currentSectorNombre.isEmpty) {
      _showSnack('No se pudo identificar el sector de vacunación.');
      return;
    }

    final hasExistingPhoto = _photoUrl != null && _photoUrl!.isNotEmpty;
    final hasNewPhoto = _selectedImageBytes != null;

    if (!hasExistingPhoto && !hasNewPhoto) {
      _showSnack('Agrega una fotografía de evidencia.');
      return;
    }

    if (_latitude == 0 || _longitude == 0) {
      _showSnack('Captura la ubicación GPS.');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    setState(() => _isLoading = true);

    try {
      final localPhotoPath = await _savePhotoLocally();
      String finalPhotoPath = localPhotoPath;

      if (authService.isFirebaseInitialized && _selectedImageBytes != null) {
        try {
          finalPhotoPath = await _storageService.uploadVaccinationPhoto(File(localPhotoPath));
        } catch (storageError) {
          debugPrint("Error al subir a Firebase Storage, usando path local: $storageError");
          finalPhotoPath = localPhotoPath;
        }
      }

      final vaccination = VaccinationModel(
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
        fotografia: finalPhotoPath,
        latitud: _latitude,
        longitud: _longitude,
        fechaHora: widget.vaccinationToEdit?.fechaHora ?? DateTime.now(),
        vacunadorId: widget.vaccinationToEdit?.vacunadorId ?? user?.uid ?? '',
        vacunadorNombre:
            widget.vaccinationToEdit?.vacunadorNombre ?? user?.name ?? '',
        sectorId: _currentSectorId,
        sectorNombre: _currentSectorNombre,
      );

      if (isEditing) {
        await _vaccinationService.updateVaccination(vaccination);
      } else {
        await _vaccinationService.saveVaccination(vaccination);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Error al guardar vacunación: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: VetTheme.accent,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: VetTheme.primary),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      final file = File(_photoUrl!);

      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) {
            return const Center(
              child: Text(
                'No se pudo cargar la imagen',
                style: TextStyle(color: VetTheme.textLight),
              ),
            );
          },
        );
      }

      return const Center(
        child: Text(
          'Imagen no encontrada en este dispositivo',
          style: TextStyle(color: VetTheme.textLight),
        ),
      );
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          color: VetTheme.primary,
          size: 42,
        ),
        SizedBox(height: 8),
        Text(
          'No hay fotografía registrada',
          style: TextStyle(color: VetTheme.textLight),
        ),
      ],
    );
  }

  Widget _buildSectorInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VetTheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: VetTheme.primary.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_city_outlined,
            color: VetTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentSectorNombre.isEmpty
                  ? 'Sector no identificado'
                  : 'Sector: $_currentSectorNombre',
              style: const TextStyle(
                color: VetTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _latitude != 0 && _longitude != 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Vacunación' : 'Registrar Vacunación',
        ),
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectorInfo(),
                  const SizedBox(height: 24),
                  const Text(
                    'Datos del propietario',
                    style: TextStyle(
                      color: VetTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _ownerNameCtrl,
                    labelText: 'Nombre del propietario',
                    prefixIcon: Icons.person_outline,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                      ),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$')
                          .hasMatch(v.trim())) {
                        return 'Solo se permiten letras';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ownerIdCtrl,
                    labelText: 'Cédula del propietario',
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'La cédula es obligatoria';
                      }
                      if (v.trim().length != 10) {
                        return 'La cédula debe tener 10 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneCtrl,
                    labelText: 'Teléfono',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El teléfono es obligatorio';
                      }
                      if (v.trim().length != 10) {
                        return 'El teléfono debe tener 10 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Datos de la mascota',
                    style: TextStyle(
                      color: VetTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _petType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de mascota',
                      prefixIcon: Icon(Icons.pets, color: VetTheme.primary),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Perro', child: Text('Perro')),
                      DropdownMenuItem(value: 'Gato', child: Text('Gato')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _petType = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _petNameCtrl,
                    labelText: 'Nombre de la mascota',
                    prefixIcon: Icons.cruelty_free_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                      ),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El nombre de la mascota es obligatorio';
                      }
                      if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$')
                          .hasMatch(v.trim())) {
                        return 'Solo se permiten letras';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ageCtrl,
                    labelText: 'Edad aproximada',
                    prefixIcon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'La edad es obligatoria';
                      }
                      final age = int.tryParse(v.trim());
                      if (age == null || age <= 0) {
                        return 'Edad inválida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _petGender,
                    decoration: const InputDecoration(
                      labelText: 'Sexo',
                      prefixIcon:
                          Icon(Icons.transgender, color: VetTheme.primary),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                      DropdownMenuItem(value: 'Hembra', child: Text('Hembra')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _petGender = value);
                    },
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Datos de vacunación',
                    style: TextStyle(
                      color: VetTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _vaccineCtrl,
                    labelText: 'Vacuna aplicada',
                    prefixIcon: Icons.vaccines_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s\-]'),
                      ),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'La vacuna es obligatoria';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _obsCtrl,
                    maxLines: 2,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s.,\-]'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      prefixIcon:
                          Icon(Icons.notes_outlined, color: VetTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Evidencia y ubicación',
                    style: TextStyle(
                      color: VetTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.50),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: VetTheme.primary.withOpacity(0.18),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildPhotoPreview(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showPhotoOptions,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(
                        _selectedImageBytes != null ||
                                (_photoUrl != null && _photoUrl!.isNotEmpty)
                            ? 'Cambiar fotografía'
                            : 'Agregar fotografía',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: hasLocation
                            ? VetTheme.primary.withOpacity(0.30)
                            : VetTheme.primary.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      hasLocation
                          ? 'Ubicación GPS capturada\nLatitud: ${_latitude.toStringAsFixed(6)}\nLongitud: ${_longitude.toStringAsFixed(6)}'
                          : 'No se ha capturado el GPS',
                      style: const TextStyle(
                        color: VetTheme.textLight,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 19),
                      label: Text(
                        _isGettingLocation
                            ? 'Obteniendo ubicación...'
                            : 'Capturar GPS',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: hasLocation ? _openGoogleMaps : null,
                      icon: const Icon(Icons.map_outlined, size: 19),
                      label: const Text('Abrir en Google Maps'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text:
                        isEditing ? 'Guardar Cambios' : 'Registrar Vacunación',
                    isLoading: _isLoading,
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}