// Private fields fed by public named params cannot use initializing formals.
// ignore_for_file: prefer_initializing_formals

import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Everything export needs from a data source: one page of rows for a query.
///
/// Deliberately *not* `Repository<E, ID>`. Export only ever reads pages, and
/// half the lists in this app are not backed by a full CRUD repository — the
/// voucher lists have a bespoke read-only one. Depending on the whole interface
/// would have shut those out for no reason; depending on the one method export
/// actually calls lets any of them pass `repository.list` straight in.
typedef ExportSource<E> =
    Future<Result<Paginated<E>>> Function(PageQuery query);

/// Export pulls far bigger pages than the screen does — the rows never render,
/// so the only cost is bytes over the wire, and fewer round trips is faster.
const kExportPageSize = 200;

/// A backstop, not a business rule: an unbounded walk against a filter that
/// matches the whole ledger would hammer the server and blow up memory on web.
/// The view tells the user when this trims the file.
const kExportRowCap = 5000;

/// Which file the view should write once the rows are gathered.
enum ExportFormat { excel, csv }

@immutable
sealed class ExportState<E> extends Equatable {
  const ExportState();

  @override
  List<Object?> get props => const [];
}

final class ExportIdle<E> extends ExportState<E> {
  const ExportIdle();
}

final class ExportRunning<E> extends ExportState<E> {
  const ExportRunning();
}

/// The rows are gathered and the view should now write the file.
///
/// The bytes are deliberately *not* written here: a cubit that touches the
/// filesystem cannot be tested without one, and the platform fork lives in the
/// sink. The view writes, then calls [ExportCubit.handled] so a rebuild cannot
/// hand it the same file twice.
final class ExportReady<E> extends ExportState<E> {
  const ExportReady({
    required this.items,
    required this.total,
    required this.format,
  });

  final List<E> items;

  /// What the server says the result set holds — which may be more than we
  /// pulled, when [ExportCubit] hit the cap.
  final int total;

  final ExportFormat format;

  bool get isTruncated => items.length < total;

  @override
  List<Object?> get props => [items, total, format];
}

final class ExportFailed<E> extends ExportState<E> {
  const ExportFailed(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Gathers every row matching a list's current query, so an export is the whole
/// result set and not merely the pages that happen to have been scrolled into
/// view.
///
/// One cubit serves every list — the manifest-driven masters on
/// `MasterListSurface` and the feature screens that run their own list bloc —
/// because all of them program against the same [Repository] and [PageQuery].
/// That is the reason none of those list blocs needed an export event of their
/// own.
class ExportCubit<E> extends Cubit<ExportState<E>> {
  ExportCubit({
    required ExportSource<E> source,
    int pageSize = kExportPageSize,
    int rowCap = kExportRowCap,
  }) : _source = source,
       _pageSize = pageSize,
       _rowCap = rowCap,
       super(ExportIdle<E>());

  final ExportSource<E> _source;
  final int _pageSize;
  final int _rowCap;

  Future<void> run({
    required PageQuery query,
    required ExportFormat format,
  }) async {
    // A second tap while a walk is running would double the traffic and race to
    // hand the view two files.
    if (state is ExportRunning<E>) return;
    emit(ExportRunning<E>());

    final base = query.copyWith(page: 1, limit: _pageSize);
    final items = <E>[];
    var page = 1;
    var totalPages = 1;
    var total = 0;

    while (page <= totalPages && items.length < _rowCap) {
      final result = await _source(base.copyWith(page: page));
      if (isClosed) return;

      final keepGoing = result.fold(
        (failure) {
          emit(ExportFailed<E>(failure));
          return false;
        },
        (fetched) {
          items.addAll(fetched.items);
          total = fetched.meta.total;
          totalPages = fetched.meta.totalPages;
          // A page that comes back empty would otherwise spin forever against a
          // server whose totalPages disagrees with what it actually returns.
          return fetched.items.isNotEmpty;
        },
      );
      if (!keepGoing) {
        if (state is ExportFailed<E>) return;
        break;
      }

      page++;
    }

    final capped = items.length > _rowCap
        ? items.take(_rowCap).toList()
        : items;

    emit(
      ExportReady<E>(
        items: capped,
        // Trust the server's count over what we managed to pull, so a capped
        // export still reports the true size of the result set.
        total: total < capped.length ? capped.length : total,
        format: format,
      ),
    );
  }

  /// Called by the view once it has written the file.
  void handled() => emit(ExportIdle<E>());
}
