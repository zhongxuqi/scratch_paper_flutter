import 'dart:collection';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scratch_paper_flutter/utils/iconfonts.dart';
import '../utils/language.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'alertDialog.dart';
import 'Toast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

const double PolygonDistanceMax = 20;

enum ScratchMode {
  unknow,
  edit,
  move,
  eraser,
  graphics,
  text,
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

    paint.strokeWidth = 1 / scale;
    final width = 5 / scale;

    // draw horizontal lines
    for (var i = translate.y > 0 ?  - (translate.y.toInt() ~/ MediaQuery.of(context).size.height) : 1 + (-translate.y).toInt() ~/ MediaQuery.of(context).size.height; i * MediaQuery.of(context).size.height > -translate.y && i * MediaQuery.of(context).size.height < -translate.y + MediaQuery.of(context).size.height / scale; i++) {
      drawDash(canvas, paint, Offset(-translate.x, i * MediaQuery.of(context).size.height), Offset(-translate.x + MediaQuery.of(context).size.width / scale, i * MediaQuery.of(context).size.height), width);
    }

    // draw vertical lines
    for (var i = translate.x > 0 ?  - (translate.x.toInt() ~/ MediaQuery.of(context).size.width) : 1 + (-translate.x).toInt() ~/ MediaQuery.of(context).size.width; i * MediaQuery.of(context).size.width > -translate.x && i * MediaQuery.of(context).size.width < -translate.x + MediaQuery.of(context).size.width / scale; i++) {
      drawDash(canvas, paint, Offset(i * MediaQuery.of(context).size.width, -translate.y), Offset(i * MediaQuery.of(context).size.width, -translate.y + MediaQuery.of(context).size.height / scale), width);
    }
  }

  if (image != null) {
    canvas.drawImage(image, offset, paint);
  }

  for (var stroke in strokes) {
    drawStroke(canvas, paint, stroke);
  }

  if (currStroke != null) {
    drawStroke(canvas, paint, currStroke);

    // 如果是多边形就标记一下
    if (!isExport && currStroke.scratchMode == ScratchMode.graphics &&
        currStroke.scratchGraphicsMode == ScratchGraphicsMode.polygon && currStroke.points.length > 0 &&
        strokes.length > 0 && strokes.last.points.length > 0) {
      for (var point in currStroke.points) {
        if (point.exists) {
          paint.color = Colors.grey;
          paint.strokeWidth = 2;
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
  final double minScale = 0.1;
  final double maxScale = 2;
  final LinkedList<Stroke> strokes = LinkedList<Stroke>();
  final LinkedList<Stroke> undoStrokes = LinkedList<Stroke>();
  bool isCheckingStrokes = false;
  ui.Image _image;
  Offset offset;
  Point lastPoint;
  Stroke currStroke;
  Point translate = Point(x: 0, y: 0);
  double scale = 1;
  double lastScale = 1;
  Offset _leftTopBorder, _rightBottomBorder;
  ScratchMode nextMode = ScratchMode.unknow;
  final ValueChanged<ScratchMode> modeChanged;

  ScratchPaperState({@required this.modeChanged});

  void backOrigin() {
    setState(() {
      scale = 1;
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

        if (img.width > MediaQuery.of(context).size.width || img.height > MediaQuery.of(context).size.height) {
          var scaleH = MediaQuery.of(context).size.width / img.width;
          var scaleV = MediaQuery.of(context).size.height / img.height;
          scale = scaleH < scaleV ? scaleH : scaleV;
          offset = Offset(
            (MediaQuery.of(context).size.width / scale - img.width) / 2,
            (MediaQuery.of(context).size.height / scale - img.height) / 2,
          );
        } else {
          scale = 1;
          offset = Offset(
            (MediaQuery.of(context).size.width - img.width) / 2,
            (MediaQuery.of(context).size.height - img.height) / 2,
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
      if (stroke.scratchMode != ScratchMode.graphics || stroke.scratchGraphicsMode != ScratchGraphicsMode.circle) {
        for (var point in stroke.points) {
          if (_leftTopBorder == null) {
            _leftTopBorder = Offset(
                point.x - stroke.lineWeight, point.y - stroke.lineWeight);
          } else if (_leftTopBorder.dx > point.x - stroke.lineWeight ||
              _leftTopBorder.dy > point.y - stroke.lineWeight) {
            _leftTopBorder = Offset(
              _leftTopBorder.dx > point.x - stroke.lineWeight ? point.x -
                  stroke.lineWeight : _leftTopBorder.dx,
              _leftTopBorder.dy > point.y - stroke.lineWeight ? point.y -
                  stroke.lineWeight : _leftTopBorder.dy,
            );
          }
          if (_rightBottomBorder == null) {
            _rightBottomBorder = Offset(
                point.x + stroke.lineWeight, point.y + stroke.lineWeight);
          } else if (_rightBottomBorder.dx < point.x + stroke.lineWeight ||
              _rightBottomBorder.dy < point.y + stroke.lineWeight) {
            _rightBottomBorder = Offset(
              _rightBottomBorder.dx < point.x + stroke.lineWeight ? point.x +
                  stroke.lineWeight : _rightBottomBorder.dx,
              _rightBottomBorder.dy < point.y + stroke.lineWeight ? point.y +
                  stroke.lineWeight : _rightBottomBorder.dy,
            );
          }
        }
      } else {
        if (stroke.points.length >= 2) {
          var circleCenter = stroke.points.elementAt(0);
          var radius = circleCenter.distanceTo(stroke.points.elementAt(1));
          if (_leftTopBorder == null) {
            _leftTopBorder = Offset(
                circleCenter.x - radius - stroke.lineWeight, circleCenter.y - radius - stroke.lineWeight);
          } else if (_leftTopBorder.dx > circleCenter.x - radius - stroke.lineWeight ||
              _leftTopBorder.dy > circleCenter.y - radius - stroke.lineWeight) {
            _leftTopBorder = Offset(
              _leftTopBorder.dx > circleCenter.x - radius - stroke.lineWeight ? circleCenter.x - radius -
                  stroke.lineWeight : _leftTopBorder.dx,
              _leftTopBorder.dy > circleCenter.y - radius - stroke.lineWeight ? circleCenter.y - radius -
                  stroke.lineWeight : _leftTopBorder.dy,
            );
          }
          if (_rightBottomBorder == null) {
            _rightBottomBorder = Offset(
                circleCenter.x + radius + stroke.lineWeight, circleCenter.y + radius + stroke.lineWeight);
          } else if (_rightBottomBorder.dx < circleCenter.x + radius + stroke.lineWeight ||
              _rightBottomBorder.dy < circleCenter.y + radius + stroke.lineWeight) {
            _rightBottomBorder = Offset(
              _rightBottomBorder.dx < circleCenter.x + radius + stroke.lineWeight ? circleCenter.x + radius +
                  stroke.lineWeight : _rightBottomBorder.dx,
              _rightBottomBorder.dy < circleCenter.y + radius + stroke.lineWeight ? circleCenter.y + radius +
                  stroke.lineWeight : _rightBottomBorder.dy,
            );
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
                lineWeight: widget.selectedLineWeight,
              );
              break;
            case ScratchMode.edit:
            case ScratchMode.graphics:
              switch (widget.scratchGraphicsMode) {
                case ScratchGraphicsMode.polygon:
                  var currPoint = Point(
                    x: -translate.x + details.localFocalPoint.dx / scale,
                    y: -translate.y + details.localFocalPoint.dy / scale,
                  );
                  double radius = PolygonDistanceMax;
                  var selectedPoint = currPoint;
                  for (var stroke in strokes) {
                    for (var point in stroke.points) {
                      var theRadius = currPoint.distanceTo(point);
                      if (radius > theRadius) {
                        radius = theRadius;
                        selectedPoint = point.clone(exists: true);
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
          }
        },
        onScaleUpdate: (details) {
          switch (widget.scratchMode) {
            case ScratchMode.unknow:
              break;
            case ScratchMode.eraser:
            case ScratchMode.edit:
              if (details.scale != 1) {
                nextMode = widget.scratchMode;
                modeChanged(ScratchMode.move);
                break;
              }
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
              var currPoint = Point(x: -translate.x + details.localFocalPoint.dx / scale, y: -translate.y + details.localFocalPoint.dy / scale);

              // 多边形特殊逻辑
              if (widget.scratchGraphicsMode == ScratchGraphicsMode.polygon) {
                double radius = PolygonDistanceMax;
                var selectedPoint = currPoint;
                for (var stroke in strokes) {
                  for (var point in stroke.points) {
                    var theRadius = currPoint.distanceTo(point);
                    if (radius > theRadius) {
                      radius = theRadius;
                      selectedPoint = point.clone(exists: true);
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
          }
        },
        onScaleEnd: (details) {
          switch (widget.scratchMode) {
            case ScratchMode.unknow:
              break;
            case ScratchMode.eraser:
            case ScratchMode.edit:
            case ScratchMode.graphics:
              strokes.add(currStroke);
              undoStrokes.clear();
              _checkStrokes();
              break;
            case ScratchMode.move:
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
  final ScratchMode scratchMode;
  final ScratchGraphicsMode scratchGraphicsMode;
  final LinkedList<Point> points;
  final Color color;
  final double lineWeight;

  Stroke({@required this.scratchMode, @required this.scratchGraphicsMode, @required this.points, @required this.color, @required this.lineWeight});

  Stroke clone() {
    return Stroke(
      scratchMode: scratchMode,
      scratchGraphicsMode: scratchGraphicsMode,
      points: this.points,
      color: this.color,
      lineWeight: this.lineWeight,
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
