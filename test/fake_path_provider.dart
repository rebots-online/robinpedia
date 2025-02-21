import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mockito/mockito.dart';

class FakePathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final tempDir = await Directory.systemTemp.createTemp('app_documents_');
    return tempDir.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    final tempDir = await Directory.systemTemp.createTemp('app_temp_');
    return tempDir.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final tempDir = await Directory.systemTemp.createTemp('app_support_');
    return tempDir.path;
  }

  @override
  Future<String?> getLibraryPath() async {
    final tempDir = await Directory.systemTemp.createTemp('app_library_');
    return tempDir.path;
  }

  @override
  Future<String?> getApplicationCachePath() async {
    final tempDir = await Directory.systemTemp.createTemp('app_cache_');
    return tempDir.path;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    final tempDir = await Directory.systemTemp.createTemp('external_storage_');
    return tempDir.path;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    final tempDir = await Directory.systemTemp.createTemp('external_cache_');
    return [tempDir.path];
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp('external_storage_${type?.toString() ?? "default"}_');
    return [tempDir.path];
  }

  @override
  Future<String?> getDownloadsPath() async {
    final tempDir = await Directory.systemTemp.createTemp('downloads_');
    return tempDir.path;
  }
}
