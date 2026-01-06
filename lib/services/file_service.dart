import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:logger/logger.dart';

class FileService {
  final _logger = Logger();

  /// Save PDF file to device storage
  Future<String?> savePDF(Uint8List data, String filename) async {
    try {
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        _logger.e('Could not get download directory');
        return null;
      }

      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(data);

      _logger.i('PDF saved to: ${file.path}');
      return file.path;
    } catch (e) {
      _logger.e('Error saving PDF: $e');
      return null;
    }
  }

  /// Save CSV file to device storage
  Future<String?> saveCSV(String data, String filename) async {
    try {
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        _logger.e('Could not get download directory');
        return null;
      }

      final file = File('${directory.path}/$filename');
      await file.writeAsString(data);

      _logger.i('CSV saved to: ${file.path}');
      return file.path;
    } catch (e) {
      _logger.e('Error saving CSV: $e');
      return null;
    }
  }

  /// Get appropriate download directory based on platform
  Future<Directory?> _getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Use external storage on Android if available
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return externalDir;
        }
        // Fallback to app documents directory
        return await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS) {
        // Use documents directory on iOS
        return await getApplicationDocumentsDirectory();
      } else {
        // Desktop platforms
        return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      _logger.e('Error getting download directory: $e');
      return null;
    }
  }

  /// Share a file using the system share dialog
  Future<bool> shareFile(String filePath, {String? subject}) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles(
        [file],
        subject: subject,
      );
      return true;
    } catch (e) {
      _logger.e('Error sharing file: $e');
      return false;
    }
  }

  /// Save and share PDF file
  Future<Map<String, dynamic>> saveAndSharePDF(
    Uint8List data,
    String filename, {
    String? subject,
  }) async {
    try {
      final path = await savePDF(data, filename);
      if (path == null) {
        return {
          'success': false,
          'message': 'Failed to save PDF file',
        };
      }

      final shared = await shareFile(path, subject: subject);
      return {
        'success': shared,
        'path': path,
        'message': shared ? 'File shared successfully' : 'Failed to share file',
      };
    } catch (e) {
      _logger.e('Error saving and sharing PDF: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Save and share CSV file
  Future<Map<String, dynamic>> saveAndShareCSV(
    String data,
    String filename, {
    String? subject,
  }) async {
    try {
      final path = await saveCSV(data, filename);
      if (path == null) {
        return {
          'success': false,
          'message': 'Failed to save CSV file',
        };
      }

      final shared = await shareFile(path, subject: subject);
      return {
        'success': shared,
        'path': path,
        'message': shared ? 'File shared successfully' : 'Failed to share file',
      };
    } catch (e) {
      _logger.e('Error saving and sharing CSV: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Delete a file
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _logger.i('File deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Error deleting file: $e');
      return false;
    }
  }
}
