import 'package:flutter/material.dart';
import 'package:scratch_paper_flutter/utils/iconfonts.dart';
import './components/ScratchPaper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/languange.dart';
import 'utils/cupertino.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';

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
  final scratchModes = <ScratchMode>[ScratchMode.edit, ScratchMode.move, ScratchMode.eraser];
  var scratchMode = ScratchMode.edit;
  Color selectedColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                scratchMode: scratchMode,
                selectedColor: selectedColor,
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
                          color: ScratchMode2Color(scratchMode),
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              child: Icon(
                                ScratchMode2Icon(scratchMode),
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
                      onSelected: (ScratchMode result) { setState(() { scratchMode = result; }); },
                      itemBuilder: (BuildContext context) {
                        return scratchModes.map((item) {
                          return PopupMenuItem<ScratchMode>(
                            value: item,
                            child: Row(
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(right: 10),
                                  child: Icon(
                                    ScratchMode2Icon(item),
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ),
                                Text(
                                  ScratchMode2Desc(context, item),
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
                                    contentPadding: EdgeInsets.only(bottom: 10),
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

                            },
                          ),
                          IconButton(
                            icon: Icon(IconFonts.undo,size: 24,),
                            onPressed: () {

                            },
                          ),
                          IconButton(
                            icon: Icon(IconFonts.redo,size: 24,),
                            onPressed: () {

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
                            onSelected: (MoreAction result) {

                            },
                            itemBuilder: (BuildContext context) {
                              return <MoreAction>[MoreAction.import, MoreAction.export].map((item) {
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
          ]
        ),
      ),
    );
  }
}

enum MoreAction {
  import,
  export,
}

IconData MoreAction2Icon(MoreAction action) {
  switch (action) {
    case MoreAction.import:
      return IconFonts.import;
    case MoreAction.export:
      return IconFonts.export;
  }
  return null;
}

String MoreAction2Desc(BuildContext context, MoreAction action) {
  switch (action) {
    case MoreAction.import:
      return AppLocalizations.of(context).getLanguageText('import');
    case MoreAction.export:
      return AppLocalizations.of(context).getLanguageText('export');
  }
  return null;
}