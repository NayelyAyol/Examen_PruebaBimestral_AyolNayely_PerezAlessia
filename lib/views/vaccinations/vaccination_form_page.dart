import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/sector_model.dart';
import '../../models/vaccination_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../services/vaccination_service.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';

class VaccinationFormPage extends StatefulWidget {
  final VaccinationModel? vaccinationToEdit;

  const VaccinationFormPage({super.key, this.vaccinationToEdit});

  @override
  State<VaccinationFormPage> createState() => _VaccinationFormPageState();
}

class _VaccinationFormPageState extends State<VaccinationFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores del formulario
  late TextEditingController _ownerNameController;
  late TextEditingController _ownerCedulaController;
  late TextEditingController _ownerPhoneController;
  late TextEditingController _petNameController;
  late TextEditingController _petAgeController;
  late TextEditingController _vaccineNameController;
  late TextEditingController _observationsController;

  // Servicios que se usan en la pantalla
  final VaccinationService _vaccinationService = VaccinationService();
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  // Variables del formulario
  String _petType = 'Perro';
  String _petSex = 'Macho';
  String? _selectedSectorId;
  String? _selectedSectorName;

  // En móvil sí usamos File, porque Image.file funciona bien en Android
  File? _selectedImage;
  String _photoUrl = '';

  double _latitude = 0;
  double _longitude = 0;

  bool _isLoading = false;
  bool _isGettingLocation = false;

  bool get isEditing => widget.vaccinationToEdit != null;

  @override
  void initState() {
    super.initState();

    final vaccination = widget.vaccinationToEdit;

    _ownerNameController = TextEditingController(
      text: vaccination?.ownerName ?? '',
    );
    _ownerCedulaController = TextEditingController(
      text: vaccination?.ownerCedula ?? '',
    );
    _ownerPhoneController = TextEditingController(
      text: vaccination?.ownerPhone ?? '',
    );
    _petNameController = TextEditingController(
      text: vaccination?.petName ?? '',
    );
    _petAgeController = TextEditingController(text: vaccination?.petAge ?? '');
    _vaccineNameController = TextEditingController(
      text: vaccination?.vaccineName ?? '',
    );
    _observationsController = TextEditingController(
      text: vaccination?.observations ?? '',
    );

    // Si se edita un registro, cargamos los datos que ya existían
    if (vaccination != null) {
      _petType = vaccination.petType;
      _petSex = vaccination.petSex;
      _selectedSectorId = vaccination.sectorId;
      _selectedSectorName = vaccination.sectorName;
      _photoUrl = vaccination.photoUrl;
      _latitude = vaccination.latitude;
      _longitude = vaccination.longitude;
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerCedulaController.dispose();
    _ownerPhoneController.dispose();
    _petNameController.dispose();
    _petAgeController.dispose();
    _vaccineNameController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  // Muestra opciones para tomar foto o escoger desde galería
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Fotografía de evidencia',
                    style: TextStyle(
                      color: VetTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  const Text(
                    'Puedes tomar una foto o escoger una imagen del teléfono.',
                    style: TextStyle(
                      color: VetTheme.textLight,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _PhotoOptionTile(
                    icon: Icons.camera_alt_outlined,
                    title: 'Tomar foto',
                    subtitle: 'Abrir cámara del celular',
                    onTap: () {
                      Navigator.pop(context);
                      _pickPhoto(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 8),

                  _PhotoOptionTile(
                    icon: Icons.photo_library_outlined,
                    title: 'Escoger de galería',
                    subtitle: 'Seleccionar una foto existente',
                    onTap: () {
                      Navigator.pop(context);
                      _pickPhoto(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Selecciona foto desde cámara o galería
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1400,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo seleccionar la foto: $e'),
          backgroundColor: VetTheme.accent,
        ),
      );
    }
  }

  // Captura el GPS actual del celular
  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final position = await _locationService.getCurrentLocation();

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación GPS capturada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener GPS: $e'),
          backgroundColor: VetTheme.accent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  // Abre la ubicación exacta en Google Maps con latitud y longitud
  Future<void> _openGoogleMaps() async {
    if (_latitude == 0 || _longitude == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero captura la ubicación GPS'),
          backgroundColor: VetTheme.accent,
        ),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude',
    );

    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir Google Maps'),
          backgroundColor: VetTheme.accent,
        ),
      );
    }
  }

  // Guarda o actualiza la vacunación
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSectorId == null || _selectedSectorName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un sector'),
          backgroundColor: VetTheme.accent,
        ),
      );
      return;
    }

    if (_latitude == 0 || _longitude == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Captura la ubicación GPS'),
          backgroundColor: VetTheme.accent,
        ),
      );
      return;
    }

    if (!isEditing && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega una fotografía'),
          backgroundColor: VetTheme.accent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      String finalPhotoUrl = _photoUrl;

      if (_selectedImage != null) {
        try {
          finalPhotoUrl = await _storageService.uploadVaccinationPhoto(
            _selectedImage!,
          );
        } catch (e) {
          debugPrint('Error Storage: $e');

          // Continuar sin fotografía
          finalPhotoUrl = '';

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.orange,
                content: Text(
                  'No se pudo subir la fotografía.\nSe guardará el registro sin imagen.',
                ),
              ),
            );
          }
        }
      }

      final vaccination = VaccinationModel(
        id: widget.vaccinationToEdit?.id ?? '',
        ownerName: _ownerNameController.text.trim(),
        ownerCedula: _ownerCedulaController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        petType: _petType,
        petName: _petNameController.text.trim(),
        petAge: _petAgeController.text.trim(),
        petSex: _petSex,
        vaccineName: _vaccineNameController.text.trim(),
        observations: _observationsController.text.trim(),
        photoUrl: finalPhotoUrl,
        latitude: _latitude,
        longitude: _longitude,
        createdAt: widget.vaccinationToEdit?.createdAt ?? DateTime.now(),
        sectorId: _selectedSectorId!,
        sectorName: _selectedSectorName!,
        vaccinatorId: currentUser?.uid ?? '',
        vaccinatorName: currentUser?.name ?? 'Vacunador',
        isSynced: true,
      );

      if (isEditing) {
        await _vaccinationService.updateVaccination(vaccination);
      } else {
        await _vaccinationService.addVaccination(vaccination);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Vacunación actualizada correctamente'
                : 'Vacunación registrada correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar vacunación: $e'),
          backgroundColor: VetTheme.accent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Lista de sectores disponibles
  Widget _buildSectorDropdown(FirestoreService firestoreService) {
    return StreamBuilder<List<SectorModel>>(
      stream: firestoreService.getSectorsStream(),
      builder: (context, snapshot) {
        final sectors = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: VetTheme.primary),
          );
        }

        return DropdownButtonFormField<String>(
          value: _selectedSectorId,
          decoration: const InputDecoration(
            labelText: 'Sector',
            prefixIcon: Icon(Icons.map_outlined, color: VetTheme.primary),
          ),
          items: sectors.map((sector) {
            return DropdownMenuItem(value: sector.id, child: Text(sector.name));
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final sector = sectors.firstWhere((s) => s.id == value);
            setState(() {
              _selectedSectorId = sector.id;
              _selectedSectorName = sector.name;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Selecciona un sector';
            }
            return null;
          },
        );
      },
    );
  }

  // Vista previa de la fotografía
  Widget _buildPhotoPreview() {
    Widget content;

    if (_selectedImage != null) {
      content = Image.file(
        _selectedImage!,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (_photoUrl.isNotEmpty) {
      content = Image.network(
        _photoUrl,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      content = Container(
        height: 170,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.50),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VetTheme.primary.withOpacity(0.18)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: VetTheme.primary, size: 42),
            SizedBox(height: 8),
            Text(
              'No hay fotografía registrada',
              style: TextStyle(color: VetTheme.textLight),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(18), child: content),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showPhotoOptions,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(
              _selectedImage != null || _photoUrl.isNotEmpty
                  ? 'Cambiar fotografía'
                  : 'Agregar fotografía',
            ),
          ),
        ),
      ],
    );
  }

  // Botón para capturar ubicación GPS
  Widget _buildGpsButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isGettingLocation ? null : _getLocation,
        icon: _isGettingLocation
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: Text(
          _isGettingLocation ? 'Obteniendo ubicación...' : 'Capturar GPS',
        ),
      ),
    );
  }

  // Tarjeta de ubicación GPS
  // La dejé en columna para que no se aplaste en pantallas pequeñas.
  Widget _buildLocationCard() {
    final hasLocation = _latitude != 0 && _longitude != 0;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VetTheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: VetTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ubicación GPS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: VetTheme.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasLocation
                          ? 'Punto capturado correctamente'
                          : 'Todavía no se ha capturado la ubicación',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VetTheme.textLight,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              hasLocation
                  ? 'Latitud: ${_latitude.toStringAsFixed(6)}\nLongitud: ${_longitude.toStringAsFixed(6)}'
                  : 'Presiona el botón para capturar el GPS del celular.',
              style: const TextStyle(
                color: VetTheme.textLight,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Botones separados en columna para que no se dañen en móviles pequeños.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isGettingLocation ? null : _getLocation,
              icon: _isGettingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 19),
              label: Text(
                _isGettingLocation ? 'Obteniendo ubicación...' : 'Capturar GPS',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasLocation ? _openGoogleMaps : null,
              icon: const Icon(Icons.map_outlined, size: 19),
              label: const Text(
                'Abrir en Google Maps',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Validación sencilla: nombres solo letras y espacios
  String? _validateOnlyLetters(String? value, String message) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Campo obligatorio';
    }

    if (text.length < 2) {
      return '$message debe tener al menos 2 letras';
    }

    return null;
  }

  // Campo reutilizable para no repetir mucho código
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
      textCapitalization: TextCapitalization.words,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: VetTheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Vacunación' : 'Registrar Vacunación'),
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 780;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 820 : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isWide ? 32 : 20),
                  child: GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(title: 'Datos del propietario'),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _ownerNameController,
                            labelText: 'Nombre del propietario',
                            prefixIcon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                            inputFormatters: [
                              // Solo letras y espacios
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                              ),
                            ],
                            validator: (value) {
                              return _validateOnlyLetters(
                                value,
                                'El nombre del propietario',
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _ownerCedulaController,
                            labelText: 'Cédula del propietario',
                            prefixIcon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              // Solo números y máximo 10 dígitos
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'Campo obligatorio';
                              }

                              if (text.length != 10) {
                                return 'La cédula debe tener 10 dígitos';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _ownerPhoneController,
                            labelText: 'Teléfono',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              // Solo números y máximo 10 dígitos
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'Campo obligatorio';
                              }

                              if (text.length != 10) {
                                return 'El teléfono debe tener 10 dígitos';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 26),

                          const _SectionTitle(title: 'Datos de la mascota'),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _petType,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de mascota',
                              prefixIcon: Icon(
                                Icons.pets,
                                color: VetTheme.primary,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Perro',
                                child: Text('Perro'),
                              ),
                              DropdownMenuItem(
                                value: 'Gato',
                                child: Text('Gato'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _petType = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _petNameController,
                            labelText: 'Nombre de la mascota',
                            prefixIcon: Icons.cruelty_free_outlined,
                            keyboardType: TextInputType.name,
                            inputFormatters: [
                              // Solo letras y espacios
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                              ),
                            ],
                            validator: (value) {
                              return _validateOnlyLetters(
                                value,
                                'El nombre de la mascota',
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _petAgeController,
                            labelText: 'Edad aproximada',
                            prefixIcon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              // Solo números y máximo 2 dígitos
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'Campo obligatorio';
                              }

                              final age = int.tryParse(text);
                              if (age == null || age <= 0) {
                                return 'Edad no válida';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _petSex,
                            decoration: const InputDecoration(
                              labelText: 'Sexo',
                              prefixIcon: Icon(
                                Icons.transgender,
                                color: VetTheme.primary,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Macho',
                                child: Text('Macho'),
                              ),
                              DropdownMenuItem(
                                value: 'Hembra',
                                child: Text('Hembra'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _petSex = value);
                              }
                            },
                          ),
                          const SizedBox(height: 26),

                          const _SectionTitle(title: 'Datos de vacunación'),
                          const SizedBox(height: 16),
                          _buildSectorDropdown(firestoreService),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _vaccineNameController,
                            labelText: 'Vacuna aplicada',
                            prefixIcon: Icons.vaccines_outlined,
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              // Vacuna puede tener letras, números, espacios, punto, coma y guion
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s.,-]'),
                              ),
                              LengthLimitingTextInputFormatter(60),
                            ],
                            validator: (value) {
                              final text = value?.trim() ?? '';

                              if (text.isEmpty) {
                                return 'Campo obligatorio';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _observationsController,
                            maxLines: 3,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(250),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Observaciones',
                              prefixIcon: Icon(
                                Icons.notes_outlined,
                                color: VetTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),

                          const _SectionTitle(title: 'Evidencia y ubicación'),
                          const SizedBox(height: 16),
                          _buildPhotoPreview(),
                          const SizedBox(height: 16),
                          _buildLocationCard(),
                          const SizedBox(height: 28),

                          CustomButton(
                            text: isEditing
                                ? 'Guardar Cambios'
                                : 'Registrar Vacunación',
                            isLoading: _isLoading,
                            onPressed: _handleSave,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          color: VetTheme.textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PhotoOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VetTheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VetTheme.primary.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: VetTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: VetTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: VetTheme.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: VetTheme.textLight),
          ],
        ),
      ),
    );
  }
}
