import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/presentation/sales_invoice_html_open.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/sales_invoice_di.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Loads the backend print HTML with the app Dio auth stack.
///
/// On web, opens a blob URL in a new tab for native print. On other
/// platforms, shows the HTML source in a scrollable view.
class SalesInvoiceHtmlPdfPage extends StatefulWidget {
  const SalesInvoiceHtmlPdfPage({required this.id, super.key});

  final int id;

  @override
  State<SalesInvoiceHtmlPdfPage> createState() =>
      _SalesInvoiceHtmlPdfPageState();
}

class _SalesInvoiceHtmlPdfPageState extends State<SalesInvoiceHtmlPdfPage> {
  late final _repo = createSalesInvoiceRepository(getIt<DioClient>());
  late Future<String> _future;
  bool _webOpened = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<String> _load() async {
    final r = await _repo.fetchPdfHtml(widget.id);
    return r.fold((f) => throw Exception(f.toString()), (html) => html);
  }

  void _maybeOpenWeb(String html) {
    if (!kIsWeb || _webOpened || html.isEmpty) return;
    _webOpened = true;
    // Defer so we are not calling window.open during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openSalesInvoiceHtml(html);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice PDF #${widget.id}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              _webOpened = false;
              _future = _load();
            }),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snapshot.hasError) {
            final err = snapshot.error;
            return ErrorState(
              failure: err is Failure ? err : Failure.unknown(err.toString()),
              onRetry: () => setState(() {
                _webOpened = false;
                _future = _load();
              }),
            );
          }
          final html = snapshot.data ?? '';
          if (kIsWeb) {
            _maybeOpenWeb(html);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Print window opened with authenticated HTML.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => openSalesInvoiceHtml(html),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open again'),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              MaterialBanner(
                content: const Text(
                  'Authenticated HTML from the server. Use a browser build '
                  'for one-click print, or copy the HTML below.',
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: html));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('HTML copied')),
                      );
                    },
                    child: const Text('Copy HTML'),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(html),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
