import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:test_firebase/const.dart';
import 'package:test_firebase/firebase/index.dart';
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
    Reference storageRef = fbStorage
        .ref()
        .child('chat_media')
        .child(chatId)
        .child(senderId)
        .child(fname);

    //Note: getData() takes a max size limit. 10MB
    final Uint8List? bytes = await storageRef.getData(maxFileSize);

    return bytes!;
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String? fileUrl, // Pass the downloadUrl if it's an attachment
  }) async {
    try {
      // 1. Check if there is an attached file to delete
      if (fileUrl != null && fileUrl.isNotEmpty) {
        try {
          // Create a reference directly from the URL
          final storageRef = fbStorage.refFromURL(fileUrl);

          // Delete the file from the Firebase Storage bucket
          await storageRef.delete();
        } on FirebaseException catch (e) {
          // Crucial Guard: If the file is ALREADY deleted (or missing),
          // we don't want the whole function to crash. We still want to
          // delete the Firestore document so the user isn't stuck with a ghost message.
          if (e.code == 'object-not-found') {
            print(
              'File already missing from storage, proceeding to delete message doc.',
            );
          } else {
            // If it's a permission error or network issue, stop and throw.
            rethrow;
          }
        }
      }

      // 2. Delete the message document from Firestore
      // await FirestoreService().firestore
      //     .collection('chats')
      //     .doc(chatId)
      //     .collection('messages')
      //     .doc(messageId)
      //     .delete();

      await FirestoreService().firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'isDeleted': true,
            'text': 'Deleted',
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Failed to unsend message: $e');
      // Here you would use your SnackBar extension to tell the user it failed!
    }
  }
}
