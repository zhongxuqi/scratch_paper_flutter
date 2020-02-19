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