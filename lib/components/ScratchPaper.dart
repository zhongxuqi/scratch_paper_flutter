import 'dart:collection';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scratch_paper_flutter/utils/iconfonts.dart';
import '../utils/language.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'alertDialog.dart';
import 'Toast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

const double baseScale = 0.5;
const double PolygonDistanceMax = 20 / baseScale;

enum ScratchMode {
  unknow,
  edit,
  move,
  eraser,
  graphics,
  text,
  crop,
}

IconData scratchMode2Icon(ScratchMode mode) {
  switch (mode) {
    case ScratchMode.unknow:
      return IconFonts.edit;
    case ScratchMode.edit:
      return IconFonts.edit;
    case ScratchMode.move:
      return IconFonts.move;
    case ScratchMode.eraser:
      return IconFonts.eraser;
    case ScratchMode.graphics:
      return IconFonts.ruler;
    case ScratchMode.text:
      return IconFonts.text;
    case ScratchMode.crop:
      return IconFonts.crop;
  }
  return null;
}

String scratchMode2Desc(BuildContext context, ScratchMode mode) {
  switch (mode) {
    case ScratchMode.unknow:
      return "";
    case ScratchMode.edit:
      return AppLocalizations.of(context).getLanguageText('edit');
    case ScratchMode.move:
      return AppLocalizations.of(context).getLanguageText('move');
    case ScratchMode.eraser:
      return AppLocalizations.of(context).getLanguageText('eraser');
    case ScratchMode.graphics:
      return AppLocalizations.of(context).getLanguageText('graphics');
    case ScratchMode.text:
      return AppLocalizations.of(context).getLanguageText('text');
    case ScratchMode.crop:
      return AppLocalizations.of(context).getLanguageText('crop');
  }
  return null;
}

Color scratchMode2Color(ScratchMode mode) {
  switch (mode) {
    case ScratchMode.unknow:
      return Colors.black;
    case ScratchMode.edit:
      return Colors.green;
    case ScratchMode.move:
      return Colors.blue;
    case ScratchMode.eraser:
      return Colors.orange;
    case ScratchMode.graphics:
      return Colors.deepPurple;
    case ScratchMode.text:
      return Colors.teal;
    case ScratchMode.crop:
      return Colors.black38;
  }
  return null;
}

enum ScratchGraphicsMode {
  line,
  square,
  circle,
  polygon,
}

IconData scratchGraphicsMode2Icon(ScratchGraphicsMode mode) {
  switch (mode) {
    case ScratchGraphicsMode.line:
      return IconFonts.line;
    case ScratchGraphicsMode.square:
      return IconFonts.square;
    case ScratchGraphicsMode.circle:
      return IconFonts.circle;
    case ScratchGraphicsMode.polygon:
      return IconFonts.polygon;
    default:
      return IconFonts.edit;
  }
}

class ScratchPaper extends StatefulWidget {
  final ScratchMode scratchMode;
  final ScratchGraphicsMode scratchGraphicsMode;
  final Color selectedColor;
  final double selectedLineWeight;
  final ValueChanged<ScratchMode> modeChanged;

  ScratchPaper({
    Key key,
    @required this.scratchMode,
    @required this.scratchGraphicsMode,
    @required this.selectedColor,
    @required this.selectedLineWeight,
    @required this.modeChanged,
  }): super(key: key);

  @override
  ScratchPaperState createState() => ScratchPaperState(
    modeChanged: modeChanged,
  );
}

void drawDash(Canvas canvas, Paint paint, Offset from, Offset to, double width) {
  var path = Path();
  var vec = (to - from) / (to - from).distance;
  var prevLoc = from;
  while ((prevLoc - from).distance < (to - from).distance) {
    var nextLoc = prevLoc + vec * width;
    if ((nextLoc - from).distance > (to - from).distance) {
      nextLoc = to;
    }
    path.moveTo(prevLoc.dx, prevLoc.dy);
    path.lineTo(nextLoc.dx, nextLoc.dy);
    canvas.drawLine(prevLoc, nextLoc, paint);
    prevLoc += vec * 2 * width;
  }
  canvas.drawPath(path, paint);
}

void drawStroke(Canvas canvas, Paint paint, Stroke stroke) {
  paint.color = stroke.color;
  paint.strokeWidth = stroke.lineWeight.toDouble();

  switch (stroke.scratchMode) {
    case ScratchMode.graphics:
      switch (stroke.scratchGraphicsMode) {
        case ScratchGraphicsMode.square:
          if (stroke.points.length >= 2) {
            var path = Path()
              ..fillType = PathFillType.evenOdd;
            path.moveTo(stroke.points.elementAt(0).x, stroke.points.elementAt(0).y);
            path.lineTo(stroke.points.elementAt(0).x, stroke.points.elementAt(1).y);
            path.lineTo(stroke.points.elementAt(1).x, stroke.points.elementAt(1).y);
            path.lineTo(stroke.points.elementAt(1).x, stroke.points.elementAt(0).y);
            path.lineTo(stroke.points.elementAt(0).x, stroke.points.elementAt(0).y);
            canvas.drawPath(path, paint);
          }
          break;
        case ScratchGraphicsMode.circle:
          if (stroke.points.length >= 2) {
            canvas.drawCircle(
              Offset(stroke.points.elementAt(0).x, stroke.points.elementAt(0).y),
              stroke.points.elementAt(0).distanceTo(stroke.points.elementAt(1)),
              paint,
            );
          }
          break;
        default:
          var path = Path()
            ..fillType = PathFillType.evenOdd;
          path.moveTo(stroke.points.elementAt(0).x, stroke.points.elementAt(0).y);
          for (var i=1;i<stroke.points.length;i++) {
            path.lineTo(stroke.points.elementAt(i).x, stroke.points.elementAt(i).y);
          }
          canvas.drawPath(path, paint);
          break;
      }
      break;
    case ScratchMode.text:
      if (stroke.points.length > 0) {
        var textPainter = TextPainter(
          text: TextSpan(
            text: stroke.text,
            style: TextStyle(
              fontSize: stroke.fontSize,
              color: stroke.color,
            ),
          ),
          textDirection: TextDirection.rtl,
        );
        textPainter.layout(minWidth: 0, maxWidth: 9999);
        textPainter.paint(canvas, Offset(stroke.points.first.x, stroke.points.first.y));
      }
      break;
    case ScratchMode.crop:
      break;
    default:
      var path = Path()
        ..fillType = PathFillType.evenOdd;
      path.moveTo(stroke.points.elementAt(0).x, stroke.points.elementAt(0).y);
      for (var i=1;i<stroke.points.length;i++) {
        path.lineTo(stroke.points.elementAt(i).x, stroke.points.elementAt(i).y);
      }
      canvas.drawPath(path, paint);
      break;
  }
}

void paintCanvas(BuildContext context, Canvas canvas, double scale, Point translate, ui.Image image, Offset offset, LinkedList<Stroke> strokes, Stroke currStroke, ScratchMode scratchMode, Point focalPoint, {bool isExport = false}) {
  canvas.scale(scale);
  canvas.translate(translate.x, translate.y);
  if (!isExport) {
    canvas.clipRect(ui.Rect.fromPoints(
      Offset(-translate.x, -translate.y - MediaQuery
          .of(context)
          .padding
          .top / scale),
      Offset(-translate.x + MediaQuery
          .of(context)
          .size
          .width / scale, -translate.y + MediaQuery
          .of(context)
          .size
          .height / scale),
    ));
  }
  var paint = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  if (scratchMode == ScratchMode.move) {
    paint.color = Colors.grey[400];

    paint.strokeWidth = 10 / scale;
    canvas.drawPoints(ui.PointMode.points, <Offset>[Offset(0, 0)], paint);
    final width = 5 / scale;
    paint.strokeWidth = 1 / scale;

    final screenWidth = MediaQuery.of(context).size.width / baseScale;
    final screenHeight = MediaQuery.of(context).size.height / baseScale;

    // draw horizontal lines
    for (var i = translate.y > 0 ?  - (translate.y.toInt() ~/ screenHeight) : 1 + (-translate.y).toInt() ~/ screenHeight; i * screenHeight > -translate.y && i * screenHeight < -translate.y + screenHeight / scale; i++) {
      drawDash(canvas, paint, Offset(-translate.x, i * screenHeight), Offset(-translate.x + screenWidth / scale, i * screenHeight), width);
    }

    // draw vertical lines
    for (var i = translate.x > 0 ?  - (translate.x.toInt() ~/ screenWidth) : 1 + (-translate.x).toInt() ~/ screenWidth; i * screenWidth > -translate.x && i * screenWidth < -translate.x + screenWidth / scale; i++) {
      drawDash(canvas, paint, Offset(i * screenWidth, -translate.y), Offset(i * screenWidth, -translate.y + screenHeight / scale), width);
    }
  }

  final cropStrokes = <Stroke>[];
  final noCropStrokes = <LinkedList<Stroke>>[];

  var tmpStrokes = LinkedList<Stroke>();
  for (var stroke in strokes) {
    if (stroke.scratchMode == ScratchMode.crop) {
      cropStrokes.add(stroke);
      noCropStrokes.add(tmpStrokes);
      tmpStrokes = LinkedList<Stroke>();
    } else {
      tmpStrokes.add(stroke.clone());
    }
  }
  noCropStrokes.add(tmpStrokes);

  var index = 0;
  for (; index < cropStrokes.length; index++) {
    canvas.save();
    Point leftTopBorder, rightTopBorder;
    for (var i = index; i < cropStrokes.length; i++) {
      final cropStroke = cropStrokes[i];
      if (cropStroke.points.length != 2) continue;
      if (leftTopBorder == null) {
        leftTopBorder = Point(
          x: math.min(cropStroke.points.first.x, cropStroke.points.last.x),
          y: math.min(cropStroke.points.first.y, cropStroke.points.last.y),
        );
      } else {
        leftTopBorder = Point(
          x: math.min(rightTopBorder.x, math.max(leftTopBorder.x, math.min(cropStroke.points.first.x, cropStroke.points.last.x))),
          y: math.min(rightTopBorder.y, math.max(leftTopBorder.y, math.min(cropStroke.points.first.y, cropStroke.points.last.y))),
        );
      }
      if (rightTopBorder == null) {
        rightTopBorder = Point(
          x: math.max(cropStroke.points.first.x, cropStroke.points.last.x),
          y: math.max(cropStroke.points.first.y, cropStroke.points.last.y),
        );
      } else {
        rightTopBorder = Point(
          x: math.max(leftTopBorder.x, math.min(rightTopBorder.x, math.max(cropStroke.points.first.x, cropStroke.points.last.x))),
          y: math.max(leftTopBorder.y, math.min(rightTopBorder.y, math.max(cropStroke.points.first.y, cropStroke.points.last.y))),
        );
      }
    }
    if (leftTopBorder != null && rightTopBorder != null) {
      canvas.clipRect(Rect.fromPoints(Offset(leftTopBorder.x, leftTopBorder.y),
          Offset(rightTopBorder.x, rightTopBorder.y)));
    }
    if (index == 0) {
      if (image != null) {
        canvas.drawImage(image, offset, paint);
      }
    }
    for (var stroke in noCropStrokes[index]) {
      drawStroke(canvas, paint, stroke);
    }
    canvas.restore();
  }

  if (index == 0) {
    if (image != null) {
      canvas.drawImage(image, offset, paint);
    }
  }
  if (index < noCropStrokes.length) {
    for (var stroke in noCropStrokes[index]) {
      drawStroke(canvas, paint, stroke);
    }
  }

  if (currStroke != null) {
    if (currStroke.scratchMode == ScratchMode.crop && currStroke.points.length == 2) {
      paint.strokeWidth = 2 / baseScale;
      final width = 5 / scale;
      paint.color = scratchMode2Color(ScratchMode.crop);
      drawDash(canvas, paint, Offset(currStroke.points.first.x, currStroke.points.first.y), Offset(currStroke.points.first.x, currStroke.points.last.y), width);
      drawDash(canvas, paint, Offset(currStroke.points.first.x, currStroke.points.last.y), Offset(currStroke.points.last.x, currStroke.points.last.y), width);
      drawDash(canvas, paint, Offset(currStroke.points.last.x, currStroke.points.last.y), Offset(currStroke.points.last.x, currStroke.points.first.y), width);
      drawDash(canvas, paint, Offset(currStroke.points.last.x, currStroke.points.first.y), Offset(currStroke.points.first.x, currStroke.points.first.y), width);
    } else {
      drawStroke(canvas, paint, currStroke);
    }

    // 如果是多边形就标记一下
    if (!isExport && currStroke.scratchMode == ScratchMode.graphics &&
        currStroke.scratchGraphicsMode == ScratchGraphicsMode.polygon && currStroke.points.length > 0 &&
        strokes.length > 0 && strokes.last.points.length > 0) {
      for (var point in currStroke.points) {
        if (point.exists) {
          paint.color = Colors.grey;
          paint.strokeWidth = 2 / baseScale;
          canvas.drawCircle(Offset(point.x, point.y), PolygonDistanceMax, paint);
        }
      }
    }
  }

  if (scratchMode == ScratchMode.eraser && focalPoint != null) {
    paint.color = Colors.orange;
    canvas.drawPoints(ui.PointMode.points, <Offset>[Offset(
      focalPoint.x / scale - translate.x,
      focalPoint.y / scale - translate.y,
    )], paint);
  }
}

class ScratchPaperState extends State<ScratchPaper> {
  final maxStrokesLen = 10;
  final double minScale = 0.25 * baseScale;
  final double maxScale = 2 * baseScale;
  final LinkedList<Stroke> strokes = LinkedList<Stroke>();
  final LinkedList<Stroke> undoStrokes = LinkedList<Stroke>();
  bool isCheckingStrokes = false;
  ui.Image _image;
  Offset offset;
  Point lastPoint;
  Stroke currStroke;
  Point translate = Point(x: 0, y: 0);
  double scale = baseScale;
  double lastScale = 1;
  Offset _leftTopBorder, _rightBottomBorder;
  ScratchMode nextMode = ScratchMode.unknow;
  final ValueChanged<ScratchMode> modeChanged;

  ScratchPaperState({@required this.modeChanged});

  void backOrigin() {
    setState(() {
      scale = baseScale;
      translate = Point(x: 0, y: 0);
    });
  }

  void reset() {
    setState(() {
      strokes.clear();
      undoStrokes.clear();
      lastPoint = null;
      currStroke = null;
      lastScale = 1;
      _image = null;
      offset = null;
    });
  }

  bool undo() {
    if (strokes.length <= 0) {
      return false;
    }
    var lastStroke = strokes.last;
    strokes.remove(lastStroke);
    undoStrokes.add(lastStroke);
    setState(() {});
    return true;
  }

  bool redo() {
    if (undoStrokes.length <= 0) {
      return false;
    }
    var lastStroke = undoStrokes.last;
    undoStrokes.remove(lastStroke);
    strokes.add(lastStroke);
    setState(() {});
    return true;
  }

  set image(ui.Image img) {
    showAlertDialog(context, AppLocalizations.of(context).getLanguageText('importWillClear'), callback: () {
      setState(() {
        _image = img;
        translate = Point(x: 0, y: 0);
        strokes.clear();
        undoStrokes.clear();
        lastPoint = null;
        currStroke = null;
        lastScale = 1;

        final screenWidth = MediaQuery.of(context).size.width / baseScale;
        final screenHeight = MediaQuery.of(context).size.height / baseScale;

        if (img.width > screenWidth || img.height > screenHeight) {
          var scaleH = screenWidth / img.width * baseScale;
          var scaleV = screenHeight / img.height * baseScale;
          scale = scaleH < scaleV ? scaleH : scaleV;
          offset = Offset(
            (screenWidth / scale * baseScale - img.width) / 2,
            (screenHeight / scale * baseScale - img.height) / 2,
          );
        } else {
          scale = baseScale;
          offset = Offset(
            (screenWidth - img.width) / 2,
            (screenHeight - img.height) / 2,
          );
        }
      });
    });
  }

  Future<ui.Image> drawImage({bool belowMaxLen=false}) async {
    _leftTopBorder = null;
    _rightBottomBorder = null;
    if (_image != null) {
      _leftTopBorder = Offset(offset.dx, offset.dy);
      _rightBottomBorder = Offset(offset.dx + _image.width, offset.dy + _image.height);
    }
    LinkedList<Stroke> _strokes;
    if (belowMaxLen) {
      _strokes = LinkedList<Stroke>();
      for(var i=0;i<maxStrokesLen;i++) {
        _strokes.add(strokes.elementAt(i).clone());
      }
    } else {
      _strokes = strokes;
    }

    for (var stroke in _strokes) {
      if (stroke.scratchMode == ScratchMode.graphics && stroke.scratchGraphicsMode == ScratchGraphicsMode.circle) {
        if (stroke.points.length >= 2) {
          var circleCenter = stroke.points.elementAt(0);
          var radius = circleCenter.distanceTo(stroke.points.elementAt(1));
          var leftTopPoint = Offset(circleCenter.x - radius - stroke.lineWeight, circleCenter.y - radius - stroke.lineWeight);
          var rightBottomPoint = Offset(circleCenter.x + radius + stroke.lineWeight, circleCenter.y + radius + stroke.lineWeight);
          if (_leftTopBorder == null) {
            _leftTopBorder = leftTopPoint;
          } else {
            _leftTopBorder = Offset(math.min(_leftTopBorder.dx, leftTopPoint.dx), math.min(_leftTopBorder.dy, leftTopPoint.dy));
          }
          if (_rightBottomBorder == null) {
            _rightBottomBorder = rightBottomPoint;
          } else {
            _rightBottomBorder = Offset(math.max(_rightBottomBorder.dx, rightBottomPoint.dx), math.max(_rightBottomBorder.dy, rightBottomPoint.dy));
          }
        }
      } else if (stroke.scratchMode == ScratchMode.text) {
        if (stroke.points.length > 0) {
          var leftTopPoint = Offset(stroke.points.first.x - stroke.lineWeight,
              stroke.points.first.y - stroke.lineWeight);
          var rightBottomPoint = Offset(
              stroke.points.first.x + stroke.text.length * stroke.fontSize +
                  stroke.lineWeight,
              stroke.points.first.y + stroke.fontSize * 1.2 +
                  stroke.lineWeight);
          if (_leftTopBorder == null) {
            _leftTopBorder = leftTopPoint;
          } else {
            _leftTopBorder = Offset(math.min(_leftTopBorder.dx, leftTopPoint.dx), math.min(_leftTopBorder.dy, leftTopPoint.dy));
          }
          if (_rightBottomBorder == null) {
            _rightBottomBorder = rightBottomPoint;
          } else {
            _rightBottomBorder = Offset(math.max(_rightBottomBorder.dx, rightBottomPoint.dx), math.max(_rightBottomBorder.dy, rightBottomPoint.dy));
          }
        }
      } else if (stroke.scratchMode == ScratchMode.crop) {
        if (stroke.points.length == 2) {
          var leftTopPoint = Offset(stroke.points.first.x, stroke.points.first.y);
          var rightBottomPoint = Offset(stroke.points.last.x, stroke.points.last.y);
          if (_leftTopBorder == null) {
            _leftTopBorder = leftTopPoint;
          } else {
            _leftTopBorder = Offset(
              math.min(math.max(_leftTopBorder.dx, leftTopPoint.dx), _rightBottomBorder.dx),
              math.min(math.max(_leftTopBorder.dy, leftTopPoint.dy), _rightBottomBorder.dy),
            );
          }
          if (_rightBottomBorder == null) {
            _rightBottomBorder = rightBottomPoint;
          } else {
            _rightBottomBorder = Offset(
              math.max(math.min(_rightBottomBorder.dx, rightBottomPoint.dx), _leftTopBorder.dx),
              math.max(math.min(_rightBottomBorder.dy, rightBottomPoint.dy), _leftTopBorder.dy),
            );
          }
        }
      } else {
        for (var point in stroke.points) {
          var leftTopPoint = Offset(point.x - stroke.lineWeight, point.y - stroke.lineWeight);
          var rightBottomPoint = Offset(point.x + stroke.lineWeight, point.y + stroke.lineWeight);
          if (_leftTopBorder == null) {
            _leftTopBorder = leftTopPoint;
          } else {
            _leftTopBorder = Offset(math.min(_leftTopBorder.dx, leftTopPoint.dx), math.min(_leftTopBorder.dy, leftTopPoint.dy));
          }
          if (_rightBottomBorder == null) {
            _rightBottomBorder = rightBottomPoint;
          } else {
            _rightBottomBorder = Offset(math.max(_rightBottomBorder.dx, rightBottomPoint.dx), math.max(_rightBottomBorder.dy, rightBottomPoint.dy));
          }
        }
      }
    }
    final recorder = ui.PictureRecorder();
    var translate = Point(x: -_leftTopBorder.dx, y: -_leftTopBorder.dy);
    var leftTopPoint = Offset(0, 0);
    var rightBottomPoint = Offset(_rightBottomBorder.dx - _leftTopBorder.dx, _rightBottomBorder.dy - _leftTopBorder.dy);
    final canvas = Canvas(recorder, Rect.fromPoints(leftTopPoint, rightBottomPoint));
    var paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    canvas.drawRect(Rect.fromLTRB(0, 0, rightBottomPoint.dx, rightBottomPoint.dy), paint);
    paintCanvas(context, canvas, 1, translate, _image, offset, _strokes, null, ScratchMode.edit, null, isExport: true);
    final picture = recorder.endRecording();
    return await picture.toImage(rightBottomPoint.dx.toInt(), rightBottomPoint.dy.toInt());
  }

  Future<String> export() async {
    if (_image == null && strokes.length <= 0) {
      showErrorToast(AppLocalizations.of(context).getLanguageText('cantShareEmpty'));
      return "";
    }
    Map<PermissionGroup, PermissionStatus> permissions = await PermissionHandler().requestPermissions([PermissionGroup.storage]);
    if (permissions[PermissionGroup.storage] != PermissionStatus.granted) {
      return "";
    }
    final img = await drawImage();
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final externalDir = await getExternalStorageDirectory();
    final imageFilePath = path.join(externalDir.absolute.path, "scratch_paper_export.png");
    final imageFile = File(imageFilePath);
    await imageFile.writeAsBytes(pngBytes.buffer.asInt8List(), mode: FileMode.writeOnly, flush: true);
    return imageFilePath;
  }

  void saveGallery() async {
    if (_image == null && strokes.length <= 0) {
      showErrorToast(AppLocalizations.of(context).getLanguageText('contentEmpty'));
      return;
    }
    Map<PermissionGroup, PermissionStatus> permissions = await PermissionHandler().requestPermissions([PermissionGroup.storage]);
    if (permissions[PermissionGroup.storage] != PermissionStatus.granted) {
      return;
    }
    var img = await drawImage();
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    await ImageGallerySaver.saveImage(pngBytes.buffer.asUint8List());
    showSuccessToast(AppLocalizations.of(context).getLanguageText('saveSuccess'));
  }

  void _checkStrokes() async {
    if (strokes.length < 2 * maxStrokesLen) return;
    if (isCheckingStrokes) return;
    isCheckingStrokes = true;
    _image = await drawImage(belowMaxLen: true);
    offset = _leftTopBorder;
    for (var i=0;i<maxStrokesLen;i++) {
      strokes.remove(strokes.first);
    }
    isCheckingStrokes = false;
  }

  void addText(Offset loca, String text, double fontSize) {
    strokes.add(Stroke(
      scratchMode: widget.scratchMode,
      scratchGraphicsMode: widget.scratchGraphicsMode,
      points: LinkedList<Point>()..add(Point(
        x: -translate.x + loca.dx / scale,
        y: -translate.y + loca.dy / scale,
      )),
      color: widget.selectedColor,
      lineWeight: widget.selectedLineWeight,
      text: text,
      fontSize: fontSize / baseScale,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: GestureDetector(
        onScaleStart: (details) {
          lastScale = 1;
          lastPoint = Point(x: details.localFocalPoint.dx, y: details.localFocalPoint.dy);
          switch (widget.scratchMode) {
            case ScratchMode.unknow:
              break;
            case ScratchMode.eraser:
              currStroke = Stroke(
                scratchMode: widget.scratchMode,
                scratchGraphicsMode: widget.scratchGraphicsMode,
                points: LinkedList<Point>()..add(Point(
                  x: -translate.x + details.localFocalPoint.dx / scale,
                  y: -translate.y + details.localFocalPoint.dy / scale,
                )),
                color: Colors.white,
                lineWeight: widget.selectedLineWeight / baseScale,
              );
              break;
            case ScratchMode.edit:
            case ScratchMode.graphics:
            case ScratchMode.crop:
              switch (widget.scratchGraphicsMode) {
                case ScratchGraphicsMode.polygon:
                  var currPoint = Point(
                    x: -translate.x + details.localFocalPoint.dx / scale,
                    y: -translate.y + details.localFocalPoint.dy / scale,
                  );
                  double radius = PolygonDistanceMax;
                  var selectedPoint = currPoint;
                  for (var stroke in strokes) {
                    if (stroke.scratchMode == ScratchMode.edit || stroke.scratchMode == ScratchMode.graphics) {
                      for (var point in stroke.points) {
                        var theRadius = currPoint.distanceTo(point);
                        if (radius > theRadius) {
                          radius = theRadius;
                          selectedPoint = point.clone(exists: true);
                        }
                      }
                    }
                  }
                  currStroke = Stroke(
                    scratchMode: widget.scratchMode,
                    scratchGraphicsMode: widget.scratchGraphicsMode,
                    points: LinkedList<Point>()..add(selectedPoint),
                    color: widget.selectedColor,
                    lineWeight: widget.selectedLineWeight,
                  );
                  break;
                default:
                  currStroke = Stroke(
                    scratchMode: widget.scratchMode,
                    scratchGraphicsMode: widget.scratchGraphicsMode,
                    points: LinkedList<Point>()..add(Point(
                      x: -translate.x + details.localFocalPoint.dx / scale,
                      y: -translate.y + details.localFocalPoint.dy / scale,
                    )),
                    color: widget.selectedColor,
                    lineWeight: widget.selectedLineWeight,
                  );
                  break;
              }
              break;
            case ScratchMode.move:
              break;
            case ScratchMode.text:
              break;
          }
        },
        onScaleUpdate: (details) {
          if (widget.scratchMode != ScratchMode.move && details.scale != 1) {
            nextMode = widget.scratchMode;
            currStroke.scratchMode = ScratchMode.move;
            modeChanged(ScratchMode.move);
            return;
          }
          switch (widget.scratchMode) {
            case ScratchMode.unknow:
              break;
            case ScratchMode.eraser:
            case ScratchMode.edit:
              currStroke.points.add(Point(x: -translate.x + details.localFocalPoint.dx / scale, y: -translate.y + details.localFocalPoint.dy / scale));
              lastPoint = Point(x: details.localFocalPoint.dx, y: details.localFocalPoint.dy);
              setState(() {});
              break;
            case ScratchMode.move:
              var factor = details.scale / lastScale;
              if (scale * factor < minScale) {
                factor = 1;
                scale = minScale;
              } else if (scale * factor > maxScale) {
                factor = 1;
                scale = maxScale;
              } else {
                scale = scale * factor;
              }
              lastScale = details.scale;

              var currPoint = Point(x: details.localFocalPoint.dx, y: details.localFocalPoint.dy);
              translate = Point(
                x: translate.x + (currPoint.x - lastPoint.x) / scale - details.localFocalPoint.dx * (factor - 1) / scale,
                y: translate.y + (currPoint.y - lastPoint.y) / scale - details.localFocalPoint.dy * (factor - 1) / scale,
              );
              lastPoint = currPoint;
              setState(() {});
              break;
            case ScratchMode.graphics:
            case ScratchMode.crop:
              var currPoint = Point(x: -translate.x + details.localFocalPoint.dx / scale, y: -translate.y + details.localFocalPoint.dy / scale);

              // 多边形特殊逻辑
              if (widget.scratchGraphicsMode == ScratchGraphicsMode.polygon) {
                double radius = PolygonDistanceMax;
                var selectedPoint = currPoint;
                for (var stroke in strokes) {
                  if (stroke.scratchMode == ScratchMode.edit || stroke.scratchMode == ScratchMode.graphics) {
                    for (var point in stroke.points) {
                      var theRadius = currPoint.distanceTo(point);
                      if (radius > theRadius) {
                        radius = theRadius;
                        selectedPoint = point.clone(exists: true);
                      }
                    }
                  }
                }
                currPoint = selectedPoint;
              }

              while (currStroke.points.length > 1) {
                currStroke.points.remove(currStroke.points.last);
              }
              currStroke.points.add(currPoint);
              setState(() {});
              lastPoint = currPoint;
              break;
            case ScratchMode.text:
              break;
          }
        },
        onScaleEnd: (details) {
          switch (widget.scratchMode) {
            case ScratchMode.unknow:
              break;
            case ScratchMode.eraser:
            case ScratchMode.edit:
            case ScratchMode.graphics:
            case ScratchMode.crop:
              strokes.add(currStroke);
              undoStrokes.clear();
              _checkStrokes();
              break;
            case ScratchMode.move:
              break;
            case ScratchMode.text:
              break;
          }
          currStroke = null;
          lastPoint = null;
          setState(() {});
          if (nextMode != ScratchMode.unknow) {
            modeChanged(nextMode);
            nextMode = ScratchMode.unknow;
          }
        },
        child: CustomPaint(
          painter: ScratchPainter(
            context: context,
            scratchMode: widget.scratchMode,
            image: _image,
            offset: offset,
            strokes: strokes,
            currStroke: currStroke,
            translate: translate,
            scale: scale,
            focalPoint: lastPoint,
          ),
        ),
      ),
    );
  }
}

class Point extends LinkedListEntry<Point> {
  final double x, y;
  final bool exists;

  Point({@required this.x, @required this.y, this.exists = false});

  double distanceTo(Point p2) {
    return math.sqrt(math.pow(x - p2.x, 2) + math.pow(y - p2.y, 2));
  }

  Point clone({bool exists = false}) {
    return Point(x: x, y: y, exists: exists);
  }
}

class Stroke extends LinkedListEntry<Stroke> {
  ScratchMode scratchMode;
  final ScratchGraphicsMode scratchGraphicsMode;
  final LinkedList<Point> points;
  final Color color;
  final double lineWeight;
  final String text;
  final double fontSize;

  Stroke({
    @required this.scratchMode,
    @required this.scratchGraphicsMode,
    @required this.points,
    @required this.color,
    @required this.lineWeight,
    this.text = "",
    this.fontSize = 12.0,
  });

  Stroke clone() {
    return Stroke(
      scratchMode: scratchMode,
      scratchGraphicsMode: scratchGraphicsMode,
      points: this.points,
      color: this.color,
      lineWeight: this.lineWeight,
      text: this.text,
      fontSize: this.fontSize,
    );
  }
}

class ScratchPainter extends CustomPainter {
  final BuildContext context;
  final ScratchMode scratchMode;
  final ui.Image image;
  final Offset offset;
  final LinkedList<Stroke> strokes;
  final Stroke currStroke;
  final Point translate;
  final double scale;
  final Point focalPoint;

  ScratchPainter({
    @required this.context,
    @required this.scratchMode,
    @required this.image,
    @required this.offset,
    @required this.strokes,
    @required this.currStroke,
    @required this.translate,
    @required this.scale,
    @required this.focalPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintCanvas(context, canvas, scale, translate, image, offset, strokes, currStroke, scratchMode, focalPoint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
