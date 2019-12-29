import 'dart:collection';

import 'package:flutter/material.dart';

class ScratchPaper extends StatefulWidget {
  ScratchPaper({Key key}): super(key: key);

  @override
  _ScratchPaperState createState() => _ScratchPaperState();
}

class _ScratchPaperState extends State<ScratchPaper> {
  LinkedList<Stroke> strokes = LinkedList<Stroke>();
  Offset lastPoint = Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: GestureDetector(
        onPanStart: (DragStartDetails details) {
          lastPoint = Offset(details.localPosition.dx, details.localPosition.dy);
        },
        onPanUpdate: (DragUpdateDetails details) {
          var currPoint = Offset(details.localPosition.dx, details.localPosition.dy);
          strokes.addFirst(Stroke(from: lastPoint, to: currPoint, color: Colors.black, width: 1));
          lastPoint = currPoint;
          setState(() {

          });
        },
        child: CustomPaint(
          painter: ScratchPainter(
            strokes: strokes,
          ),
        ),
      ),
    );
  }
}

class Stroke extends LinkedListEntry<Stroke> {
  final Offset from, to;
  final Color color;
  final int width;

  Stroke({@required this.from, @required this.to, @required this.color, @required this.width});
}

class ScratchPainter extends CustomPainter {
  final LinkedList<Stroke> strokes;

  ScratchPainter({@required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (var stroke in strokes) {
      paint.color = stroke.color;
      paint.strokeWidth = stroke.width.toDouble();
      canvas.drawLine(stroke.from, stroke.to, paint);
      canvas.save();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
