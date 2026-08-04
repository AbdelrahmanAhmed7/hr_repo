import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Helper class for picking and saving profile images
class ProfileImagePicker {
  /// Pick an image from gallery or camera
  /// Returns the local file path if successful, null otherwise
  static Future<String?> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final selectedPath = result.files.single.path!;
        final selectedFile = File(selectedPath);

        // Check if file exists
        if (!await selectedFile.exists()) {
          return null;
        }

        // Copy image to app documents directory with a consistent name
        final appDir = await getApplicationDocumentsDirectory();
        final profileImagesDir = Directory('${appDir.path}/profile_images');
        
        // Create directory if it doesn't exist
        if (!await profileImagesDir.exists()) {
          await profileImagesDir.create(recursive: true);
        }

        // Use a consistent filename for profile image
        final savedImagePath = '${profileImagesDir.path}/profile_image.jpg';
        final savedFile = await selectedFile.copy(savedImagePath);

        return savedFile.path;
      }

      return null;
    } catch (e) {
      // Error picking image
      return null;
    }
  }

  /// Delete profile image from local storage
  static Future<void> deleteProfileImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Error deleting image - ignore
    }
  }
}

