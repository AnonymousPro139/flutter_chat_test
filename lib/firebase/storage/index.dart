import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
