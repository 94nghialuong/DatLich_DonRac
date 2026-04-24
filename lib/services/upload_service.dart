import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class UploadService {
  final storage = FirebaseStorage.instance;

  Future<String> uploadImage(Uint8List bytes, String path) async {
    final ref = storage.ref().child(path);

    await ref.putData(bytes);

    return await ref.getDownloadURL();
  }
}
