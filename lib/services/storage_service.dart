import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadVaccinationPhoto(File imageFile) async {
    final fileName = 'vaccination_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = _storage.ref().child('vaccinations').child(fileName);

    final bytes = await imageFile.readAsBytes();

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
    );

    await ref.putData(bytes, metadata);

    return await ref.getDownloadURL();
  }
}