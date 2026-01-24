import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerHelper {
  /// Create a custom person marker icon
  static Future<BitmapDescriptor> createPersonMarker({
    Color color = Colors.blue,
    double size = 100,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Draw person icon with a pin shape
    final Paint pinPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final Paint strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Draw pin background (teardrop shape)
    final Path pinPath = Path();
    final double pinWidth = size * 0.6;
    final double pinHeight = size * 0.8;
    final double centerX = size / 2;
    final double topY = size * 0.1;
    
    // Create teardrop/pin shape
    pinPath.addOval(Rect.fromCircle(
      center: Offset(centerX, topY + pinWidth / 2),
      radius: pinWidth / 2,
    ));
    
    // Add point at bottom
    pinPath.moveTo(centerX - pinWidth * 0.3, topY + pinWidth * 0.8);
    pinPath.lineTo(centerX, topY + pinHeight);
    pinPath.lineTo(centerX + pinWidth * 0.3, topY + pinWidth * 0.8);
    
    canvas.drawPath(pinPath, pinPaint);
    canvas.drawPath(pinPath, strokePaint);
    
    // Draw person icon inside the pin
    final double personSize = pinWidth * 0.5;
    final double personCenterX = centerX;
    final double personCenterY = topY + pinWidth / 2;
    
    final Paint personPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Draw head
    canvas.drawCircle(
      Offset(personCenterX, personCenterY - personSize * 0.15),
      personSize * 0.2,
      personPaint,
    );
    
    // Draw body (simple rectangle with rounded corners)
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(personCenterX, personCenterY + personSize * 0.15),
        width: personSize * 0.4,
        height: personSize * 0.5,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(body, personPaint);
    
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
}
