import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import './platform_custom.dart' as platform_custom;

final FreeExiredTimeKey = "free-expired-time";
final DaySeconds = 24 * 3600;

final UserTypeKey = 'user-type';
final UserExpiredTimeKey = 'user-expired-time';
final UserIDKey = 'user-id';
final UserNameKey = 'user-name';
final UserAvatorKey = 'user-avator';

Future<bool> isFreeExpired() async {
  var currTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  var sharedPreference = await SharedPreferences.getInstance();
  var freeExpiredTs = sharedPreference.getInt(FreeExiredTimeKey);
  if (freeExpiredTs == null) {
    freeExpiredTs = currTime;
    sharedPreference.setInt(FreeExiredTimeKey, currTime);
  }
  return freeExpiredTs < currTime;
}

void addFreeExpired(int day) async {
  var currTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  var sharedPreference = await SharedPreferences.getInstance();
  sharedPreference.setInt(FreeExiredTimeKey, currTime + day * DaySeconds);
}

void loginQQ() async {
  platform_custom.loginQQ();
}

void loginWeibo() async {
  platform_custom.loginWeibo();
}