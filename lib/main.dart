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
  final scratchModes = <ScratchMode>[ScratchMode.edit, ScratchMode.move, ScratchMode.eraser, ScratchMode.graphics];
  final scratchGraphicsModes = <ScratchGraphicsMode>[ScratchGraphicsMode.line, ScratchGraphicsMode.square, ScratchGraphicsMode.circle, ScratchGraphicsMode.polygon];
  final GlobalKey<ScratchPaperState> _scratchPaperState = new GlobalKey<ScratchPaperState>();

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
  final lineWeights = <double>[1, 2, 4, 6, 8, 10];
  double selectedLineWeight = 2;

  final eraserLineWeights = <double>[8, 12, 16, 20, 24, 28];
  double eraserSelectedLineWeight = 16;

  @override
  void initState() {
    super.initState();
    fluwx.registerWxApi(
        appId: "wx27f355795896793b", doOnAndroid: true, doOnIOS: true);
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Stack(
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
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return <MoreAction>[MoreAction.backOrigin, MoreAction.clear, MoreAction.import, MoreAction.export, MoreAction.gallery, MoreAction.wechat].map((item) {
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
            ]
          ),
        ),
      ),
    );
  }
}

enum MoreAction {
  backOrigin,
  clear,
  import,
  export,
  gallery,
  wechat,
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
  }
  return null;
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
  }
  return null;
}