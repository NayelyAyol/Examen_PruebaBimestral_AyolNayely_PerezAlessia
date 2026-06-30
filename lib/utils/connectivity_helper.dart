import 'dart:io';
import 'package:flutter/foundation.dart';

Future<bool> checkInternetConnection() async {
  if (kIsWeb) return true;
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
