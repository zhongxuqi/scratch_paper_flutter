import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import './platform_custom.dart' as platform_custom;
import 'dart:convert';

final FreeExiredTimeKey = "free-expired-time";
final AppVersionKey = "app-version";
final DaySeconds = 24 * 3600;

final UserTypeKey = 'user-type';
final UserExpiredTimeKey = 'user-expired-time';
final UserIDKey = 'user-id';
final UserNameKey = 'user-name';
final UserAvatarKey = 'user-avatar';

setAppVersion(int v) async {
  var sharedPreference = await SharedPreferences.getInstance();
  sharedPreference.setInt(AppVersionKey, v);
}

Future<int> getAppVersion() async {
  var sharedPreference = await SharedPreferences.getInstance();
  var ret = sharedPreference.getInt(AppVersionKey);
  return ret==null?0:ret;
}

Future<bool> isFreeExpired() async {
  var currTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  var sharedPreference = await SharedPreferences.getInstance();
  var freeExpiredTs = sharedPreference.getInt(FreeExiredTimeKey);
  if (freeExpiredTs == null) {
    freeExpiredTs = await platform_custom.getInstallTime();
    freeExpiredTs = (freeExpiredTs ~/ 1000) + DaySeconds;
    if (freeExpiredTs > currTime + DaySeconds) {
      freeExpiredTs = currTime + DaySeconds;
    }
    sharedPreference.setInt(FreeExiredTimeKey, freeExpiredTs);
  }
  return freeExpiredTs < currTime;
}

addFreeExpired(int day) async {
  var currTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  var sharedPreference = await SharedPreferences.getInstance();
  sharedPreference.setInt(FreeExiredTimeKey, currTime + day * DaySeconds);
}

clearUserInfo() async {
  await setUserType('');
  await setUserID('');
}

setUserType(String t) async {
  var sharedPreference = await SharedPreferences.getInstance();
  sharedPreference.setString(UserTypeKey, t);
}

Future<String> getUserType() async {
  var currTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  var sharedPreference = await SharedPreferences.getInstance();
  var expiredTime = await getUserExpiredTime();
  if (currTime > expiredTime) {
    await clearUserInfo();
    return '';
  }
  var ret = sharedPreference.getString(UserTypeKey);
  return ret==null?'':ret;
}

setUserExpiredTime(int t) async {
  var sharedPreference = await SharedPreferences.getInstance();
  sharedPreference.setInt(UserExpiredTimeKey, t);
}

Future<int> getUserExpiredTime() async {
  var sharedPreference = await SharedPreferences.getInstance();
  var ret = sharedPreference.getInt(UserExpiredTimeKey);
  return ret==null?0:ret;
}

setUserID(String t) async {
  var sharedPreference = await SharedPreferences.getInstance();
  sharedPreference.setString(UserIDKey, t);
}

Future<String> getUserID() async {
  var currTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  var sharedPreference = await SharedPreferences.getInstance();
  var expiredTime = await getUserExpiredTime();
  if (currTime > expiredTime) {
    await clearUserInfo();
    return '';
  }
  var ret = sharedPreference.getString(UserIDKey);
  return ret==null?'':ret;
}

loginQQ() async {
  var result = await platform_custom.loginQQ();
  Map<String, dynamic> qqUserInfo = json.decode(result);
  await setUserType("qq");
  await setUserExpiredTime((qqUserInfo['expires_time'] as int) ~/ 1000);
  await setUserID(qqUserInfo['openid']);
}

loginWeibo() async {
  var result = await platform_custom.loginWeibo();
  Map<String, dynamic> qqUserInfo = json.decode(result);
  await setUserType("weibo");
  await setUserExpiredTime((qqUserInfo['expires_time'] as int) ~/ 1000);
  await setUserID(qqUserInfo['uid']);
}