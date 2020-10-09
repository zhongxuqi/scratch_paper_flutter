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
import 'package:fluwx/fluwx.dart' as fluwx;
import 'dart:ui' as ui;
import 'components/alertDialog.dart';
import './net/mypass.dart' as mypass;
import 'dart:convert';
import './utils/platform_custom.dart' as platform_custom;
import './utils/user.dart' as user;
import './common/consts.dart' as consts;
import 'components/userNoticeDialog.dart';
import 'components/shareWechatDialog.dart';
import 'components/imagePickDialog.dart';
import './utils/common.dart';
import 'dart:io';
import 'package:share/share.dart';

typedef FreeExpiredCallback<T, D> = void Function(T needPay, D isVip);

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
        const Locale('zh', 'CH'),
      ],
      debugShowCheckedModeBanner: false,
      showSemanticsDebugger: false,
      initialRoute: '/',
      routes: {
        '/': (context) => MainPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final scratchModes = <ScratchMode>[
    ScratchMode.edit,
    ScratchMode.move,
    ScratchMode.eraser,
    ScratchMode.graphics,
    ScratchMode.text,
    ScratchMode.crop
  ];
  final scratchGraphicsModes = <ScratchGraphicsMode>[
    ScratchGraphicsMode.line,
    ScratchGraphicsMode.square,
    ScratchGraphicsMode.circle,
    ScratchGraphicsMode.polygon
  ];
  final GlobalKey<ScratchPaperState> _scratchPaperState =
      new GlobalKey<ScratchPaperState>();

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
  final fontSizes = <double>[
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30
  ];

  var loginType = "";

  var showUserNotice = false;

  bool shareWechat = false;
  int shareWechatDays = 0;
  String shareWechatUrl = "";
  var needPay = false;
  bool isVip = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    fluwx.registerWxApi(
        appId: "wx27f355795896793b", doOnAndroid: true, doOnIOS: true);

    mypass.scratchPaper().then((resp) {
      Map<String, dynamic> respObj = json.decode(utf8.decode(resp.bodyBytes));
      if (respObj['errno'] != 0) {
        return;
      }
      Map<String, dynamic> respData = respObj['data'];
      Map<String, dynamic> respDataShareWechat = respData['share_wechat'];
      shareWechat = respDataShareWechat['status'];
      shareWechatDays = respDataShareWechat['days'];
      shareWechatUrl = respDataShareWechat['url'];
      user.setBetaVersion(respData['beta_version']);
      setState(() {});
    });
    checkFirstOpen();
  }

  void checkFirstOpen() async {
    if (Platform.isAndroid) {
      var isFirstOpen = await user.getFirstOpenKey();
      if (isFirstOpen == null) {
        // 首次打开展示用户协议
        setState(() {
          showUserNotice = true;
        });

        user.setFirstOpenKey();
      }
    }
  }

  void checkFreeExpired(FreeExpiredCallback callback) async {
    if (Platform.isIOS) {
      if (callback != null) callback(true, false);
      return;
    } else if (Platform.isAndroid) {
      var userID = await user.getUserID();
      loginType = await user.getUserType();
      setState(() {});
      var freeExpired = await user.isFreeExpired();
      var isVip = false;
      if (loginType != '') {
        mypass.postAccount(loginType, userID).then((resp) async {
          Map<String, dynamic> respObj =
              json.decode(utf8.decode(resp.bodyBytes));
          if (respObj['errno'] != 0) {
            return;
          }
          var currTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          if (respObj['data']['expire_time'] > currTime) {
            await user.addFreeExpired(7);
            freeExpired = await user.isFreeExpired();
            isVip = true;
          } else {
            isVip = false;
          }
        }).whenComplete(() {
          if (callback != null) callback(freeExpired, isVip);
        });
      } else {
        if (callback != null) callback(freeExpired, isVip);
      }
    }
  }

  Future<bool> _onWillPop() {
    if (_scratchPaperState.currentState != null &&
        _scratchPaperState.currentState.strokes.length > 0) {
      showAlertDialog(
          context, AppLocalizations.of(context).getLanguageText('exitAlert'),
          callback: () {
        SystemNavigator.pop();
      });
      return Future.value(false);
    }
    return Future.value(true);
  }

  void addText() {
    if (textCtl.text.length <= 0) return;
    setState(() {
      _scratchPaperState.currentState
          .addText(textInputerOffset, textCtl.text, fontSize);
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
                    AppLocalizations.of(context)
                        .getLanguageText('thirdPartyLogin'),
                    style: TextStyle(fontSize: 17, color: Colors.grey),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
              ),
              Divider(
                color: Colors.grey[300],
                height: 1,
              ),
              Container(
                padding: EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                          child: Image.asset(
                            'images/QQ.png',
                            height: 50.0,
                            width: 50.0,
                          ),
                          onTap: () async {
                            await user.loginQQ();
                            loginType = await user.getUserType();
                            setState(() {});
                            if (loginType != '') {
                              Navigator.of(context).pop();
                              checkFreeExpired((freeExpired, isVip) {
                                setState(() {
                                  this.isVip = isVip;
                                });
                              });
                            }
                          }),
                    ),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                          child: Image.asset(
                            'images/weibo.png',
                            height: 50.0,
                            width: 50.0,
                          ),
                          onTap: () async {
                            await user.loginWeibo();
                            loginType = await user.getUserType();
                            setState(() {});
                            if (loginType != '') {
                              Navigator.of(context).pop();
                              checkFreeExpired((freeExpired, isVip) {
                                setState(() {
                                  this.isVip = isVip;
                                });
                              });
                            }
                          }),
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
    Widget body = Stack(children: <Widget>[
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
          selectedLineWeight: scratchMode == ScratchMode.eraser
              ? eraserSelectedLineWeight
              : selectedLineWeight,
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
                  if (result == ScratchMode.edit ||
                      result == ScratchMode.move) {
                    setState(() {
                      textInputerOffset = null;
                      textCtl.text = "";
                      scratchMode = result;
                    });
                  } else {
                    checkFreeExpired((needPay, isVip) {
                      if (!needPay) {
                        setState(() {
                          textInputerOffset = null;
                          textCtl.text = "";
                          scratchMode = result;
                        });
                      } else {
                        setState(() {
                          this.needPay = needPay;
                        });
                      }
                    });
                  }
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
                                    maxHeight:
                                        MediaQuery.of(context).size.height / 2,
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
                      icon: Icon(
                        IconFonts.lineWeight,
                        size: 24,
                      ),
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
                                    lineWeight:
                                        scratchMode == ScratchMode.eraser
                                            ? eraserSelectedLineWeight
                                            : selectedLineWeight,
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
                                    lineWeights:
                                        scratchMode == ScratchMode.eraser
                                            ? eraserLineWeights
                                            : lineWeights,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        IconFonts.undo,
                        size: 24,
                      ),
                      onPressed: () {
                        if (_scratchPaperState.currentState == null ||
                            !_scratchPaperState.currentState.undo()) {
                          showErrorToast(AppLocalizations.of(context)
                              .getLanguageText('noMoreUndo'));
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        IconFonts.redo,
                        size: 24,
                      ),
                      onPressed: () {
                        if (_scratchPaperState.currentState == null ||
                            !_scratchPaperState.currentState.redo()) {
                          showErrorToast(AppLocalizations.of(context)
                              .getLanguageText('noMoreRedo'));
                        }
                      },
                    ),
                    PopupMenuButton<MoreAction>(
                      padding: EdgeInsets.all(0),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
                            var imageFilePath =
                                await _scratchPaperState.currentState.export();
                            if (imageFilePath != "") {
                              Share.shareFiles([imageFilePath]);
                            }
                            break;
                          case MoreAction.clear:
                            _scratchPaperState.currentState.reset();
                            break;
                          case MoreAction.import:
                            if (!await checkPermission()) {
                              return;
                            }
                            showModalBottomSheet(
                              context: context,
                              builder: (ctx) => ImagePickDialog(
                                callback: (image) async {
                                  ui.decodeImageFromList(
                                      await image.readAsBytes(), (image) {
                                    _scratchPaperState.currentState.image =
                                        image;
                                  });
                                },
                                title: AppLocalizations.of(context)
                                    .getLanguageText('importImageEdit'),
                              ),
                            );
                            break;
                          case MoreAction.gallery:
                            _scratchPaperState.currentState.saveGallery();
                            break;
                          case MoreAction.wechat:
                            var imageFilePath =
                                await _scratchPaperState.currentState.export();
                            if (imageFilePath != "") {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => ShareWechatDialog(
                                  callback: (fluwx.WeChatScene scene) async {
                                    Navigator.of(context).pop();
                                    try {
                                      await fluwx.shareToWeChat(
                                          fluwx.WeChatShareImageModel(
                                        image: "file://$imageFilePath",
                                        scene: scene,
                                      ));
                                    } on Exception catch (e) {
                                      print("error: ${e.toString()}.");
                                      showErrorToast(AppLocalizations.of(
                                              context)
                                          .getLanguageText('wechatNotFound'));
                                    }
                                  },
                                ),
                              );
                            }
                            break;
                          case MoreAction.invitWechat:
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => ShareWechatDialog(
                                callback: (fluwx.WeChatScene scene) async {
                                  Navigator.of(context).pop();
                                  var model = fluwx.WeChatShareWebPageModel(
                                      webPage: shareWechatUrl,
                                      title: AppLocalizations.of(context)
                                          .getLanguageText('shareTitle'),
                                      description: AppLocalizations.of(context)
                                          .getLanguageText('shareDescription'),
                                      thumbnail: "assets://images/logo.png",
                                      scene: scene,
                                      transaction: "ScratchPaper");
                                  try {
                                    await fluwx.shareToWeChat(model);
                                  } on Exception catch (e) {
                                    print("error: ${e.toString()}.");
                                    showErrorToast(AppLocalizations.of(context)
                                        .getLanguageText('wechatNotFound'));
                                  }
                                },
                              ),
                            );
                            break;
                          case MoreAction.feedback:
                            showFeedbackDialog(context, callback: (msg) {
                              if (msg == '') return;
                              mypass.feedback(msg).then((resp) {
                                Map<String, dynamic> respObj =
                                    json.decode(utf8.decode(resp.bodyBytes));
                                if (respObj['errno'] != 0) {
                                  return;
                                }
                                showSuccessToast(AppLocalizations.of(context)
                                    .getLanguageText('thankFeedback'));
                              });
                            });
                            break;
                          case MoreAction.privacy:
                            setState(() {
                              showUserNotice = true;
                            });
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        var actions = [];
                        if (Platform.isAndroid) {
                          actions.add(MoreAction.user);
                        }
                        actions.addAll(<MoreAction>[
                          MoreAction.backOrigin,
                          MoreAction.clear,
                          MoreAction.import,
                          MoreAction.export
                        ]);
                        if (Platform.isAndroid) {
                          actions.add(MoreAction.gallery);
                          actions.add(MoreAction.wechat);
                        }
                        if (shareWechat) {
                          actions.add(MoreAction.invitWechat);
                        }
                        actions.add(MoreAction.feedback);
                        actions.add(MoreAction.privacy);
                        return actions.map((item) {
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
                                  isVip
                                      ? Container(
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(4)),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          margin: EdgeInsets.only(left: 8),
                                          child: Text(
                                            "VIP",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                          ),
                                        )
                                      : Container(),
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
      scratchMode == ScratchMode.graphics
          ? Positioned(
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
                          borderRadius =
                              BorderRadius.vertical(top: Radius.circular(999));
                        } else if (item == ScratchGraphicsMode.polygon) {
                          borderRadius = BorderRadius.vertical(
                              bottom: Radius.circular(999));
                        }
                        return GestureDetector(
                          child: Container(
                            decoration: BoxDecoration(
                              color: item == scratchGraphicsMode
                                  ? Colors.deepPurple
                                  : Colors.transparent,
                              borderRadius: borderRadius,
                            ),
                            child: IconButton(
                              icon: Icon(
                                scratchGraphicsMode2Icon(item),
                                size: 24,
                                color: item == scratchGraphicsMode
                                    ? Colors.white
                                    : Colors.black,
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
            )
          : Container(),
      textInputerOffset == null
          ? Positioned(
              top: 0,
              left: 0,
              child: Container(),
            )
          : Positioned(
              top: textInputerOffset.dy,
              left: textInputerOffset.dx,
              child: Container(
                width: MediaQuery.of(context).size.width -
                    textInputerOffset.dx -
                    5,
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
                        placeholder: AppLocalizations.of(context)
                            .getLanguageText('inputHint'),
                        style: TextStyle(
                          fontSize: fontSize *
                              _scratchPaperState.currentState.scale /
                              baseScale,
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
                        padding:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                        child: Icon(
                          IconFonts.ok,
                          size: 17,
                          color: Colors.teal,
                        ),
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
      needPay && !showUserNotice
          ? Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              right: 0,
              child: Container(
                color: Colors.black38,
                child: SimpleDialog(
                  titlePadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                  contentPadding: EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 0),
                            child: Text(
                              AppLocalizations.of(context)
                                  .getLanguageText('freeExpired'),
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
                            setState(() {
                              needPay = false;
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        RawMaterialButton(
                            child: Text(
                              AppLocalizations.of(context)
                                  .getLanguageText('payAction'),
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
                                        margin: EdgeInsets.only(
                                            bottom: 10.0,
                                            left: 20.0,
                                            right: 20),
                                        child: Text(
                                          AppLocalizations.of(context)
                                              .getLanguageText('payHint'),
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
                                              margin: EdgeInsets.symmetric(
                                                  vertical: 10.0,
                                                  horizontal: 20.0),
                                              child: GestureDetector(
                                                child: Container(
                                                  padding: EdgeInsets.all(8.0),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                6.0)),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      AppLocalizations.of(
                                                              context)
                                                          .getLanguageText(
                                                              'sharePayToWechat'),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                onTap: () async {
                                                  var userID =
                                                      await user.getUserID();
                                                  var payjsUrl =
                                                      "${mypass.url}/payjs.html?app_id=${consts.AppID}&platform_type=$loginType&account=$userID";
                                                  var model = fluwx.WeChatShareWebPageModel(
                                                      webPage: payjsUrl,
                                                      title: AppLocalizations
                                                              .of(context)
                                                          .getLanguageText(
                                                              'payUrl'),
                                                      description:
                                                          AppLocalizations
                                                                  .of(context)
                                                              .getLanguageText(
                                                                  'thankForPay'),
                                                      thumbnail:
                                                          "assets://images/logo.png",
                                                      scene: fluwx
                                                          .WeChatScene.SESSION,
                                                      transaction:
                                                          "scratchpaper");
                                                  try {
                                                    await fluwx
                                                        .shareToWeChat(model);
                                                  } on PlatformException catch (e) {
                                                    print(
                                                        "error: ${e.toString()}.");
                                                    showErrorToast(
                                                        AppLocalizations.of(
                                                                context)
                                                            .getLanguageText(
                                                                'wechatNotFound'));
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
                            }),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        RawMaterialButton(
                            child: Text(
                              AppLocalizations.of(context)
                                  .getLanguageText('paidLogin'),
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                            onPressed: () {
                              showLogin();
                            }),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : Container(),
      showUserNotice && AppLocalizations.of(context).isLangZh()
          ? Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              right: 0,
              child: Container(
                color: Colors.black38,
                child: SimpleDialog(
                  titlePadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                  contentPadding: EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        RawMaterialButton(
                            child: Text(
                              AppLocalizations.of(context)
                                  .getLanguageText('showUserNotice'),
                              style: TextStyle(
                                color: Colors.deepOrange,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () {
                              showUserNoticeDialog(context);
                            }),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        RawMaterialButton(
                            child: Text(
                              AppLocalizations.of(context)
                                  .getLanguageText('agree'),
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                            onPressed: () async {
                              user.setFirstOpenKey();
                              setState(() {
                                showUserNotice = false;
                              });
                            }),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : Container(),
    ]);
    if (scratchMode == ScratchMode.text) {
      body = GestureDetector(
        child: body,
        onTapUp: (details) {
          setState(() {
            textInputerOffset = Offset(
              details.localPosition.dx + textInpterMinWidth >
                      MediaQuery.of(context).size.width
                  ? MediaQuery.of(context).size.width - textInpterMinWidth
                  : details.localPosition.dx,
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
  invitWechat,
  feedback,
  privacy
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
    case MoreAction.invitWechat:
      return IconFonts.wechat;
    case MoreAction.feedback:
      return IconFonts.feedback;
    case MoreAction.privacy:
      return IconFonts.privacy;
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
    case MoreAction.invitWechat:
      return AppLocalizations.of(context).getLanguageText('inviteFriend');
    case MoreAction.feedback:
      return AppLocalizations.of(context).getLanguageText('feedback');
    case MoreAction.privacy:
      return AppLocalizations.of(context).getLanguageText('privacy');
    default:
      return null;
  }
}
