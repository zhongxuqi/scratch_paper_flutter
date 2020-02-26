import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scratch_paper_flutter/utils/iconfonts.dart';
import './components/ScratchPaper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/language.dart';
import 'utils/cupertino.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'components/LineWeightPicker.dart';
import 'components/Toast.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluwx/fluwx.dart' as fluwx;
import 'package:multi_image_picker/multi_image_picker.dart';
import 'dart:ui' as ui;
import 'package:permission_handler/permission_handler.dart';
import 'components/alertDialog.dart';
import './net/mypass.dart' as mypass;
import 'dart:convert';
import './utils/platform_custom.dart' as platform_custom;
import './utils/user.dart' as user;
import './common/consts.dart' as consts;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScratchPaper',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: [
        const AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ChineseCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('zh','CH'),
      ],
      debugShowCheckedModeBanner: false,
      showSemanticsDebugger:false,
      initialRoute: '/',
      routes: {
        '/': (context) => MainPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key}): super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final scratchModes = <ScratchMode>[ScratchMode.edit, ScratchMode.move, ScratchMode.eraser, ScratchMode.graphics, ScratchMode.text, ScratchMode.crop];
  final scratchGraphicsModes = <ScratchGraphicsMode>[ScratchGraphicsMode.line, ScratchGraphicsMode.square, ScratchGraphicsMode.circle, ScratchGraphicsMode.polygon];
  final GlobalKey<ScratchPaperState> _scratchPaperState = new GlobalKey<ScratchPaperState>();

  var freeExpired = false;
  static const MaterialColor black = MaterialColor(
    0xFF000000,
    <int, Color>{
      500: Color(0xFF000000),
    },
  );
  final colors = const <ColorSwatch>[
    black,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];
  var scratchMode = ScratchMode.edit;
  var scratchGraphicsMode = ScratchGraphicsMode.line;
  Color selectedColor = black;
  final lineWeights = <double>[2, 4, 6, 8, 10, 12];
  double selectedLineWeight = 4;

  final eraserLineWeights = <double>[12, 16, 20, 24, 28, 32];
  double eraserSelectedLineWeight = 20;

  Offset textInputerOffset;
  final textInpterMinWidth = 200;
  final textCtl = TextEditingController();
  final textFocusNode = FocusNode();
  double fontSize = 12;
  final fontSizes = <double>[8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30];

  var loginType = "";

  @override
  void initState() {
    super.initState();
    fluwx.registerWxApi(
        appId: "wx27f355795896793b", doOnAndroid: true, doOnIOS: true);
    checkFreeExpied();
  }

//  void checkPayBtn() async {
//    var appChannel = await platform_custom.getAppChannel();
//    print("appChannel $appChannel");
//    var appVersion = await user.getAppVersion();
//    mypass.getAppVersion().then((resp) {
//      Map<String, dynamic> respObj = json.decode(utf8.decode(resp.bodyBytes));
//      if (respObj['errno'] != 0) {
//        return;
//      }
//      Map<String, int> respData = respObj['data'];
//      var appVersion = respData['default'];
//      if (respData.containsKey(appChannel)) {
//        appVersion = respData['appChannel'];
//      }
//      print(appVersion);
//      setState(() {
//        showPayBtn = appVersion >= consts.AppVersion;
//      });
//    });
//  }

  void checkFreeExpied() async {
    var userID = await user.getUserID();
    loginType = await user.getUserType();
    setState(() {});
    freeExpired = await user.isFreeExpired();
    if (loginType != '') {
      mypass.postAccount(loginType, userID).then((resp) async {
        Map<String, dynamic> respObj = json.decode(utf8.decode(resp.bodyBytes));
        if (respObj['errno'] != 0) {
          return;
        }
        var currTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (respObj['data']['expire_time'] > currTime) {
          await user.addFreeExpired(7);
          freeExpired = await user.isFreeExpired();
        }
      }).whenComplete(() {
        setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  void showVideoAds() async {
    var result = await platform_custom.showVideoAds();
    if (result == 'wait') {
      showVideoAds();
      return;
    } else if (result == 'fail') {
      showErrorToast(AppLocalizations.of(context).getLanguageText('videoFailHint'));
      return;
    } else {
      user.addFreeExpired(1);
      setState(() {
        freeExpired = false;
      });
    }
  }

  Future<bool> _onWillPop() {
    if (_scratchPaperState.currentState != null && _scratchPaperState.currentState.strokes.length > 0) {
      showAlertDialog(context, AppLocalizations.of(context).getLanguageText('exitAlert'), callback: () {
        SystemNavigator.pop();
      });
      return Future.value(false);
    }
    return Future.value(true);
  }

  void addText() {
    if (textCtl.text.length <= 0) return;
    setState(() {
      _scratchPaperState.currentState.addText(textInputerOffset, textCtl.text, fontSize);
      textInputerOffset = null;
      textCtl.text = "";
    });
  }

  void showLogin() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.white,
          height: 150.0,
          child: Column(
            children: <Widget>[
              Container(
                alignment: Alignment.centerLeft,
                child: Padding(
                  child: Text(
                    AppLocalizations.of(context).getLanguageText('thirdPartyLogin'),
                    style: TextStyle(fontSize:17, color: Colors.grey),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
              ),
              Divider(color: Colors.grey[300], height: 1,),
              Container(
                padding: EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex:1,
                      child:GestureDetector(
                          child: Image.asset('images/QQ.png', height: 50.0, width: 50.0,),
                          onTap: () async {
                            await user.loginQQ();
                            loginType = await user.getUserType();
                            setState(() {});
                            if (loginType != '') {
                              Navigator.of(context).pop();
                              checkFreeExpied();
                            }
                          }
                      ),
                    ),
                    Expanded(
                      flex:1,
                      child:GestureDetector(
                        child: Image.asset('images/weibo.png', height: 50.0, width: 50.0,),
                        onTap: () async {
                          await user.loginWeibo();
                          loginType = await user.getUserType();
                          setState(() {});
                          if (loginType != '') {
                            Navigator.of(context).pop();
                            checkFreeExpied();
                          }
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var avatar = 'images/default_head.png';
    var nickname = AppLocalizations.of(context).getLanguageText('clickLogin');
    switch (loginType) {
      case "qq":
        avatar = 'images/QQ.png';
        nickname = AppLocalizations.of(context).getLanguageText('logined');
        break;
      case "weibo":
        avatar = 'images/weibo.png';
        nickname = AppLocalizations.of(context).getLanguageText('logined');
        break;
    }
    Widget body = Stack(
      children: <Widget>[
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          child: ScratchPaper(
            key: _scratchPaperState,
            scratchMode: scratchMode,
            scratchGraphicsMode: scratchGraphicsMode,
            selectedColor: selectedColor,
            selectedLineWeight: scratchMode==ScratchMode.eraser?eraserSelectedLineWeight:selectedLineWeight,
            modeChanged: (newMode) {
              setState(() {
                scratchMode = newMode;
              });
            },
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            margin: EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                PopupMenuButton<ScratchMode>(
                  initialValue: scratchMode,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: scratchMode2Color(scratchMode),
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          child: Icon(
                            scratchMode2Icon(scratchMode),
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        Container(
                          child: Icon(
                            IconFonts.dropdown,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onSelected: (ScratchMode result) {
                    setState(() {
                      textInputerOffset = null;
                      textCtl.text = "";
                      scratchMode = result;
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return scratchModes.map((item) {
                      return PopupMenuItem<ScratchMode>(
                        value: item,
                        child: Row(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(right: 10),
                              child: Icon(
                                scratchMode2Icon(item),
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                            Text(
                              scratchMode2Desc(context, item),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[100]),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          IconFonts.colors,
                          size: 24,
                          color: selectedColor,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return SimpleDialog(
                                contentPadding: EdgeInsets.all(0),
                                children: <Widget>[
                                  Container(
                                    constraints: BoxConstraints(
                                      maxHeight: MediaQuery.of(context).size.height / 2,
                                    ),
                                    child: MaterialColorPicker(
                                      allowShades: false,
                                      onMainColorChange: (Color color) {
                                        setState(() {
                                          selectedColor = color;
                                        });
                                        Navigator.of(context).pop();
                                      },
                                      selectedColor: selectedColor,
                                      colors: colors,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(IconFonts.lineWeight,size: 24,),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return SimpleDialog(
                                contentPadding: EdgeInsets.all(0),
                                children: <Widget>[
                                  Container(
                                    child: LineWeightPicker(
                                      selectedColor: selectedColor,
                                      lineWeight: scratchMode==ScratchMode.eraser?eraserSelectedLineWeight:selectedLineWeight,
                                      onValue: (newValue) {
                                        if (scratchMode == ScratchMode.eraser) {
                                          setState(() {
                                            eraserSelectedLineWeight = newValue;
                                          });
                                        } else {
                                          setState(() {
                                            selectedLineWeight = newValue;
                                          });
                                        }
                                        Navigator.of(context).pop();
                                      },
                                      lineWeights: scratchMode==ScratchMode.eraser?eraserLineWeights:lineWeights,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(IconFonts.undo,size: 24,),
                        onPressed: () {
                          if (_scratchPaperState.currentState == null || !_scratchPaperState.currentState.undo()) {
                            showErrorToast(AppLocalizations.of(context).getLanguageText('noMoreUndo'));
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(IconFonts.redo,size: 24,),
                        onPressed: () {
                          if (_scratchPaperState.currentState == null || !_scratchPaperState.currentState.redo()) {
                            showErrorToast(AppLocalizations.of(context).getLanguageText('noMoreRedo'));
                          }
                        },
                      ),
                      PopupMenuButton<MoreAction>(
                        padding: EdgeInsets.all(0),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                          ),
                          child: Icon(
                            IconFonts.more,
                            color: Colors.black,
                            size: 22,
                          ),
                        ),
                        onSelected: (MoreAction result) async {
                          if (_scratchPaperState.currentState == null) return;
                          switch (result) {
                            case MoreAction.user:
                              showLogin();
                              break;
                            case MoreAction.backOrigin:
                              _scratchPaperState.currentState.backOrigin();
                              break;
                            case MoreAction.export:
                              var imageFilePath = await _scratchPaperState.currentState.export();
                              if (imageFilePath != "") {
                                await FlutterShare.shareFile(
                                  title: 'ScratchPaper',
                                  filePath: imageFilePath,
                                );
                              }
                              break;
                            case MoreAction.clear:
                              _scratchPaperState.currentState.reset();
                              break;
                            case MoreAction.import:
                              Map<PermissionGroup, PermissionStatus> permissions = await PermissionHandler().requestPermissions([PermissionGroup.storage, PermissionGroup.camera]);
                              if (permissions[PermissionGroup.storage] != PermissionStatus.granted || permissions[PermissionGroup.camera] != PermissionStatus.granted) {
                                return;
                              }
                              List<Asset> resultList = List<Asset>();
                              try {
                                resultList = await MultiImagePicker.pickImages(
                                  maxImages: 1,
                                  enableCamera: true,
                                );
                              } on Exception catch (e) {
                                print(e.toString());
                                return;
                              }
                              if (!mounted) return;
                              if (resultList.length <= 0) return;
                              ui.decodeImageFromList((await resultList[0].getByteData()).buffer.asUint8List(), (image) {
                                _scratchPaperState.currentState.image = image;
                              });
                              break;
                            case MoreAction.gallery:
                              _scratchPaperState.currentState.saveGallery();
                              break;
                            case MoreAction.wechat:
                              var imageFilePath = await _scratchPaperState.currentState.export();
                              if (imageFilePath != "") {
                                fluwx.shareToWeChat(fluwx.WeChatShareImageModel(
                                  image: "file://$imageFilePath",
                                  scene: fluwx.WeChatScene.SESSION,
                                ));
                              }
                              break;
                            case MoreAction.feedback:
                              showFeedbackDialog(context, callback: (msg) {
                                mypass.feedback(msg).then((resp) {
                                  Map<String, dynamic> respObj = json.decode(utf8.decode(resp.bodyBytes));
                                  if (respObj['errno'] != 0) {
                                    return;
                                  }
                                  showSuccessToast(AppLocalizations.of(context).getLanguageText('thankFeedback'));
                                });
                              });
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return <MoreAction>[MoreAction.user, MoreAction.backOrigin, MoreAction.clear, MoreAction.import, MoreAction.export, MoreAction.gallery, MoreAction.wechat, MoreAction.feedback].map((item) {
                            if (item == MoreAction.user) {
                              return PopupMenuItem<MoreAction>(
                                value: item,
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(right: 10),
                                      child: Image.asset(
                                        avatar,
                                        height: 30.0,
                                        width: 30.0,
                                      ),
                                    ),
                                    Text(
                                      nickname,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return PopupMenuItem<MoreAction>(
                              value: item,
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(right: 10),
                                    child: Icon(
                                      MoreAction2Icon(item),
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                  Text(
                                    MoreAction2Desc(context, item),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        scratchMode==ScratchMode.graphics?Positioned(
          top: 0,
          left: 10,
          bottom: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[100]),
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: scratchGraphicsModes.map((item) {
                    var borderRadius = BorderRadius.zero;
                    if (item == ScratchGraphicsMode.line) {
                      borderRadius = BorderRadius.vertical(top: Radius.circular(999));
                    } else if (item == ScratchGraphicsMode.polygon) {
                      borderRadius = BorderRadius.vertical(bottom: Radius.circular(999));
                    }
                    return GestureDetector(
                      child: Container(
                        decoration: BoxDecoration(
                          color: item==scratchGraphicsMode?Colors.deepPurple:Colors.transparent,
                          borderRadius: borderRadius,
                        ),
                        child: IconButton(
                          icon: Icon(
                            scratchGraphicsMode2Icon(item),
                            size: 24,
                            color: item==scratchGraphicsMode?Colors.white:Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              scratchGraphicsMode = item;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ):Container(),
        textInputerOffset==null?Positioned(
          top: 0,
          left: 0,
          child: Container(),
        ):Positioned(
          top: textInputerOffset.dy,
          left: textInputerOffset.dx,
          child: Container(
            width: MediaQuery.of(context).size.width - textInputerOffset.dx - 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(5)),
              border: Border.all(color: Colors.teal),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: CupertinoTextField(
                    controller: textCtl,
                    focusNode: textFocusNode,
                    maxLines: 1,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    placeholder: AppLocalizations.of(context).getLanguageText('inputHint'),
                    style: TextStyle(
                      fontSize: fontSize * _scratchPaperState.currentState.scale,
                      color: selectedColor,
                      textBaseline: TextBaseline.alphabetic,
                    ),
                    onSubmitted: (t) {
                      addText();
                    },
                    onEditingComplete: () {
                      addText();
                    },
                  ),
                ),
                InkWell(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                    child: Icon(IconFonts.ok, size: 17, color: Colors.teal,),
                  ),
                  onTap: () {
                    addText();
                  },
                ),
                Container(
                  margin: EdgeInsets.only(right: 5),
                  child: PopupMenuButton<double>(
                    initialValue: fontSize,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            child: Text(
                              fontSize.toInt().toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                          Container(
                            child: Icon(
                              IconFonts.dropdown,
                              color: Colors.teal,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onSelected: (newValue) {
                      setState(() {
                        fontSize = newValue;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return fontSizes.map((item) {
                        return PopupMenuItem<double>(
                          value: item,
                          child: Text(
                            item.toInt().toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal,
                            ),
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        freeExpired?Positioned(
          top: 0,
          left: 0,
          bottom: 0,
          right: 0,
          child: Container(
            color: Colors.black38,
            child: SimpleDialog(
              titlePadding: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              contentPadding: EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: Text(
                          AppLocalizations.of(context).getLanguageText('freeExpired'),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      child: Container(
                        padding: EdgeInsets.all(3),
                        child: Icon(
                          IconFonts.close,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
                      onTap: () {
                        SystemNavigator.pop();
                      },
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    RawMaterialButton(
                      child: Text(
                        AppLocalizations.of(context).getLanguageText('showAds'),
                        style: TextStyle(
                          color: Colors.green,
                        ),
                      ),
                      onPressed: () {
                        showVideoAds();
                      }
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    RawMaterialButton(
                      child: Text(
                        AppLocalizations.of(context).getLanguageText('payAction'),
                        style: TextStyle(
                          color: Colors.orange,
                        ),
                      ),
                      onPressed: () {
                        if (loginType == '') {
                          showLogin();
                          return;
                        }
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SimpleDialog(
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(bottom:10.0, left: 20.0, right: 20),
                                  child: Text(
                                    AppLocalizations.of(context).getLanguageText('payHint'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        margin: EdgeInsets.symmetric(vertical:10.0, horizontal: 20.0),
                                        child: GestureDetector(
                                          child: Container(
                                            padding: EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius: BorderRadius.all(Radius.circular(6.0)),
                                            ),
                                            child: Center(
                                              child: Text(
                                                AppLocalizations.of(context).getLanguageText('sharePayToWechat'),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          onTap: () async {
                                            var userID = await user.getUserID();
                                            var payjsUrl = "${mypass.url}/payjs.html?app_id=${consts.AppID}&platform_type=$loginType&account=$userID";
                                            var model = fluwx.WeChatShareWebPageModel(
                                                webPage: payjsUrl,
                                                title: AppLocalizations.of(context).getLanguageText('payUrl'),
                                                description: AppLocalizations.of(context).getLanguageText('thankForPay'),
                                                thumbnail: "assets://images/logo.png",
                                                scene: fluwx.WeChatScene.SESSION,
                                                transaction: "scratchpaper");
                                            try {
                                              await fluwx.shareToWeChat(model);
                                            } on PlatformException catch(e) {
                                              print("error: ${e.toString()}.");
                                              showErrorToast(AppLocalizations.of(context).getLanguageText(
                                                  'wechat_not_found'));
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      }
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    RawMaterialButton(
                      child: Text(
                        AppLocalizations.of(context).getLanguageText('paidLogin'),
                        style: TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                      onPressed: () {
                        showLogin();
                      }
                    ),
                  ],
                ),
              ],
            ),
          ),
        ):Container(),
      ]
    );
    if (scratchMode == ScratchMode.text) {
      body = GestureDetector(
        child: body,
        onTapUp: (details) {
          setState(() {
            textInputerOffset = Offset(
              details.localPosition.dx+textInpterMinWidth>MediaQuery.of(context).size.width?MediaQuery.of(context).size.width-textInpterMinWidth:details.localPosition.dx,
              details.localPosition.dy,
            );
          });
        },
      );
    }
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: body,
        ),
      ),
    );
  }
}

enum MoreAction {
  user,
  backOrigin,
  clear,
  import,
  export,
  gallery,
  wechat,
  feedback,
}

IconData MoreAction2Icon(MoreAction action) {
  switch (action) {
    case MoreAction.backOrigin:
      return IconFonts.location;
    case MoreAction.clear:
      return IconFonts.reset;
    case MoreAction.import:
      return IconFonts.import;
    case MoreAction.export:
      return IconFonts.export;
    case MoreAction.gallery:
      return IconFonts.gallery;
    case MoreAction.wechat:
      return IconFonts.wechat;
    case MoreAction.feedback:
      return IconFonts.feedback;
    default:
      return null;
  }
}

String MoreAction2Desc(BuildContext context, MoreAction action) {
  switch (action) {
    case MoreAction.backOrigin:
      return AppLocalizations.of(context).getLanguageText('backOrigin');
    case MoreAction.clear:
      return AppLocalizations.of(context).getLanguageText('clear');
    case MoreAction.import:
      return AppLocalizations.of(context).getLanguageText('import');
    case MoreAction.export:
      return AppLocalizations.of(context).getLanguageText('export');
    case MoreAction.gallery:
      return AppLocalizations.of(context).getLanguageText('save2Gallery');
    case MoreAction.wechat:
      return AppLocalizations.of(context).getLanguageText('shareWechat');
    case MoreAction.feedback:
      return AppLocalizations.of(context).getLanguageText('feedback');
    default:
      return null;
  }
}