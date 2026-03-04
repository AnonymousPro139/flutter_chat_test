import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

Future<String?> uploadFile() async {
  // 1. Pick the file
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    File file = File(result.files.single.path!);
    String fileName =
        "${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}";

    try {
      // 2. Create a reference to the location in Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref('uploads/$fileName');

      // 3. Upload the file
      UploadTask uploadTask = storageRef.putFile(file);

      // (Optional) Monitor progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // 4. Wait for completion and get the URL
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl; // Use this to save in Firestore
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  } else {
    // User canceled the picker
    return null;
  }
}

Future<String> uploadImage(String chatId, String path) async {
  try {
    String extension = p.extension(path);
    String fileName =
        'chat_${chatId}_${DateTime.now().millisecondsSinceEpoch}.${extension}';

    // 3. Create the Firebase Storage reference
    // We store it in a subfolder named after the chatId to keep things organized
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_media')
        .child(chatId)
        .child(fileName);

    // 4. Upload the file to Storage
    // Note: We convert XFile to a standard dart:io File
    UploadTask uploadTask = storageRef.putFile(File(path));

    // Wait for the upload to complete and get the snapshot
    TaskSnapshot snapshot = await uploadTask;

    // 5. Retrieve the real download URL
    return await snapshot.ref.getDownloadURL();
  } catch (e) {
    // 7. Handle any errors (connection issues, permission denied, etc.)
    debugPrint('Upload failed: $e');
    return "";
    // Optional: Show a SnackBar to the user here
  }
}
