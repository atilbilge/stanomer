import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the [DocumentStorageService] instance.
final documentStorageServiceProvider = Provider<DocumentStorageService>((ref) {
  return DocumentStorageService();
});

/// Riverpod provider for managing the cloud upload permission state.
final cloudUploadAllowedProvider = StateNotifierProvider<CloudUploadAllowedNotifier, bool>((ref) {
  final service = ref.watch(documentStorageServiceProvider);
  return CloudUploadAllowedNotifier(service);
});

/// StateNotifier to handle loading and toggling of the cloud upload allowed preference.
class CloudUploadAllowedNotifier extends StateNotifier<bool> {
  final DocumentStorageService _service;

  CloudUploadAllowedNotifier(this._service) : super(kIsWeb) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    if (kIsWeb) {
      state = true;
      return;
    }
    state = await _service.getCloudUploadAllowed();
  }

  Future<void> toggle(bool allowed) async {
    if (kIsWeb) return;
    await _service.setCloudUploadAllowed(allowed);
    state = allowed;
  }
}

/// Custom exception representing errors during document saving operations.
class DocumentStorageException implements Exception {
  final String message;
  final dynamic details;

  DocumentStorageException(this.message, [this.details]);

  @override
  String toString() => 'DocumentStorageException: $message (${details ?? ''})';
}

/// Service class responsible for managing document storage preferences and
/// executing the save path (Local vs Cloud) based on the user's choice.
class DocumentStorageService {
  static const String _storagePrefKey = 'isCloudUploadAllowed';

  /// Saves the given file to the appropriate storage destination.
  /// Returns the path/URL of the saved document, or throws [DocumentStorageException].
  Future<String> saveDocument(File file) async {
    if (!await file.exists()) {
      throw DocumentStorageException('The source file does not exist.');
    }

    try {
      final isCloudAllowed = await getCloudUploadAllowed();

      if (isCloudAllowed) {
        return await _uploadToCloud(file);
      } else {
        return await _saveToLocalDirectory(file);
      }
    } on DocumentStorageException {
      rethrow;
    } catch (e) {
      throw DocumentStorageException('Unexpected error during document save: $e', e);
    }
  }

  /// Retrieves the persisted preference. Default is false (Privacy-First Approach).
  Future<bool> getCloudUploadAllowed() async {
    if (kIsWeb) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_storagePrefKey) ?? false;
    } catch (e) {
      // Return privacy-first default if SharedPreferences fails
      return false; 
    }
  }

  /// Persists the storage preference.
  Future<void> setCloudUploadAllowed(bool allowed) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storagePrefKey, allowed);
    } catch (e) {
      throw DocumentStorageException('Failed to persist preferences: $e', e);
    }
  }

  /// Saves the file locally to the application's document directory.
  Future<String> _saveToLocalDirectory(File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      
      // Store in a dedicated folder to keep the root documents directory clean
      final documentsDir = Directory('${appDir.path}/stored_documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      final fileName = path.basename(file.path);
      final destinationPath = '${documentsDir.path}/$fileName';

      // Perform the copy operation
      final savedFile = await file.copy(destinationPath);
      return savedFile.path;
    } catch (e) {
      throw DocumentStorageException('Failed to save document locally: $e', e);
    }
  }

  /// Mock implementation for uploading the file to a cloud API.
  Future<String> _uploadToCloud(File file) async {
    try {
      // Simulate network request latency
      await Future.delayed(const Duration(milliseconds: 1500));

      final fileName = path.basename(file.path);
      
      // Mock successful response containing the public resource URL
      return 'https://cloud-storage.stanomer.com/uploads/documents/$fileName';
    } catch (e) {
      throw DocumentStorageException('Failed to upload document to cloud: $e', e);
    }
  }
}
