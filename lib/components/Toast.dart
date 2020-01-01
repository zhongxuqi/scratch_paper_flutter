import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showErrorToast(String errMsg) {
  Fluttertoast.showToast(
    msg: errMsg,
    toastLength: Toast.LENGTH_SHORT,
    backgroundColor: const Color(0xfff44336),
    textColor: Colors.white,
    gravity: ToastGravity.CENTER,
  );
}

void showSuccessToast(String msg) {
  Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_SHORT,
    backgroundColor: const Color(0xff4caf50),
    textColor: Colors.white,
    gravity: ToastGravity.CENTER,
  );
}