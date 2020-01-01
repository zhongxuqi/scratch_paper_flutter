import 'dart:collection';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:scratch_paper_flutter/utils/iconfonts.dart';
import '../utils/languange.dart';

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

class ScratchPaperState extends State<ScratchPaper> {
  final LinkedList<Stroke> strokes = LinkedList<Stroke>();
  final LinkedList<Stroke> undoStrokes = LinkedList<Stroke>();
  Point lastPoint;
  Stroke currStroke;
  Point translate = Point(x: 0, y: 0);
  double scale = 1;
  double lastScale = 1;

  void backOrigin() {
    setState(() {
      scale = 1;
      translate = Point(x: 0, y: 0);
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
              scale = scale * factor;
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
              break;
            case ScratchMode.move:
              break;
          }
        },
        child: CustomPaint(
          painter: ScratchPainter(
            scratchMode: widget.scratchMode,
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
}

class ScratchPainter extends CustomPainter {
  final ScratchMode scratchMode;
  final LinkedList<Stroke> strokes;
  final Stroke currStroke;
  final Point translate;
  final double scale;
  final Point focalPoint;

  ScratchPainter({@required this.scratchMode, @required this.strokes, @required this.currStroke, @required this.translate, @required this.scale, @required this.focalPoint});

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

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    canvas.translate(translate.x, translate.y);
    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var stroke in strokes) {
      drawStroke(canvas, paint, stroke);
    }
    if (currStroke != null) {
      drawStroke(canvas, paint, currStroke);
    }

    if (scratchMode == ScratchMode.eraser && focalPoint != null) {
      paint.color = Colors.orange;
      canvas.drawPoints(PointMode.points, <Offset>[Offset(
        focalPoint.x / scale - translate.x,
        focalPoint.y / scale - translate.y,
      )], paint);
    }

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
