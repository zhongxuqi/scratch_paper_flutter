import 'package:flutter/material.dart';
import 'package:scratch_paper_flutter/utils/iconfonts.dart';
import './components/ScratchPaper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/languange.dart';
import 'utils/cupertino.dart';

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
              child: ScratchPaper(),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                decoration: BoxDecoration(
                  color: ScratchMode2Color(scratchMode),
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: PopupMenuButton<ScratchMode>(
                  initialValue: scratchMode,
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
              ),
            ),
          ]
        ),
      ),
    );
  }
}