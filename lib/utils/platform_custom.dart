import 'package:flutter/services.dart';

const platform = const MethodChannel('com.musketeer.scratchpaper');

Future<String> checkVideoAds() async {
  try {
    var result = await platform.invokeMethod('checkVideoAds', {});
    return result.toString();
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
}

Future<String> showVideoAds() async {
  try {
    await checkVideoAds();
    var result = await platform.invokeMethod('showVideoAds', {});
    return result.toString();
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
}

Future<String> loginQQ() async {
  try {
    var result = await platform.invokeMethod('loginQQ', {});
    return result.toString();
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
  return "";
}

Future<String> loginWeibo() async {
  try {
    var result = await platform.invokeMethod('loginWeibo', {});
    return result.toString();
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
  return "";
}

Future<int> getInstallTime() async {
  try {
    var result = await platform.invokeMethod('getInstallTime', {});
    return int.parse(result.toString());
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
  return 0;
}

Future<String> getAppChannel() async {
  try {
    var result = await platform.invokeMethod('getAppChannel', {});
    return result.toString();
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
  return "";
}