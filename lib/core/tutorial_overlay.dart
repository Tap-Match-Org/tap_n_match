import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum TutorialCardPosition {
  topLeft,
  topCenter,
  topRight,
  center,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class TutorialStep {
  const TutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.cardPosition,
    this.showArrow = true,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
  final TutorialCardPosition cardPosition;
  final bool showArrow;
}

class GuidedTutorialOverlay extends StatefulWidget {
  const GuidedTutorialOverlay({
    super.key,
    required this.steps,
    required this.currentIndex,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
    this.isSaving = false,
  });

  final List<TutorialStep> steps;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final bool isSaving;

  @override
  State<GuidedTutorialOverlay> createState() => _GuidedTutorialOverlayState();
}

class _GuidedTutorialOverlayState extends State<GuidedTutorialOverlay> {
  final GlobalKey _overlayKey = GlobalKey();
  Rect? _targetRect;
  bool _isMeasurementScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleMeasurement();
  }

  @override
  void didUpdateWidget(covariant GuidedTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _targetRect = null;
    }
    _scheduleMeasurement();
  }

  void _scheduleMeasurement() {
    if (_isMeasurementScheduled || !mounted) {
      return;
    }

    _isMeasurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isMeasurementScheduled = false;
      if (!mounted) return;

      final nextRect = _resolveTargetRect(widget.steps[widget.currentIndex].targetKey);
      if (nextRect == null) {
        WidgetsBinding.instance.scheduleFrame();
        _scheduleMeasurement();
        return;
      }

      if (_targetRect != nextRect) {
        setState(() => _targetRect = nextRect);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasurement();

    final step = widget.steps[widget.currentIndex];
    final targetRect = _targetRect;

    return Positioned.fill(
      child: SizedBox.expand(
        key: _overlayKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (targetRect == null) {
              return const SizedBox.expand();
            }

            final screenSize = constraints.biggest;
            final cardRect = _cardRectForPosition(screenSize, step.cardPosition);

            return Stack(
              children: [
                const ModalBarrier(
                  dismissible: false,
                  color: Color(0xBF000000),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _TutorialOverlayPainter(
                        targetRect: targetRect,
                        cardRect: cardRect,
                        showArrow: false,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: _alignmentFor(step.cardPosition),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEF7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 14,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tutorial ${widget.currentIndex + 1}/${widget.steps.length}',
                                style: GoogleFonts.pixelifySans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                step.title,
                                style: GoogleFonts.pixelifySans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                step.description,
                                style: GoogleFonts.pixelifySans(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  if (widget.currentIndex > 0)
                                    Expanded(
                                      child: _TutorialButton(
                                        label: 'Back',
                                        onTap: widget.isSaving ? null : widget.onBack,
                                        color: const Color(0xFFB8C4D8),
                                      ),
                                    ),
                                  if (widget.currentIndex > 0) const SizedBox(width: 10),
                                  Expanded(
                                    child: _TutorialButton(
                                      label: widget.currentIndex == widget.steps.length - 1
                                          ? 'Finish'
                                          : 'Next',
                                      onTap: widget.isSaving ? null : widget.onNext,
                                      color: const Color(0xFFF6BE56),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: widget.isSaving ? null : widget.onSkip,
                                  child: Text(
                                    widget.isSaving ? 'Saving...' : 'Skip tutorial',
                                    style: GoogleFonts.pixelifySans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Rect? _resolveTargetRect(GlobalKey key) {
    final targetContext = key.currentContext;
    final overlayContext = _overlayKey.currentContext;
    final targetRenderObject = targetContext?.findRenderObject();
    final overlayRenderObject = overlayContext?.findRenderObject();
    if (targetRenderObject is! RenderBox || overlayRenderObject is! RenderBox) {
      return null;
    }
    if (!targetRenderObject.hasSize || !overlayRenderObject.hasSize) {
      return null;
    }

    final localTopLeft = targetRenderObject.localToGlobal(
      Offset.zero,
      ancestor: overlayRenderObject,
    );
    return localTopLeft & targetRenderObject.size;
  }

  Alignment _alignmentFor(TutorialCardPosition position) {
    switch (position) {
      case TutorialCardPosition.topLeft:
        return Alignment.topLeft;
      case TutorialCardPosition.topCenter:
        return Alignment.topCenter;
      case TutorialCardPosition.topRight:
        return Alignment.topRight;
      case TutorialCardPosition.center:
        return Alignment.center;
      case TutorialCardPosition.centerLeft:
        return Alignment.centerLeft;
      case TutorialCardPosition.centerRight:
        return Alignment.centerRight;
      case TutorialCardPosition.bottomLeft:
        return Alignment.bottomLeft;
      case TutorialCardPosition.bottomCenter:
        return Alignment.bottomCenter;
      case TutorialCardPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }

  Rect _cardRectForPosition(Size size, TutorialCardPosition position) {
    const horizontalPadding = 24.0;
    const verticalPadding = 24.0;
    const cardWidth = 340.0;
    const cardHeight = 210.0;
    const left = horizontalPadding;
    final right = size.width - cardWidth - horizontalPadding;
    final centerX = (size.width - cardWidth) / 2;
    const top = verticalPadding;
    final bottom = size.height - cardHeight - verticalPadding;
    final centerY = (size.height - cardHeight) / 2;

    switch (position) {
      case TutorialCardPosition.topLeft:
        return const Rect.fromLTWH(left, top, cardWidth, cardHeight);
      case TutorialCardPosition.topCenter:
        return Rect.fromLTWH(centerX, top, cardWidth, cardHeight);
      case TutorialCardPosition.topRight:
        return Rect.fromLTWH(right, top, cardWidth, cardHeight);
      case TutorialCardPosition.center:
        return Rect.fromLTWH(centerX, centerY, cardWidth, cardHeight);
      case TutorialCardPosition.centerLeft:
        return Rect.fromLTWH(left, centerY, cardWidth, cardHeight);
      case TutorialCardPosition.centerRight:
        return Rect.fromLTWH(right, centerY, cardWidth, cardHeight);
      case TutorialCardPosition.bottomLeft:
        return Rect.fromLTWH(left, bottom, cardWidth, cardHeight);
      case TutorialCardPosition.bottomCenter:
        return Rect.fromLTWH(centerX, bottom, cardWidth, cardHeight);
      case TutorialCardPosition.bottomRight:
        return Rect.fromLTWH(right, bottom, cardWidth, cardHeight);
    }
  }
}

class _TutorialButton extends StatelessWidget {
  const _TutorialButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: GoogleFonts.pixelifySans(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _TutorialOverlayPainter extends CustomPainter {
  const _TutorialOverlayPainter({
    required this.targetRect,
    required this.cardRect,
    required this.showArrow,
  });

  final Rect targetRect;
  final Rect cardRect;
  final bool showArrow;

  @override
  void paint(Canvas canvas, Size size) {
    final highlightRect = targetRect.inflate(10);
    final outerGlowRect = targetRect.inflate(18);
    final highlightRRect = RRect.fromRectAndRadius(
      highlightRect,
      const Radius.circular(16),
    );
    final outerGlowRRect = RRect.fromRectAndRadius(
      outerGlowRect,
      const Radius.circular(22),
    );

    final outerGlowPaint = Paint()
      ..color = const Color(0xFFFFF0B8).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(outerGlowRRect, outerGlowPaint);

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(highlightRRect, glowPaint);

    final haloPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawRRect(highlightRRect, haloPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFFFD36E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawRRect(highlightRRect, borderPaint);

    if (!showArrow) {
      return;
    }

    final targetCenter = targetRect.center;
    final arrowStart = _nearestPointOnRect(cardRect, targetCenter);
    final arrowEnd = _nearestPointOnRect(highlightRect, arrowStart);

    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(arrowStart, arrowEnd, shadowPaint);
    canvas.drawLine(arrowStart, arrowEnd, arrowPaint);

    final angle = math.atan2(arrowEnd.dy - arrowStart.dy, arrowEnd.dx - arrowStart.dx);
    const headLength = 16.0;
    final leftWing = Offset(
      arrowEnd.dx - headLength * math.cos(angle - math.pi / 7),
      arrowEnd.dy - headLength * math.sin(angle - math.pi / 7),
    );
    final rightWing = Offset(
      arrowEnd.dx - headLength * math.cos(angle + math.pi / 7),
      arrowEnd.dy - headLength * math.sin(angle + math.pi / 7),
    );
    canvas.drawLine(arrowEnd, leftWing, arrowPaint);
    canvas.drawLine(arrowEnd, rightWing, arrowPaint);
  }

  Offset _nearestPointOnRect(Rect rect, Offset point) {
    final dx = point.dx.clamp(rect.left, rect.right).toDouble();
    final dy = point.dy.clamp(rect.top, rect.bottom).toDouble();
    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(covariant _TutorialOverlayPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.cardRect != cardRect ||
        oldDelegate.showArrow != showArrow;
  }
}
