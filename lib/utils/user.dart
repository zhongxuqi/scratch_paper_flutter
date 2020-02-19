import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

final FreeExiredTimeKey = "free-expired-time";
final DaySeconds = 24 * 3600;

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