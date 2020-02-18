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