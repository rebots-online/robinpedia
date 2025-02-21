import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class StorageAccessManager {
  static final StorageAccessManager _instance = StorageAccessManager._internal();
  factory StorageAccessManager() => _instance;
  StorageAccessManager._internal();

  static const platform = MethodChannel('world.robinsai.robinpedia/storage');

  /// Gets the appropriate storage directory for the current platform
  Future<String> getDownloadLocation() async {
    if (Platform.isAndroid) {
      return await _getAndroidDownloadLocation();
    } else if (Platform.isIOS) {
      return await _getIOSDownloadLocation();
    } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return await _getDesktopDownloadLocation();
    } else {
      // Web platform or unknown - use temporary directory
      final temp = await getTemporaryDirectory();
      return temp.path;
    }
  }

  Future<String> _getAndroidDownloadLocation() async {
    if (await _checkAndroidVersion() >= 30) {
      // Android 11+ uses SAF
      final granted = await _requestSafAccess();
      if (!granted) {
        throw Exception('Storage access denied');
      }
    } else {
      // Legacy storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }
    }
    
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<String> _getIOSDownloadLocation() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<String> _getDesktopDownloadLocation() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<int> _checkAndroidVersion() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  Future<bool> _requestSafAccess() async {
    try {
      final result = await platform.invokeMethod('requestSafAccess');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error requesting SAF access: $e');
      return false;
    }
  }

  /// Check if there's enough space available for a download
  Future<bool> checkSpaceAvailable(int requiredBytes) async {
    try {
      final downloadPath = await getDownloadLocation();
      final stat = Directory(downloadPath).statSync();
      final available = stat.size;
      return available >= requiredBytes;
    } catch (e) {
      print('Error checking space: $e');
      return false;
    }
  }
}
