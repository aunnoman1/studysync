import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DiagramEditorPage extends StatefulWidget {
  final Uint8List imageBytes;
  final List<Rect> initialRects;

  const DiagramEditorPage({
    super.key,
    required this.imageBytes,
    this.initialRects = const [],
  });

  @override
  State<DiagramEditorPage> createState() => _DiagramEditorPageState();
}

class _DiagramEditorPageState extends State<DiagramEditorPage> {
  ui.Image? _image;
  List<Rect> _rects = [];
  Offset? _startPoint;
  Offset? _currentPoint;

  @override
  void initState() {
    super.initState();
    _rects = List.from(widget.initialRects);
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frameInfo = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _image = frameInfo.image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Draw Diagram Masks', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo Last',
            onPressed: _rects.isEmpty
                ? null
                : () {
                    setState(() {
                      _rects.removeLast();
                    });
                  },
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_rects);
            },
            child: const Text('DONE', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate best fit size
            final imgW = _image!.width.toDouble();
            final imgH = _image!.height.toDouble();
            final viewW = constraints.maxWidth;
            final viewH = constraints.maxHeight;

            double scale = 1.0;
            if (imgW / imgH > viewW / viewH) {
              scale = viewW / imgW;
            } else {
              scale = viewH / imgH;
            }

            final drawW = imgW * scale;
            final drawH = imgH * scale;

            return GestureDetector(
              onPanStart: (details) {
                // localPosition is already relative to the GestureDetector (the centered image area)
                setState(() {
                  _startPoint = details.localPosition;
                  _currentPoint = details.localPosition;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentPoint = details.localPosition;
                });
              },
              onPanEnd: (details) {
                if (_startPoint != null && _currentPoint != null) {
                  final rect = Rect.fromPoints(_startPoint!, _currentPoint!);
                  // Only add if it has some area to avoid accidental taps
                  if (rect.width > 5 && rect.height > 5) {
                    // Convert screen rect back to original image pixel coordinates
                    final pxRect = Rect.fromLTRB(
                      (rect.left / scale).clamp(0, imgW),
                      (rect.top / scale).clamp(0, imgH),
                      (rect.right / scale).clamp(0, imgW),
                      (rect.bottom / scale).clamp(0, imgH),
                    );
                    setState(() {
                      _rects.add(pxRect);
                    });
                  }
                }
                setState(() {
                  _startPoint = null;
                  _currentPoint = null;
                });
              },
              child: Container(
                width: drawW,
                height: drawH,
                color: Colors.transparent,
                child: CustomPaint(
                  size: Size(drawW, drawH),
                  painter: _MaskPainter(
                    image: _image!,
                    scale: scale,
                    rects: _rects,
                    startPoint: _startPoint,
                    currentPoint: _currentPoint,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Drag over areas you want to identify as diagrams. These will be masked with black blocks before OCR.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final ui.Image image;
  final double scale;
  final List<Rect> rects;
  final Offset? startPoint;
  final Offset? currentPoint;

  _MaskPainter({
    required this.image,
    required this.scale,
    required this.rects,
    this.startPoint,
    this.currentPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the image scaled
    canvas.save();
    canvas.scale(scale, scale);
    canvas.drawImage(image, Offset.zero, Paint());
    
    // Draw the confirmed rectangles (masked preview)
    final maskPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 / scale;

    for (final rect in rects) {
      canvas.drawRect(rect, maskPaint);
      canvas.drawRect(rect, borderPaint);
    }
    canvas.restore();

    // Draw the actively dragging rectangle on top without scale conversion (since points are screen space)
    if (startPoint != null && currentPoint != null) {
      final activeRect = Rect.fromPoints(startPoint!, currentPoint!);
      final activePaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(activeRect, activePaint);
      
      final activeBorder = Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(activeRect, activeBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) => true;
}
