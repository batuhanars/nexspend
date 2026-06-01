import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/api_endpoints.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/core/widgets/authenticated_image.dart';

class ReceiptImageViewerPage extends StatelessWidget {
  const ReceiptImageViewerPage({super.key, required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: AuthenticatedImage(
              urlPath: ApiEndpoints.receiptImage(receiptId),
              cacheKey: receiptId,
              fit: BoxFit.contain,
              placeholder: Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
              errorWidget: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 56,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
