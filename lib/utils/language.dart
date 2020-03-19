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
      'freeExpired': 'APP free using notice',
      'exit': 'Exit APP',
      'showAds': 'Show video ads (one more day free)',
      'videoFailHint': 'Please watch the video',
      'clickLogin': 'Click to login',
      'thirdPartyLogin': 'Third Party Login',
      'logined': 'Logined',
      'payAction': 'Free using forever ( 9.9 CNY )',
      'payHint': 'Wechat pay url has generated. Please share to wechat, and then pay in wechat.',
      'sharePayToWechat': 'Share Pay Url to Wechat and Pay',
      'payUrl': 'ScratchPaper Wechat Pay URL',
      'thankForPay': 'Thank you for support ScratchPaper',
      'paidLogin': 'I am paid user. Go login',
      'showUserNotice': 'Click to show user notice',
      'agree': 'Agree',
      'readed': 'Readed',
      'inviteFriend': 'Invite Wechat Friend',
      'shareTitle': 'Scratch Paper',
      'shareDescription': 'Scratch paper new choose. Protect our environment',
      'wechatNotFound': 'Wechat not found',
      'wechatFriend': 'Wechat Friend',
      'wechatTimeline': 'Wechat Timeline',
      'shareTo': 'Share to',
      'pickFrom': 'Pick From',
      'gallery': 'Gallery',
      'camera': 'Camera',
      'importImageEdit': 'Import Image Edit',
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
      'inputTextHint': '请输入内容',
      'thankFeedback': '感谢您的反馈',
      'freeExpired': 'APP免费使用须知',
      'exit': '退出APP',
      'showAds': '观看视频广告（免费再用1天）',
      'videoFailHint': '请看完视频广告',
      'clickLogin': '点击登录',
      'thirdPartyLogin': '第三方登录',
      'logined': '已登录',
      'payAction': '永久免费使用（9.9元）',
      'payHint': '微信的支付链接已经生成。请分享链接到微信，然后在微信中支付。',
      'sharePayToWechat': '分享支付链接到微信并支付',
      'payUrl': '草稿本微信支付链接',
      'thankForPay': '感谢您对草稿本的支持',
      'paidLogin': '我是已付费用户，登录',
      'showUserNotice': '点击查看隐私政策和用户协议',
      'agree': '同意',
      'readed': '已读',
      'inviteFriend': '邀请微信好友',
      'shareTitle': '草稿本',
      'shareDescription': '草稿本新选择，保护我们的环境',
      'wechatNotFound': '找不到微信',
      'wechatFriend': '微信好友',
      'wechatTimeline': '微信朋友圈',
      'shareTo': '分享到',
      'pickFrom': '导入自',
      'gallery': '相册',
      'camera': '相机',
      'importImageEdit': '导入图片编辑',
    }
  };

  String getLanguageText(String textID) {
    return _languageTextMap[locale.languageCode][textID];
  }

  bool isLangZh() {
    return locale.languageCode.contains('zh');
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