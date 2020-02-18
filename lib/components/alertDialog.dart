import 'package:flutter/cupertino.dart';
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

void showFeedbackDialog(BuildContext context, {@required ValueChanged<String> callback}) {
  var textCtl = TextEditingController();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        titlePadding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        contentPadding: EdgeInsets.all(0),
        title: Text(
          AppLocalizations.of(context).getLanguageText('feedback'),
          style: TextStyle(
            fontSize: 18,
            color: Colors.green,
          ),
        ),
        content: Container(
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          child: CupertinoTextField(
            controller: textCtl,
            minLines: 2,
            maxLines: null,
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            placeholder: AppLocalizations.of(context).getLanguageText('inputTextHint'),
            style: TextStyle(
              fontSize: 15,
              color: Colors.green,
              textBaseline: TextBaseline.alphabetic,
            ),
          ),
        ),
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
                color: Colors.green,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              callback(textCtl.text);
            }
          ),
        ],
      );
    },
  );
}