import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart' as fluwx;
import '../utils/language.dart';
import 'package:flutter/services.dart';
import 'Toast.dart';

class ShareWechatDialog extends StatelessWidget {
  final String webPageUrl;

  ShareWechatDialog({Key key, @required this.webPageUrl}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 180.0,
      child: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.topLeft,
            child: Padding(
              child: Text(
                AppLocalizations.of(context).getLanguageText('shareTo'),
                style: TextStyle(fontSize:20, color: Colors.black54),
              ),
              padding: EdgeInsets.all(10),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(25.0, 25.0, 25.0, 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex:1,
                  child:GestureDetector(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset('images/social-wechat.png', height: 50.0, width: 50.0,),
                          Padding(
                            child:Text(
                              AppLocalizations.of(context).getLanguageText('wechatFriend'),
                              style: TextStyle(fontSize:12),
                            ),
                            padding:EdgeInsets.all(8),
                          ),
                        ],
                      ),
                      onTap: () {
                        _share(context, fluwx.WeChatScene.SESSION);
                      }
                  ),
                ),
                Expanded(
                  flex:1,
                  child:GestureDetector(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset('images/wechat-friend.png', height: 50.0, width: 50.0,),
                          Padding(
                            child: Text(
                              AppLocalizations.of(context).getLanguageText('wechatTimeline'),
                              style: TextStyle(fontSize:12),
                            ),
                            padding: EdgeInsets.all(8),
                          ),
                        ],
                      ),
                      onTap: () {
                        _share(context, fluwx.WeChatScene.TIMELINE);
                      }
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  _share(BuildContext context, fluwx.WeChatScene scene) async {
    var model = fluwx.WeChatShareWebPageModel(
        webPage: webPageUrl,
        title: AppLocalizations.of(context).getLanguageText('shareTitle'),
        description: AppLocalizations.of(context).getLanguageText('shareDescription'),
        thumbnail: "assets://images/logo.png",
        scene: scene,
        transaction: "ScratchPaper");
    try {
      await fluwx.shareToWeChat(model);
    } on PlatformException catch (e) {
      print("error: ${e.toString()}.");
      showErrorToast(AppLocalizations.of(context).getLanguageText('wechatNotFound'));
    }
    return;
  }
}