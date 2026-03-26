import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/note_record.dart';
import '../theme.dart';

/// Digitally reconstructs a single note page by rendering OCR text blocks
/// at their original positions and drawing diagram images in-place.
class NoteDigitalView extends StatefulWidget {
  /// OCR text blocks for this page, sorted by reading order.
  final List<OcrBlock> ocrBlocks;

  /// Diagrams extracted from this page.
  final List<NoteDiagram> diagrams;

  /// Original image width (used to map quad coordinates → widget space).
  final int sourceWidth;

  /// Original image height.
  final int sourceHeight;

  /// Maximum height for the canvas (matches the original image viewport).
  final double maxHeight;

  const NoteDigitalView({
    super.key,
    required this.ocrBlocks,
    required this.diagrams,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.maxHeight,
  });

  @override
  State<NoteDigitalView> createState() => _NoteDigitalViewState();
}

class _NoteDigitalViewState extends State<NoteDigitalView> {
  /// Decoded diagram images keyed by diagram id.
  final Map<int, ui.Image> _decodedDiagrams = {};
  bool _diagramsLoading = true;

  @override
  void initState() {
    super.initState();
    _decodeDiagramImages();
  }

  @override
  void didUpdateWidget(covariant NoteDigitalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-decode if diagrams changed (e.g. page navigation).
    if (oldWidget.diagrams != widget.diagrams) {
      _decodedDiagrams.clear();
      _decodeDiagramImages();
    }
  }

  Future<void> _decodeDiagramImages() async {
    setState(() => _diagramsLoading = true);
    for (final d in widget.diagrams) {
      try {
        final codec = await ui.instantiateImageCodec(d.imageBytes);
        final frame = await codec.getNextFrame();
        _decodedDiagrams[d.id] = frame.image;
      } catch (_) {
        // Skip diagrams that fail to decode.
      }
    }
    if (mounted) setState(() => _diagramsLoading = false);
  }

  /// Decode packed Int32 quad bytes → list of 8 ints [x1,y1,x2,y2,...].
  static List<int> _quadToInts(Uint8List quadBytes) {
    final bd = quadBytes.buffer.asByteData(
      quadBytes.offsetInBytes,
      quadBytes.lengthInBytes,
    );
    final len = quadBytes.lengthInBytes ~/ 4;
    final out = <int>[];
    for (int i = 0; i < len; i++) {
      out.add(bd.getInt32(i * 4, Endian.host));
    }
    return out;
  }

  /// Get axis-aligned bounding rect from quad.
  static Rect _quadToRect(List<int> q) {
    final xs = [q[0], q[2], q[4], q[6]];
    final ys = [q[1], q[3], q[5], q[7]];
    final minX = xs.reduce((a, b) => a < b ? a : b).toDouble();
    final maxX = xs.reduce((a, b) => a > b ? a : b).toDouble();
    final minY = ys.reduce((a, b) => a < b ? a : b).toDouble();
    final maxY = ys.reduce((a, b) => a > b ? a : b).toDouble();
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  void _showDiagramDetail(BuildContext context, NoteDiagram diagram) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Diagram',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  diagram.imageBytes,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
              if (diagram.explanation != null &&
                  diagram.explanation!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Explanation',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightInputFill,
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    diagram.explanation!,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sourceWidth == 0 || widget.sourceHeight == 0) {
      return const Center(
        child: Text(
          'No image dimensions available',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final srcW = widget.sourceWidth.toDouble();
        final srcH = widget.sourceHeight.toDouble();

        // Use contain-style scaling: fit within both width and maxHeight.
        final scaleW = constraints.maxWidth / srcW;
        final scaleH = widget.maxHeight / srcH;
        final scale = scaleW < scaleH ? scaleW : scaleH;
        final canvasWidth = srcW * scale;
        final canvasHeight = srcH * scale;

        // Build diagram hit-test regions for tap detection.
        final diagramRects = <int, Rect>{};
        for (final d in widget.diagrams) {
          final q = _quadToInts(d.quad);
          if (q.length >= 8) {
            final r = _quadToRect(q);
            diagramRects[d.id] = Rect.fromLTRB(
              r.left * scale,
              r.top * scale,
              r.right * scale,
              r.bottom * scale,
            );
          }
        }

        return Center(
          child: GestureDetector(
            onTapUp: (details) {
              // Check if tap hits a diagram region.
              for (final d in widget.diagrams) {
                final r = diagramRects[d.id];
                if (r != null && r.contains(details.localPosition)) {
                  _showDiagramDetail(context, d);
                  return;
                }
              }
            },
            child: Container(
              width: canvasWidth,
              height: canvasHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.border.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                  size: Size(canvasWidth, canvasHeight),
                  painter: _DigitalPagePainter(
                    ocrBlocks: widget.ocrBlocks,
                    diagrams: widget.diagrams,
                    decodedDiagrams: _decodedDiagrams,
                    scale: scale,
                    sourceWidth: srcW,
                    sourceHeight: srcH,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    for (final img in _decodedDiagrams.values) {
      img.dispose();
    }
    super.dispose();
  }
}

/// CustomPainter that renders OCR text blocks and diagram images at their
/// original positions (scaled to widget space).
class _DigitalPagePainter extends CustomPainter {
  final List<OcrBlock> ocrBlocks;
  final List<NoteDiagram> diagrams;
  final Map<int, ui.Image> decodedDiagrams;
  final double scale;
  final double sourceWidth;
  final double sourceHeight;

  _DigitalPagePainter({
    required this.ocrBlocks,
    required this.diagrams,
    required this.decodedDiagrams,
    required this.scale,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  static List<int> _quadToInts(Uint8List quadBytes) {
    final bd = quadBytes.buffer.asByteData(
      quadBytes.offsetInBytes,
      quadBytes.lengthInBytes,
    );
    final len = quadBytes.lengthInBytes ~/ 4;
    final out = <int>[];
    for (int i = 0; i < len; i++) {
      out.add(bd.getInt32(i * 4, Endian.host));
    }
    return out;
  }

  static Rect _quadToRect(List<int> q) {
    final xs = [q[0], q[2], q[4], q[6]];
    final ys = [q[1], q[3], q[5], q[7]];
    final minX = xs.reduce((a, b) => a < b ? a : b).toDouble();
    final maxX = xs.reduce((a, b) => a > b ? a : b).toDouble();
    final minY = ys.reduce((a, b) => a < b ? a : b).toDouble();
    final maxY = ys.reduce((a, b) => a > b ? a : b).toDouble();
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw diagram images first (behind text).
    final diagramPaint = Paint();
    final diagramBgPaint = Paint()
      ..color = const Color(0xFFF0F4FF) // light blue tint behind diagrams
      ..style = PaintingStyle.fill;
    final diagramBorderPaint = Paint()
      ..color = const Color(0xFFBFDBFE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final d in diagrams) {
      final q = _quadToInts(d.quad);
      if (q.length < 8) continue;
      final rect = _quadToRect(q);
      final scaledRect = Rect.fromLTRB(
        rect.left * scale,
        rect.top * scale,
        rect.right * scale,
        rect.bottom * scale,
      );

      // Draw tinted background.
      final rrect = RRect.fromRectAndRadius(scaledRect, const Radius.circular(4));
      canvas.drawRRect(rrect, diagramBgPaint);

      // Draw diagram image if decoded.
      final img = decodedDiagrams[d.id];
      if (img != null) {
        final srcRect = Rect.fromLTWH(
          0,
          0,
          img.width.toDouble(),
          img.height.toDouble(),
        );
        canvas.drawImageRect(img, srcRect, scaledRect, diagramPaint);
      }

      // Draw border.
      canvas.drawRRect(rrect, diagramBorderPaint);

      // Draw a small "tap to expand" indicator.
      if (d.explanation != null && d.explanation!.isNotEmpty) {
        final iconSize = 16.0 * scale.clamp(0.5, 1.5);
        final iconRect = Rect.fromLTWH(
          scaledRect.right - iconSize - 4,
          scaledRect.top + 4,
          iconSize,
          iconSize,
        );
        final iconBg = Paint()
          ..color = const Color(0xCC2563EB)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(iconRect.center, iconSize / 2, iconBg);

        // Draw "i" letter for info.
        final tp = TextPainter(
          text: TextSpan(
            text: 'i',
            style: TextStyle(
              color: Colors.white,
              fontSize: iconSize * 0.65,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            iconRect.center.dx - tp.width / 2,
            iconRect.center.dy - tp.height / 2,
          ),
        );
      }
    }

    // 2. Collect diagram rects to avoid rendering text that overlaps.
    final diagramRegions = <Rect>[];
    for (final d in diagrams) {
      final q = _quadToInts(d.quad);
      if (q.length >= 8) diagramRegions.add(_quadToRect(q));
    }

    // 3. Draw OCR text blocks.
    for (final block in ocrBlocks) {
      final q = _quadToInts(block.quad);
      if (q.length < 8) continue;
      final rect = _quadToRect(q);

      // Skip text blocks that overlap significantly with a diagram region.
      bool overlaps = false;
      for (final dr in diagramRegions) {
        final intersection = rect.intersect(dr);
        if (intersection.width > 0 && intersection.height > 0) {
          final overlapArea = intersection.width * intersection.height;
          final blockArea = rect.width * rect.height;
          if (blockArea > 0 && overlapArea / blockArea > 0.4) {
            overlaps = true;
            break;
          }
        }
      }
      if (overlaps) continue;

      final text = block.text.trim();
      if (text.isEmpty) continue;

      final blockHeight = rect.height * scale;

      // Estimate font size from quad height. Use a smaller factor for
      // denser, more readable text that matches the original note.
      final fontSize = (blockHeight * 0.55).clamp(7.0, 20.0);

      // Render each block as a single non-wrapping line — OCR blocks
      // correspond to individual lines of handwritten text.
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: const Color(0xFF1F2937), // dark gray text
            fontSize: fontSize,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      tp.paint(
        canvas,
        Offset(rect.left * scale, rect.top * scale),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DigitalPagePainter oldDelegate) {
    return oldDelegate.ocrBlocks != ocrBlocks ||
        oldDelegate.diagrams != diagrams ||
        oldDelegate.decodedDiagrams != decodedDiagrams ||
        oldDelegate.scale != scale;
  }
}
