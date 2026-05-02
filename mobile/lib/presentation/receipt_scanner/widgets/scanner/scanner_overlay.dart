import 'package:flutter/material.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/scanner/corner_marks.dart';

import '../../../../core/constants/app_spacing.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const cutoutW = 300.0;
    final cutoutH = cutoutW * 1.4;
    final left = (size.width - cutoutW) / 2;
    final top = (size.height - cutoutH) / 2 - 40;

    return Stack(
      children: [
        // Dark overlay
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: Container(
                  width: cutoutW,
                  height: cutoutH,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Corner marks
        Positioned(
          left: left,
          top: top,
          child: CornerMarks(width: cutoutW, height: cutoutH),
        ),
        // Hint text below frame
        Positioned(
          left: 0,
          right: 0,
          top: top + cutoutH + AppSpacing.lg,
          child: const Text(
            'Makbuzu çerçeve içine hizalayın',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
