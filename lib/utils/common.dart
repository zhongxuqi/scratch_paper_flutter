import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

Future<bool> checkPermission() async {
  if (Platform.isIOS) {
    return true;
  }
  var permissionKeys = [Permission.camera, Permission.storage];
  Map<Permission, PermissionStatus> permissions = await permissionKeys.request();
  for (var permissionKey in permissionKeys) {
    if (permissions[permissionKey] != PermissionStatus.granted) {
      return false;
    }
  }
  return true;
}