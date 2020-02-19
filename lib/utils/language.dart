import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static Map<String, Map<String, String>> _languageTextMap = {
    'en': {
      'edit': 'Edit',
      'move': 'Move & Scale',
      'eraser': 'Eraser',
      'graphics': 'Graphics',
      'import': 'Import',
      'export': 'Export',
      'noMoreUndo': 'No more undo',
      'noMoreRedo': 'No more redo',
      'backOrigin': 'Back origin',
      'clear': 'Clear all content',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'importWillClear': 'Import will clear all content',
      'shareWechat': 'Share to wechat',
      'cantShareEmpty': 'Can not share empty',
      'save2Gallery': 'Save to gallery',
      'saveSuccess': 'Saved success',
      'contentEmpty': 'Content empty',
      'exitAlert': 'Exit will lost all modify, are you sure ?',
      'text': 'Text',
      'inputHint': 'Input text',
      'crop': 'Crop',
      'feedback': 'Feedback',
      'inputTextHint': 'Please input text',
      'thankFeedback': 'Thank you for your feedback',
      'freeExpired': 'APP free time has expired',
      'exit': 'Exit APP',
      'showAds': 'See video ads for one day free',
      'videoFailHint': 'Please watch the video',
    },
    'zh': {
      'edit': '编辑',
      'move': '移动&缩放',
      'eraser': '橡皮擦',
      'graphics': '图形',
      'import': '导入',
      'export': '导出',
      'noMoreUndo': '没有更多可撤销',
      'noMoreRedo': '没有更多可重做',
      'backOrigin': '回到原点',
      'clear': '清空所有内容',
      'cancel': '取消',
      'confirm': '确认',
      'importWillClear': '导入会清空所有内容',
      'shareWechat': '分享到微信',
      'cantShareEmpty': '无法分享空内容',
      'save2Gallery': '保存到相册',
      'saveSuccess': '保存成功',
      'contentEmpty': '内容为空',
      'exitAlert': '退出会丢失目前所有的修改，是否确认？',
      'text': '文本',
      'inputHint': '输入文本',
      'crop': '裁剪',
      'feedback': '反馈',
      'inputTextHint': '请出入内容',
      'thankFeedback': '感谢您的反馈',
      'freeExpired': 'APP免费使用已到期',
      'exit': '退出APP',
      'showAds': '观看视频广告（免费再用1天）',
      'videoFailHint': '请看完视频广告',
    }
  };

  String getLanguageText(String textID) {
    return _languageTextMap[locale.languageCode][textID];
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations>{

  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en','zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}