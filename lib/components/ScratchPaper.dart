import 'dart:collection';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scratch_paper_flutter/utils/iconfonts.dart';
import '../utils/language.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'alert.dart';
import 'Toast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

enum ScratchMode {
  edit,
  move,
  eraser,
}

IconData ScratchMode2Icon(ScratchMode mode) {
  switch (mode) {
    case ScratchMode.edit:
      return IconFonts.edit;
    case ScratchMode.move:
      return IconFonts.move;
    case ScratchMode.eraser:
      return IconFonts.eraser;
  }
  return null;
}

String ScratchMode2Desc(BuildContext context, ScratchMode mode) {
  switch (mode) {
    case ScratchMode.edit:
      return AppLocalizations.of(context).getLanguageText('edit');
    case ScratchMode.move:
      return AppLocalizations.of(context).getLanguageText('move');
    case ScratchMode.eraser:
      return AppLocalizations.of(context).getLanguageText('eraser');
  }
  return null;
}

Color ScratchMode2Color(ScratchMode mode) {
  switch (mode) {
    case ScratchMode.edit:
      return Colors.green;
    case ScratchMode.move:
      return Colors.blue;
    case ScratchMode.eraser:
      return Colors.orange;
  }
  return null;
}

class ScratchPaper extends StatefulWidget {
  final ScratchMode scratchMode;
  final Color selectedColor;
  final double selectedLineWeight;

  ScratchPaper({Key key, @required this.scratchMode, @required this.selectedColor, @required this.selectedLineWeight}): super(key: key);

  @override
  ScratchPaperState createState() => ScratchPaperState();
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
  var path = Path()
    ..fillType = PathFillType.evenOdd;
  paint.color = stroke.color;
  paint.strokeWidth = stroke.lineWeight.toDouble();

  for (var i=0;i<stroke.points.length;i++) {
    if (i == 0) {
      path.moveTo(stroke.points.elementAt(i).x, stroke.points.elementAt(i).y);
    } else {
      path.lineTo(stroke.points.elementAt(i).x, stroke.points.elementAt(i).y);
    }
  }
  canvas.drawPath(path, paint);
}

void paintCanvas(BuildContext context, Canvas canvas, double scale, Point translate, ui.Image image, Offset offset, LinkedList<Stroke> strokes, Stroke currStroke, ScratchMode scratchMode, Point focalPoint, {bool disableClipRect = false}) {
  canvas.scale(scale);
  canvas.translate(translate.x, translate.y);
  if (!disableClipRect) {
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

  void set image(ui.Image img) {
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
      for (var point in stroke.points) {
        if (_leftTopBorder == null) {
          _leftTopBorder = Offset(point.x - stroke.lineWeight, point.y - stroke.lineWeight);
        } else if (_leftTopBorder.dx > point.x - stroke.lineWeight || _leftTopBorder.dy > point.y - stroke.lineWeight) {
          _leftTopBorder = Offset(
            _leftTopBorder.dx > point.x - stroke.lineWeight?point.x - stroke.lineWeight:_leftTopBorder.dx,
            _leftTopBorder.dy > point.y - stroke.lineWeight?point.y - stroke.lineWeight:_leftTopBorder.dy,
          );
        }
        if (_rightBottomBorder == null) {
          _rightBottomBorder = Offset(point.x + stroke.lineWeight, point.y + stroke.lineWeight);
        } else if (_rightBottomBorder.dx < point.x + stroke.lineWeight || _rightBottomBorder.dy < point.y + stroke.lineWeight) {
          _rightBottomBorder = Offset(
            _rightBottomBorder.dx < point.x + stroke.lineWeight?point.x + stroke.lineWeight:_rightBottomBorder.dx,
            _rightBottomBorder.dy < point.y + stroke.lineWeight?point.y + stroke.lineWeight:_rightBottomBorder.dy,
          );
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
    paintCanvas(context, canvas, 1, translate, _image, offset, _strokes, null, ScratchMode.edit, null, disableClipRect: true);
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
          switch (widget.scratchMode) {
            case ScratchMode.eraser:
              currStroke = Stroke(
                points: LinkedList<Point>()..add(Point(
                  x: -translate.x + details.localFocalPoint.dx / scale,
                  y: -translate.y + details.localFocalPoint.dy / scale,
                )),
                color: Colors.white,
                lineWeight: widget.selectedLineWeight,
              );
              lastPoint = Point(x: details.localFocalPoint.dx, y: details.localFocalPoint.dy);
              break;
            case ScratchMode.edit:
              currStroke = Stroke(
                points: LinkedList<Point>()..add(Point(
                  x: -translate.x + details.localFocalPoint.dx / scale,
                  y: -translate.y + details.localFocalPoint.dy / scale,
                )),
                color: widget.selectedColor,
                lineWeight: widget.selectedLineWeight,
              );
              break;
            case ScratchMode.move:
              lastPoint = Point(x: details.localFocalPoint.dx, y: details.localFocalPoint.dy);
              lastScale = 1;
              break;
          }
        },
        onScaleUpdate: (details) {
          switch (widget.scratchMode) {
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
          }
        },
        onScaleEnd: (details) {
          switch (widget.scratchMode) {
            case ScratchMode.eraser:
            case ScratchMode.edit:
              strokes.add(currStroke);
              undoStrokes.clear();
              currStroke = null;
              lastPoint = null;
              setState(() {});
              _checkStrokes();
              break;
            case ScratchMode.move:
              break;
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

  Point({@required this.x, @required this.y});
}

class Stroke extends LinkedListEntry<Stroke> {
  final LinkedList<Point> points;
  final Color color;
  final double lineWeight;

  Stroke({@required this.points, @required this.color, @required this.lineWeight});

  Stroke clone() {
    return Stroke(
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
