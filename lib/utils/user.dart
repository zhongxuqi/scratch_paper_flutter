import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import './platform_custom.dart' as platform_custom;
import 'dart:convert';
import 'package:package_info/package_info.dart';

final FirstOpenKey = "first-open-key";
final FreeExiredTimeKey = "free-expired-time";
final BetaVersionKey = "beta-version";

final UserTypeKey = 'user-type';
final UserExpiredTimeKey = 'user-expired-time';
final UserIDKey = 'user-id';
final UserNameKey = 'user-name';
final UserAvatarKey = 'user-avatar';

setFirstOpenKey() async {
  var sharedPreference = await SharedPreferences.getInstance();
  sharedPreference.setInt(FirstOpenKey, 1);
}

getFirstOpenKey() async {
  var sharedPreference = await SharedPreferences.getInstance();
  return sharedPreference.getInt(FirstOpenKey);
}

setBetaVersion(int v) async {
  var sharedPreference = await SharedPreferences.getInstance();
  sharedPreference.setInt(BetaVersionKey, v);
}

Future<int> getBetaVersion() async {
  var sharedPreference = await SharedPreferences.getInstance();
  var ret = sharedPreference.getInt(BetaVersionKey);
  return ret==null?0:ret;
}

//Future getFreeExpiredTime() async {
////  var sharedPreference = await SharedPreferences.getInstance();
////  return sharedPreference.getInt(FreeExiredTimeKey);
////}

Future<bool> isFreeExpired() async {
  var currTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  var sharedPreference = await SharedPreferences.getInstance();
  var freeExpiredTs = sharedPreference.getInt(FreeExiredTimeKey);
  if (freeExpiredTs == null) {
    var packageInfo = await PackageInfo.fromPlatform();
    var buildVersion = int.parse(packageInfo.buildNumber);
    var betaVersion = await getBetaVersion();
    if (betaVersion > 0 && buildVersion < betaVersion) {
      return true;
    }
    return DateTime.parse("2020-10-16 00:00:00").millisecondsSinceEpoch ~/ 1000 < currTime;
  }
  return freeExpiredTs < currTime;
}

addFreeExpired(int day) async {
  var currTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  var sharedPreference = await SharedPreferences.getInstance();
  sharedPreference.setInt(FreeExiredTimeKey, currTime + day * 24 * 3600);
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
//  var currTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  var sharedPreference = await SharedPreferences.getInstance();
//  var expiredTime = await getUserExpiredTime();
//  if (currTime > expiredTime) {
//    await clearUserInfo();
//    return '';
//  }
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
//  var currTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  var sharedPreference = await SharedPreferences.getInstance();
//  var expiredTime = await getUserExpiredTime();
//  if (currTime > expiredTime) {
//    await clearUserInfo();
//    return '';
//  }
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

