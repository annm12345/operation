// TODO Implement this library.import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SelectionBox extends StatefulWidget {
  final Function(LatLngBounds) onSelect;

  SelectionBox({required this.onSelect});

  @override
  _SelectionBoxState createState() => _SelectionBoxState();
}

class _SelectionBoxState extends State<SelectionBox> {
  LatLng? _startPoint;
  LatLng? _endPoint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        final point = _getLatLngFromDetails(details as DragUpdateDetails);
        setState(() {
          _startPoint = point;
        });
      },
      onPanUpdate: (details) {
        final point = _getLatLngFromDetails(details);
        setState(() {
          _endPoint = point;
        });
      },
      onPanEnd: (details) {
        if (_startPoint != null && _endPoint != null) {
          final bounds = LatLngBounds(_startPoint!, _endPoint!);
          widget.onSelect(bounds);
        }
        setState(() {
          _startPoint = null;
          _endPoint = null;
        });
      },
      child: CustomPaint(
        painter: _SelectionBoxPainter(_startPoint, _endPoint),
      ),
    );
  }

  LatLng _getLatLngFromDetails(DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.globalToLocal(details.globalPosition);
    final point =
        MapState.instance!.pointToLatLng(CustomPoint(offset.dx, offset.dy));
    return point!;
  }
}

class _SelectionBoxPainter extends CustomPainter {
  final LatLng? startPoint;
  final LatLng? endPoint;

  _SelectionBoxPainter(this.startPoint, this.endPoint);

  @override
  void paint(Canvas canvas, Size size) {
    if (startPoint == null || endPoint == null) return;

    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromPoints(
      Offset(startPoint!.latitude, startPoint!.longitude),
      Offset(endPoint!.latitude, endPoint!.longitude),
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
