import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

/// One generic print surface for every voucher and report. [build] produces
/// the PDF bytes (see `core/printing/voucher_pdf.dart`); [PdfPreview] from
/// the `printing` package supplies the zoom/print/share/save UI on every
/// platform, including web.
class DocumentPdfPreviewPage extends StatelessWidget {
  const DocumentPdfPreviewPage({
    required this.title,
    required this.pdfBuilder,
    super.key,
  });

  final String title;
  final Future<Uint8List> Function() pdfBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: PdfPreview(
        build: (format) => pdfBuilder(),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
      ),
    );
  }
}
