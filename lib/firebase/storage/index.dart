import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:test_firebase/const.dart';
import 'package:test_firebase/localstorage/index.dart';

class FbStorage {
  final FirebaseStorage fbStorage = FirebaseStorage.instance;

  Future<String?> uploadFile() async {
    // 1. Pick the file
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}";

      try {
        // 2. Create a reference to the location in Firebase Storage
        Reference storageRef = fbStorage.ref('uploads/$fileName');

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
      String extension = LocalStorageService().getExtension(path);
      String fileName =
          'chat_${chatId}_${DateTime.now().millisecondsSinceEpoch}.${extension}';

      // 3. Create the Firebase Storage reference
      // We store it in a subfolder named after the chatId to keep things organized
      Reference storageRef = fbStorage
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

  Future<String> uploadImage2(
    String chatId,
    Uint8List encryptedBytes,
    String fname,
  ) async {
    try {
      // 3. Create the Firebase Storage reference
      // We store it in a subfolder named after the chatId to keep things organized
      Reference storageRef = fbStorage
          .ref()
          .child('chat_media')
          .child(chatId)
          .child(fname);

      // Use putData instead of putFile
      final uploadTask = await storageRef.putData(encryptedBytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      // 7. Handle any errors (connection issues, permission denied, etc.)
      debugPrint('Upload failed: $e');
      return "";
      // Optional: Show a SnackBar to the user here
    }
  }

  Future<String> uploadImage3({
    required String chatId,
    required String senderId,
    required Uint8List encryptedBytes,
    required String fname,
  }) async {
    try {
      // 3. Create the Firebase Storage reference
      // We store it in a subfolder named after the chatId to keep things organized
      Reference storageRef = fbStorage
          .ref()
          .child('chat_media')
          .child(chatId)
          .child(senderId)
          .child(fname);

      // Use putData instead of putFile
      final uploadTask = await storageRef.putData(encryptedBytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      // 7. Handle any errors (connection issues, permission denied, etc.)
      debugPrint('Upload failed: $e');
      return "";
      // Optional: Show a SnackBar to the user here
    }
  }

  Future<Uint8List> fetchEncryptedFileData({
    required String chatId,
    required String fname,
  }) async {
    Reference storageRef = FbStorage().fbStorage
        .ref()
        .child('chat_media')
        .child(chatId)
        .child(fname);

    //Note: getData() takes a max size limit. 10MB
    final Uint8List? bytes = await storageRef.getData(maxFileSize);

    return bytes!;
  }

  Future<Uint8List> fetchEncryptedFileData2({
    required String chatId,
    required String senderId,
    required String fname,
  }) async {
    Reference storageRef = FbStorage().fbStorage
        .ref()
        .child('chat_media')
        .child(chatId)
        .child(senderId)
        .child(fname);

    //Note: getData() takes a max size limit. 10MB
    final Uint8List? bytes = await storageRef.getData(maxFileSize);

    return bytes!;
  }
}
