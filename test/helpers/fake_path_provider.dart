import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:io';

class FakePathProvider
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getApplicationSupportPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getLibraryPath() async => null;

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => null;

  @override
  Future<String?> getDownloadsPath() async => null;

  @override
  Future<String?> getApplicationCachePath() async =>
      Directory.systemTemp.path;
}
