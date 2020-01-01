import 'package:flutter/material.dart';

class LineWeightPicker extends StatelessWidget {
  final List<double> lineWeights;
  final Color selectedColor;
  final double lineWeight;
  final ValueChanged<double> onValue;

  LineWeightPicker({Key key, @required this.selectedColor, @required this.lineWeight, @required this.lineWeights, @required this.onValue}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: lineWeights.map((item) {
          return Container(
            color: item==lineWeight?Colors.grey[200]:Colors.transparent,
            child: InkWell(
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.all(24),
                      padding: EdgeInsets.all(10),
                      height: item,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                if (onValue != null) {
                  onValue(item);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}