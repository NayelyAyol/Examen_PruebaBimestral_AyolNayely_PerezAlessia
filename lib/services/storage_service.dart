import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Sube la foto de la vacunación a Firebase Storage
  Future<String> uploadVaccinationPhoto(File imageFile) async {
    final fileName = 'vaccination_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = _storage.ref().child('vaccinations/$fileName');

    await ref.putFile(imageFile);

    return await ref.getDownloadURL();
  }
}