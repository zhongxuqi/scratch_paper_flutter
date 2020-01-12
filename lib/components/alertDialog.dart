import 'package:flutter/material.dart';
import '../utils/language.dart';

void showAlertDialog(BuildContext context, String text, {@required VoidCallback callback}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text(text),
        actions: <Widget>[
          RawMaterialButton(
            child: Text(
              AppLocalizations.of(context).getLanguageText('cancel'),
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          RawMaterialButton(
              child: Text(
                AppLocalizations.of(context).getLanguageText('confirm'),
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                callback();
              }
          ),
        ],
      );
    },
  );
}