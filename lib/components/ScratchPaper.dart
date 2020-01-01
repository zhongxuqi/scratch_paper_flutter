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

  ScratchPaper({Key key, @required this.scratchMode}): super(key: key);

  @override
  _ScratchPaperState createState() => _ScratchPaperState();
}

class _ScratchPaperState extends State<ScratchPaper> {
  final LinkedList<Stroke> strokes = LinkedList<Stroke>();
  Point lastPoint;
  Stroke currStroke;
  Color color = Colors.black;
  double width = 5;
  Point translate = Point(x: 0, y: 0);
  double scale = 1;
  double lastScale = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: GestureDetector(
        onScaleStart: (details) {
          switch (widget.scratchMode) {
            case ScratchMode.eraser:
            case ScratchMode.edit:
              currStroke = Stroke(points: LinkedList<Point>()
                ..add(Point(x: -translate.x + details.localFocalPoint.dx / scale, y: -translate.y + details.localFocalPoint.dy / scale)), color: color, width: width);
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
              currStroke = null;
              setState(() {});
              break;
            case ScratchMode.move:
              break;
          }
        },
        child: CustomPaint(
          painter: ScratchPainter(
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
  final double width;

  Stroke({@required this.points, @required this.color, @required this.width});
}

class ScratchPainter extends CustomPainter {
  final LinkedList<Stroke> strokes;
  final Stroke currStroke;
  final Point translate;
  final double scale;
  final Point focalPoint;

  ScratchPainter({@required this.strokes, @required this.currStroke, @required this.translate, @required this.scale, @required this.focalPoint});

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
      var path = Path()
        ..fillType = PathFillType.evenOdd;
      paint.color = stroke.color;
      paint.strokeWidth = stroke.width.toDouble();
      for (var i=0;i<stroke.points.length;i++) {
        if (i == 0) {
          path.moveTo(stroke.points.elementAt(i).x, stroke.points.elementAt(i).y);
        } else {
          path.lineTo(stroke.points.elementAt(i).x, stroke.points.elementAt(i).y);
        }
      }
      canvas.drawPath(path, paint);
    }
    if (currStroke != null) {
      var path = Path();
      paint.color = currStroke.color;
      paint.strokeWidth = currStroke.width.toDouble();
      for (var i=0;i<currStroke.points.length;i++) {
        if (i == 0) {
          path.moveTo(currStroke.points.elementAt(i).x, currStroke.points.elementAt(i).y);
        } else {
          path.lineTo(currStroke.points.elementAt(i).x, currStroke.points.elementAt(i).y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
