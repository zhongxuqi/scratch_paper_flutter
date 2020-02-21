import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../common/consts.dart' as consts;

var url = "https://www.easypass.tech";

Future<http.Response> feedback(String message) async {
  return http.post(url + '/openapi/codeutils', headers: {
    'Content-Type': 'application/json',
  }, body: json.encode({
    'app_id': consts.AppID,
    'type': 1,
    'message': message,
  })).timeout(Duration(seconds: 5));
}

Future<http.Response> postAccount(String platformType, String account) async {
  return http.post(url + '/openapi/external_account', headers: {
    'Content-Type': 'application/json',
  }, body: json.encode({
    'app_id': consts.AppID,
    'platform_type': platformType,
    'account': account,
  })).timeout(Duration(seconds: 5));
}

Future<http.Response> getAppVersion() async {
  return http.get(url + '/openapi/app_version').timeout(Duration(seconds: 2));
}